local cjson = require("cjson")
local encode = cjson.encode
local util = require "util"

local insert = table.insert
local format = string.format
local lower = string.lower
local gsub = string.gsub

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
    insert(res, [[
-- require "luacov"
local ffi = require "ffi"
local capnp = require "capnp"
local bit = require "bit"

local ceil              = math.ceil
local write_val         = capnp.write_val
local read_val          = capnp.read_val
local get_enum_val      = capnp.get_enum_val
local get_data_off      = capnp.get_data_off
local write_listp_buf   = capnp.write_listp_buf
local write_structp_buf = capnp.write_structp_buf
local write_structp     = capnp.write_structp
local parse_struct_buf  = capnp.parse_struct_buf
local parse_listp_buf   = capnp.parse_listp_buf
local parse_list_data   = capnp.parse_list_data
local ffi_new           = ffi.new
local ffi_string        = ffi.string
local ffi_cast          = ffi.cast
local ffi_copy          = ffi.copy
local ffi_fill          = ffi.fill

local ok, new_tab = pcall(require, "table.new")

if not ok then
    new_tab = function (narr, nrec) return {} end
end

local round8 = function(size)
    return ceil(size / 8) * 8
end

local str_buf
local default_segment_size = 4096

local function get_str_buf(size)
    if size > default_segment_size then
        return ffi_new("char[?]", size)
    end

    if not str_buf then
        str_buf = ffi_new("char[?]", default_segment_size)
    end
    return str_buf
end

local _M = new_tab(2, 8)

]])
end

function get_name(display_name)
    local n = string.find(display_name, ":")
    return string.sub(display_name, n + 1)
end

-- see http://kentonv.github.io/_Mroto/encoding.html#lists
local list_size_map = {
    [0] = 0,
    [1] = 0.125,
    [2] = 1,
    [3] = 2,
    [4] = 4,
    [5] = 8,
    [6] = 8,
    -- 7 = ?,
}

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
    if not slot then
        return
    end
    if not slot.offset then
        slot.offset = 0
    end

    field.name = util.lower_underscore_naming(field.name)

    local type_name, default
    for k, v in pairs(slot["type"]) do
        type_name   = k
        if type_name == "struct" then
            field.type_display_name = get_name(nodes[v.typeId].displayName)
            default     = "opaque object"
        elseif type_name == "enum" then
            field.enum_id = v.typeId
            field.type_display_name = get_name(nodes[v.typeId].displayName)
        elseif type_name == "list" then
            local list_type
            for k, v in pairs(field.slot["type"].list.elementType) do
                list_type = k
                break
            end
            field.element_type = list_type
        else
            default     = v
        end

        field.type_name = type_name
        field.default   = default

        break
    end

    if not type_name then
        field.type_name = "void"
        field.size = 0
    else
        field.size      = get_size(type_name)
    end
end

