local cjson = require("cjson")
local encode = cjson.encode

function usage()
    print("lua compile.lua [schema.txt]")
end

local missing_enums = {}

function get_schema_text(file)
    local f = io.open(file)
    if not f then
        return nil, "Can't open file: " .. tostring(file)
    end

    local s = f:read("*a")
    f:close()

    s = string.gsub(s, "%(", "{")
    s = string.gsub(s, "%)", "}")
    s = string.gsub(s, "%[", "{")
    s = string.gsub(s, "%]", "}")
    s = string.gsub(s, "%<", "\"")
    s = string.gsub(s, "%>", "\"")
    s = string.gsub(s, "id = (%d+)", "id = \"%1\"")
    s = string.gsub(s, "typeId = (%d+)", "typeId = \"%1\"")
    s = string.gsub(s, "void", "\"void\"")
    return "return " .. s
end

function comp_header(res, nodes)
    --print("header")
    table.insert(res, [[
local ffi = require "ffi"
local capnp = require "capnp"

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(2, 8)

function _M.init(T)
    -- suggested first segment size 4k
    local segment = capnp.new_segment(4096)
    return T:new(segment)
end

]])
end

function get_number(num)
    if not num then
        return 0
    end
end

function get_name(display_name)
    local n = string.find(display_name, ":")
    return string.sub(display_name, n + 1)
end

function comp_struct(res, nodes, struct)
end

size_map = {
    void    = 0,
    bool    = 1,
    int8    = 8,
    int16   = 16,
    int32   = 32,
    int64   = 64,
    uint8   = 8,
    uint16  = 16,
    uint32  = 32,
    uint64  = 64,
    float32 = 32,
    float64 = 64,
    text    = "2", -- list(uint8)
    data    = "2",
    list    = 2, -- size: list item size id, not actual size
    struct  = 8,  -- struct pointer
    enum    = 16,
}

function get_size(type_name)
    local size = size_map[type_name]
    if not size then
        error("Unknown type_name:" .. type_name)
    end

    return size
end

function comp_field(res, nodes, field)
    local slot = field.slot
    if not slot.offset then
        slot.offset = 0
    end

    local type_name, default
    for k, v in pairs(slot["type"]) do
        type_name   = k
        if type_name == "struct" then
            --print(v.typeId)
            --print(nodes[v.typeId].displayName)
            field.type_display_name = get_name(nodes[v.typeId].displayName)
            default     = "opaque object"
        elseif type_name == "enum" then
            field.enum_id = v.typeId
        else
            default     = v
        end

        field.type_name = type_name
        field.default   = default

        break
    end

    field.size      = get_size(type_name)

    table.insert(res, "        ")
    table.insert(res, field.name)
    table.insert(res, " = {")
    table.insert(res, " size = " .. field.size .. ",")
    table.insert(res, " offset = " .. slot.offset .. ",")
    if type_name == "enum" then
        table.insert(res, " is_enum = true,")
    end
    if type_name == "text" then
        table.insert(res, " is_text = true,")
    end
    if type_name == "data" then
        table.insert(res, " is_data = true,")
    end
    if type_name == "struct" or type_name == "list" then
        table.insert(res, " is_pointer = true,")
    end
    table.insert(res, " },\n")
end

function comp_struct_init_func(res, name, offset, size, type_name)
    table.insert(res, [[
        -- sub struct
        struct.init_]] .. name ..[[ = function(self)
            local segment = self.segment

            local data_pos = self.pointer_pos + ]].. offset .." * " .. size ..[[ -- s0.offset * s0.size (pointer size is 8)
            local data_off = ((segment.data + segment.pos) - (data_pos + 8)) / 8 -- unused memory pos - struct pointer end pos
            capnp.write_structp(data_pos, self.schema.]].. type_name ..[[, data_off)

            --print(data_off)
            local s =  capnp.write_struct(segment, self.schema.]].. type_name ..[[)

            local mt = {
                __newindex =  capnp.struct_newindex
            }
            return setmetatable(s, mt)
        end
]])
end

function comp_list_init_func(res, name, offset, size)
    table.insert(res, [[
        -- list
        struct.init_]] .. name .. [[ = function(self, num)
            assert(num)
            local segment = self.segment
            local data_pos = self.pointer_pos + ]] .. offset .. " * 8 " .. [[ -- l0.offset * 8 (pointer size is 8)
            local data_off = ((segment.data + segment.pos) - (data_pos + 8)) / 8 -- unused memory pos - list pointer end pos, result in bytes. So we need to divide this value by 8 to get word offset

            capnp.write_listp(data_pos, ]] .. size .. [[, num,  data_off) -- 2: l0.size

            local l = capnp.write_list(segment, ]].. size .. [[, num) -- 2: l0.size

            local mt = {
                __newindex =  capnp.list_newindex
            }
            return setmetatable(l, mt)
        end
]])
end