function comp_parse_struct_data(res, struct, fields, size, name)
    insert(res, format([[

    parse_struct_data = function(buf, data_word_count, pointer_count, tab)
        local s = tab
]], size))

    if struct.discriminantCount and struct.discriminantOffset then
        insert(res, format([[

        local dscrm = _M.%s.which(buf, %d) --buf, dscrmriminantOffset, dscrmriminantValue

]], name, struct.discriminantOffset))
    end

    for i, field in ipairs(fields) do
        if field.discriminantValue then
            insert(res, format([[

        if dscrm == %d then
]],field.discriminantValue))
            --[=[
            if field.type_name ~= "void" then
                insert(res, format([[

        s.%s = (dscrm == %d) and read_val(buf, "%s", 32, 4) or nil]],
                    field.name, field.discriminantValue, field.type_name,
                    field.size, field.slot.ofset))
            else
                insert(res, format([[

        s.%s = (dscrm == %d) and "Void" or nil]], field.name,
                    field.discriminantValue))
            end
            ]=]
        end
        if field.group then
            -- TODO group struffs
            insert(res, format([[

        if not s.%s then
            s.%s = new_tab(0, 4)
        end
        _M.%s.%s.parse_struct_data(buf, _M.%s.dataWordCount, _M.%s.pointerCount,
                s.%s)
]], field.name, field.name, name, field.name, name, name, field.name))
        elseif field.type_name == "enum" then
            insert(res, format([[
        local val = read_val(buf, "uint16", %d, %d)
        s.%s = get_enum_val(val, _M.%sStr)
]], field.size, field.slot.offset, field.name, field.type_display_name))

        elseif field.type_name == "list" then
            local off = field.slot.offset
            insert(res, format([[

        local off, size, num = parse_listp_buf(buf, _M.%s, %d)
        if off and num then
            s.%s = parse_list_data(buf + (%d + %d + 1 + off) * 2, size, "%s", num) -- dataWordCount + offset + pointerSize + off
        else
            s.%s = nil
        end
]], name, off, field.name, struct.dataWordCount, off, field.element_type,
        field.name))

        elseif field.type_name == "struct" then
            local off = field.slot.offset

            insert(res, format([[

        local p = buf + (%d + %d) * 2 -- buf, dataWordCount, offset
        local off, dw, pw = parse_struct_buf(p)
        if off and dw and pw then
            if not s.%s then
                s.%s = new_tab(0, 2)
            end
            _M.%s.parse_struct_data(p + 2 + off * 2, dw, pw, s.%s)
        else
            s.%s = nil
        end

]], struct.dataWordCount, off, field.name, field.name, field.type_display_name,
            field.name, field.name))

        elseif field.type_name == "text" then
            local off = field.slot.offset
            insert(res, format([[

        local off, size, num = parse_listp_buf(buf, _M.%s, %d)
        if off and num then
            s.%s = ffi.string(buf + (%d + %d + 1 + off) * 2, num - 1) -- dataWordCount + offset + pointerSize + off
        else
            s.%s = nil
        end
]], name, off, field.name, struct.dataWordCount, off, field.name))

        elseif field.type_name == "data" then
            local off = field.slot.offset
            insert(res, format([[

        local off, size, num = parse_listp_buf(buf, _M.%s, %d)
        if off and num then
            s.%s = ffi.string(buf + (%d + %d + 1 + off) * 2, num) -- dataWordCount + offset + pointerSize + off
        else
            s.%s = nil
        end
]], name, off, field.name, struct.dataWordCount, off, field.name))

        else
            insert(res, format([[
        s.%s = read_val(buf, "%s", %d, %d)
]], field.name, field.type_name, field.size, field.slot.offset))

        end
        if field.discriminantValue then
            insert(res, format([[

        end
]],field.discriminantValue))
        end
    end

    insert(res, [[

        return s
    end,]])
end

function comp_parse(res, name)
    insert(res, format([[

    parse = function(bin, tab)
        if #bin < 16 then
            return nil, "message too short"
        end

        local p = ffi_cast("uint32_t *", bin)
        local nsegs = p[0] + 1
        local sizes = {}
        for i=1, nsegs do
            sizes[i] = p[i] * 8
        end

        local pos = round8(4 + nsegs * 4)

        p = p + pos / 4

        if not tab then
            tab = new_tab(0, 8)
        end
        local off, dw, pw = parse_struct_buf(p)
        if off and dw and pw then
            return _M.%s.parse_struct_data(p + 2 + off * 2, dw, pw, tab)
        else
            return nil
        end
    end,
]], name))
end

function comp_serialize(res, name)
    insert(res, format([[

    serialize = function(data, buf, size)
        if not buf then
            size = _M.%s.calc_size(data)

            buf = get_str_buf(size)
        end
        ffi_fill(buf, size)
        local p = ffi_cast("int32_t *", buf)

        p[0] = 0                                    -- 1 segment
        p[1] = (size - 8) / 8

        write_structp(buf + 8, _M.%s, 0)
        _M.%s.flat_serialize(data, buf + 16)

        return ffi_string(buf, size)
    end,
]], name, name, name))
end