function format_enum_name(name)
    -- TODO control this using annotation
    return string.lower(string.gsub(name, "(%u)", "_%1"))
end

function comp_node(res, nodes, node, name)
    if not node then
        print("Ignoring node: ", name)
        return
    end
    print("node", name)

    table.insert(res, string.format([[
_M.%s = {
]], name))

    local s = node.struct
    if s then
        table.insert(res, string.format([[
    id = %s,
    displayName = "%s",
]], node.id, node.displayName))

        if not s.dataWordCount then
            s.dataWordCount = 0
        end
        if not s.pointerCount then
            s.pointerCount = 0
        end

        table.insert(res, "    dataWordCount = ")
        table.insert(res, s.dataWordCount)
        table.insert(res, ",\n")

        table.insert(res, "    pointerCount = ")
        table.insert(res, s.pointerCount)
        table.insert(res, ",\n")

        if s.fields then
            table.insert(res, "    fields = {\n")
            for i, field in ipairs(s.fields) do
                comp_field(res, nodes, field)
                if field.type_name == "enum" then
                    local key = "_M." .. name .. ".fields." .. field.name
                    missing_enums[key] = field.enum_id
                end
            end
            table.insert(res, "    },\n")
        end

        table.insert(res, [[
    new = function(self, segment)
        local struct = capnp.init_root(segment, self)
        struct.schema = _M
]])
        if s.fields then
            for i, field in ipairs(s.fields) do
                if field.type_name == "list" then
                    comp_list_init_func(res, field.name, field.slot.offset, field.size)
                elseif field.type_name == "struct" then
                    comp_struct_init_func(res, field.name, field.slot.offset, field.size, field.type_display_name)
                end
            end
        end

        table.insert(res, [[
        return capnp.init_new_struct(struct)
    end
]])
    end
    local e = node.enum
    if e then

        for i, v in ipairs(e.enumerants) do
            if not v.codeOrder then
                v.codeOrder = 0
            end
            table.insert(res, string.format("    [\"%s\"] = %s,\n", format_enum_name(v.name), v.codeOrder))
        end
    end

    table.insert(res, "\n}\n")
    if node.nestedNodes then
        for i, child in ipairs(node.nestedNodes) do
            comp_node(res, nodes, nodes[child.id], name .. "." .. child.name)
        end
    end
end

function comp_body(res, schema)
    print("body")
    local nodes = schema.nodes
    for i, v in ipairs(nodes) do
        nodes[v.id] = v
    end

    local files = schema.requestedFiles

    for i, file in ipairs(files) do
        comp_file(res, nodes, file)

        local imports = file.imports
        for i, import in ipairs(imports) do
            comp_import(res, nodes, import)
        end
    end

    for k, v in pairs(missing_enums) do
        table.insert(res, k .. ".enum_schema = _M." .. get_name(nodes[v].displayName .. "\n"))
    end

    table.insert(res, "\nreturn _M\n")
end

function comp_import(res, nodes, import)
    print("import", import.name)
    local id = import.id

    local import_node = nodes[id]
    --print(root_id)
    --print(nodes[root_id].displayName)
    for i, node in ipairs(import_node.nestedNodes) do
        comp_node(res, nodes, nodes[node.id], node.name)
    end
end

function comp_file(res, nodes, file)
    print("file", file.filename)
    local id = file.id

    local file_node = nodes[id]
    --print(root_id)
    --print(nodes[root_id].displayName)
    for i, node in ipairs(file_node.nestedNodes) do
        comp_node(res, nodes, nodes[node.id], node.name)
    end
end

function compile(schema)
    print("compile")
    local res = {}

    comp_header(res, schema.nodes)
    comp_body(res, schema)

    return table.concat(res)
end

function get_output_name(schema)
    return string.gsub(schema.requestedFiles[1].filename, "%.", "_") .. ".lua"
end

local f = arg[1]
if not f then
    usage()
    return
end

local t = get_schema_text(f)

local file = io.open("test.schema.lua", "w")
file:write(t)
file:close()

local schema = assert(loadstring(t))()

local outfile = get_output_name(schema)
print(outfile)
local res = compile(schema)

local file = io.open(outfile, "w")
file:write(res)
file:close()