function comp_flat_serialize(res, struct, fields, size, name)
    insert(res, format([[

    flat_serialize = function(data, buf)
        local pos = %d
        local dscrm]], size))

    for i, field in ipairs(fields) do
        print("comp_field", field.name)
        -- union
        if field.discriminantValue then
            insert(res, format([[

        if data.%s then
            dscrm = %d
        end
]], field.name, field.discriminantValue))
--[=[
            if field.type_name == "void" then

                insert(res, format([[

        if data.%s then -- type is "Void"
            _M.%s.which(buf, %d, %d) --buf, discriminantOffset, discriminantValue]],
                    field.name, name, struct.discriminantOffset,
                    field.discriminantValue))
            else

                insert(res, format([[

        if data.%s and (type(data.%s) == "number"
                or type(data.%s) == "boolean") then]], field.name, field.name,
                    field.name))

                insert(res, format([[

            _M.%s.which(buf, %d, %d) --buf, discriminantOffset, discriminantValue
            write_val(buf, data.%s, %d, %d) -- buf, val, size, offset]], name,
                    struct.discriminantOffset,
                    field.discriminantValue, field.name, field.size,
                    field.slot.offset))
            end
            insert(res, "\n        end")
        --]=]
        end
        if field.group then
            insert(res, format([[

        if data.%s and type(data.%s) == "table" then
            -- groups are just namespaces, field offsets are set within parent
            -- structs
            _M.%s.%s.flat_serialize(data.%s, buf)
        end
]], field.name, field.name, name, field.name, field.name))

        elseif field.type_name == "enum" then
            insert(res, format([[

        if data.%s and type(data.%s) == "string" then
            local val = get_enum_val(data.%s, _M.%s, "%s.%s")
            write_val(buf, val, %d, %d)
        end]], field.name, field.name, field.name, field.type_display_name,
                     name, field.name, field.size, field.slot.offset))

        elseif field.type_name == "list" then
            local off = field.slot.offset
            insert(res, format([[

        if data.%s and type(data.%s) == "table" then
            local data_off = get_data_off(_M.%s, %d, pos)

            local len = #data.%s
            write_listp_buf(buf, _M.%s, %d, %d, len, data_off)

            for i=1, len do
                write_val(buf + pos, data.%s[i], %d, i - 1) -- 8 bits
            end
            pos = pos + round8(len * 1) -- 1 ** actual size
        end]], field.name, field.name, name, off, field.name, name, off,
                    field.size, field.name, list_size_map[field.size] * 8))

        elseif field.type_name == "struct" then
            local off = field.slot.offset
            insert(res, format([[

        if data.%s and type(data.%s) == "table" then
            local data_off = get_data_off(_M.%s, %d, pos)
            write_structp_buf(buf, _M.%s, _M.%s, %d, data_off)
            local size = _M.%s.flat_serialize(data.%s, buf + pos)
            pos = pos + size
        end]], field.name, field.name, name, off, name, field.type_display_name,
                    off, field.type_display_name, field.name))

        elseif field.type_name == "text" then
            local off = field.slot.offset
            insert(res, format([[

        if data.%s and type(data.%s) == "string" then
            local data_off = get_data_off(_M.%s, %d, pos)

            local len = #data.%s + 1
            write_listp_buf(buf, _M.%s, %d, %d, len, data_off)

            ffi_copy(buf + pos, data.%s)
            pos = pos + round8(len)
        end]], field.name, field.name, name, off, field.name, name, off, 2, field.name))

        elseif field.type_name == "data" then
            local off = field.slot.offset
            insert(res, format([[

        if data.%s and type(data.%s) == "string" then
            local data_off = get_data_off(_M.%s, %d, pos)

            local len = #data.%s
            write_listp_buf(buf, _M.%s, %d, %d, len, data_off)

            ffi_copy(buf + pos, data.%s)
            pos = pos + round8(len)
        end]], field.name, field.name, name, off, field.name, name, off, 2, field.name))

        else
            insert(res, format([[

        if data.%s and (type(data.%s) == "number"
                or type(data.%s) == "boolean") then

            write_val(buf, data.%s, %d, %d)
        end]], field.name, field.name, field.name, field.name, field.size,
                    field.slot.offset))

        end

    end

    if struct.discriminantOffset then
        insert(res, format([[

        if dscrm then
            _M.%s.which(buf, %d, dscrm) --buf, discriminantOffset, discriminantValue
        end
]],  name, struct.discriminantOffset))
    end

    insert(res, [[
        return pos
    end,]])
end


function comp_calc_size(res, fields, size, name)
    insert(res, format([[
    calc_size_struct = function(data)
        local size = %d]], size))

    for i, field in ipairs(fields) do
        if field.type_name == "list" then
            insert(res, format([[

        -- list
        if data.%s then
            size = size + round8(#data.%s * %d) -- num * acutal size
        end]], field.name, field.name, list_size_map[field.size]))
        elseif field.type_name == "struct" then
            insert(res, format([[

        -- struct
        if data.%s then
            size = size + _M.%s.calc_size_struct(data.%s)
        end]], field.name, field.type_display_name, field.name))
        elseif field.type_name == "text" then
            insert(res, format([[

        -- text
        if data.%s then
            size = size + round8(#data.%s + 1) -- size 1, including trailing NULL
        end]], field.name, field.name))

        elseif field.type_name == "data" then
            insert(res, format([[

        -- data
        if data.%s then
            size = size + round8(#data.%s)
        end]], field.name, field.name))

        end

    end

    insert(res, format([[

        return size
    end,

    calc_size = function(data)
        local size = 16 -- header + root struct pointer
        return size + _M.%s.calc_size_struct(data)
    end,]], name))
end

function comp_which(res)
    insert(res, [[

    which = function(buf, offset, n)
        if n then
            -- set value
            write_val(buf, n, 16, offset)
        else
            -- get value
            return read_val(buf, "uint16", 16, offset)
        end
    end,
]])
end

function comp_struct(res, nodes, node, struct, name)

        if not struct.dataWordCount then
            struct.dataWordCount = 0
        end
        if not struct.pointerCount then
            struct.pointerCount = 0
        end

        insert(res, "    dataWordCount = ")
        insert(res, struct.dataWordCount)
        insert(res, ",\n")

        insert(res, "    pointerCount = ")
        insert(res, struct.pointerCount)
        insert(res, ",\n")

        if struct.discriminantCount then
            insert(res, "    discriminantCount = ")
            insert(res, struct.discriminantCount)
            insert(res, ",\n")
        end
        if struct.discriminantOffset then
            insert(res, "    discriminantOffset = ")
            insert(res, struct.discriminantOffset)
            insert(res, ",\n")
        end
        if struct.isGroup then
            insert(res, "    isGroup = true,\n")
        end
        struct.size = struct.dataWordCount * 8 + struct.pointerCount * 8

        if struct.fields then
            for i, field in ipairs(struct.fields) do
                comp_field(res, nodes, field)
                if field.group then
                    if not node.nestedNodes then
                        node.nestedNodes = {}
                    end
                    insert(node.nestedNodes, { name = field.name, id = field.group.typeId })
                end
            end
            if not struct.isGroup then
                comp_calc_size(res, struct.fields, struct.size, struct.type_name)
            end
            comp_flat_serialize(res, struct, struct.fields, struct.size,
                    struct.type_name)
            if not struct.isGroup then
                comp_serialize(res, struct.type_name)
            end
            if struct.discriminantCount and struct.discriminantOffset then
                comp_which(res)
            end
            comp_parse_struct_data(res, struct, struct.fields, struct.size,
                    struct.type_name)
            if not struct.isGroup then
                comp_parse(res, struct.type_name)
            end
        end
end

function comp_enum(res, enum, name, naming_func)
    if not naming_func then
        naming_func = util.upper_underscore_naming
    end

    -- string to enum
    insert(res, format([[
_M.%s = {
]], name))

    for i, v in ipairs(enum.enumerants) do
        if not v.codeOrder then
            v.codeOrder = 0
        end
        insert(res, format("    [\"%s\"] = %s,\n",
                naming_func(v.name), v.codeOrder))
    end
    insert(res, "\n}\n")

    -- enum to string
    insert(res, format([[
_M.%sStr = {
]], name))

    for i, v in ipairs(enum.enumerants) do
        if not v.codeOrder then
            v.codeOrder = 0
        end
        insert(res, format("    [%s] = \"%s\",\n",
                 v.codeOrder, naming_func(v.name)))
    end
    insert(res, "\n}\n")
end

naming_funcs = {
    lower_underscore = util.lower_underscore_naming,
    upper_underscore = util.upper_underscore_naming,
    camel            = util.camel_naming,
}

function process_annotations(annos, nodes, res)
    for i, anno in ipairs(annos) do
        local id = anno.id
        local anno_node = nodes[id]
        if get_name(anno_node.displayName) == "naming" then
            local func = naming_funcs[anno.value.text]
            if func then
                res.naming_func = func
            end
        end
    end

    return res
end

function comp_node(res, nodes, node, name)
    if not node then
        print("Ignoring node: ", name)
        return
    end

    if node.annotation then
        -- do not need to generation any code for annotations
        return
    end

    node.name = name
    node.type_name = get_name(node.displayName)

    local s = node.struct
    if s then

    insert(res, format([[
_M.%s = {
]], name))
        s.type_name = node.type_name
        insert(res, format([[
    id = %s,
    displayName = "%s",
]], node.id, node.displayName))
        comp_struct(res, nodes, node, s, name)
    insert(res, "\n}\n")
    end

    local e = node.enum
    if e then
        local anno_res = {}
        if node.annotations then
            process_annotations(node.annotations, nodes, anno_res)
        end

        comp_enum(res, e, name, anno_res.naming_func)
    end

    if node.nestedNodes then
        for i, child in ipairs(node.nestedNodes) do
            comp_node(res, nodes, nodes[child.id], name .. "." .. child.name)
        end
    end
end

function comp_body(res, schema)
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
        insert(res, k .. ".enum_schema = _M." ..
                get_name(nodes[v].displayName .. "\n"))
    end

    insert(res, "\nreturn _M\n")
end

function comp_import(res, nodes, import)
    local id = import.id

    local import_node = nodes[id]
    for i, node in ipairs(import_node.nestedNodes) do
        comp_node(res, nodes, nodes[node.id], node.name)
    end
end

function comp_file(res, nodes, file)
    local id = file.id

    local file_node = nodes[id]
    for i, node in ipairs(file_node.nestedNodes) do
        comp_node(res, nodes, nodes[node.id], node.name)
    end
end

function comp_dg_node(res, nodes, node)
    if not node.struct then
        return
    end

    local name = gsub(lower(node.name), "%.", "_")
    insert(res, format([[
function gen_%s()
    if rand.random_nil() then
        return nil
    end

]], name))

    if node.nestedNodes then
        for i, child in ipairs(node.nestedNodes) do
            comp_dg_node(res, nodes, nodes[child.id])
        end
    end

    insert(res, format("    local %s  = {}\n", name))
    for i, field in ipairs(node.struct.fields) do
        if field.group then
            -- TODO group stuffs
        elseif field.type_name == "struct" then
            insert(res, format("    %s.%s = gen_%s()\n", name,
                    field.name,
                    gsub(lower(field.type_display_name), "%.", "_")))

        elseif field.type_name == "enum" then
        elseif field.type_name == "list" then
            local list_type = field.element_type
            --[[
            for k, v in pairs(field.slot["type"].list.elementType) do
                list_type = k
                break
            end
            ]]
            insert(res, format("    %s.%s = rand.%s(rand.uint8(), rand.%s)\n", name,
                    field.name, field.type_name, list_type))

        else
            insert(res, format("    %s.%s = rand.%s()\n", name,
                    field.name, field.type_name))
        end
    end


    insert(res, format([[
    return %s
end

]], name))
end

function compile_data_generator(schema)
    local res = {}
    insert(res, [[

local rand = require("random")
local cjson = require("cjson")
local pairs = pairs

local ok, new_tab = pcall(require, "table.new")

if not ok then
    new_tab = function (narr, nrec) return {} end
end

module(...)
]])

    local files = schema.requestedFiles
    local nodes = schema.nodes

    for i, file in ipairs(files) do
        local file_node = nodes[file.id]

        for i, node in ipairs(file_node.nestedNodes) do
            comp_dg_node(res, nodes, nodes[node.id])
        end
    end

    return table.concat(res)
end

function compile(schema)
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

--[[
local t = get_schema_text(f)

local file = io.open("test.schema.lua", "w")
file:write(t)
file:close()

local schema = assert(loadstring(t))()
]]

local schema = util.parse_capnp_decode(f, "test.schema.lua")
local outfile = get_output_name(schema)

local res = compile(schema)

local file = io.open(outfile, "w")
file:write(res)
file:close()


local outfile = "data_generator.lua"
local res = compile_data_generator(schema)

local file = assert(io.open(outfile, "w"))
file:write(res)
file:close()

