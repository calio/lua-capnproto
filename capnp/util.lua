local ffi = require "ffi"
local bit = require "bit"
local lower = string.lower
local upper = string.upper
local gsub = string.gsub
local format = string.format
local concat = table.concat
local insert = table.insert

local tohex = bit.tohex

local _M = {}

function _M.upper_dash_naming(name)
    return upper(gsub(name, "(%u+)", "-%1"))
end

function _M.lower_underscore_naming(name)
    return lower(gsub(name, "(%u+)", "_%1"))
end

function _M.upper_underscore_naming(name)
    return upper(gsub(name, "(%u+)", "_%1"))
end

function _M.lower_space_naming(name)
    return lower(gsub(name, "(%u+)", " %1"))
end

-- capnp only allow camel naming for enums
function _M.camel_naming(name)
    return name
end

function _M.parse_capnp_txt(s)
    s = gsub(s, "%(", "{")
    s = gsub(s, "%)", "}")
    s = gsub(s, "%[", "{")
    s = gsub(s, "%]", "}")
    s = gsub(s, "%<", "'")
    s = gsub(s, "%>", "'")
    s = gsub(s, "id = (%d+)", "id = \"%1\"")
    s = gsub(s, "typeId = (%d+)", "typeId = \"%1\"")
    s = gsub(s, "scopeId = (%d+)", "scopeId = \"%1\"")
    s = gsub(s, "= void([^\"])", "= \"void\"%1")
    s = gsub(s, "type = {", '[\"type\"] = {')
    s = "return " .. s

    return s
end

function _M.parse_capnp_decode_txt(infile)
    local f = io.open(infile)
    if not f then
        return nil, "Can't open file: " .. tostring(infile)
    end

    local s = f:read("*a")
    f:close()

    return _M.parse_capnp_txt(s)
end

function _M.table_diff(t1, t2, namespace)
    local keys = {}

    if not namespace then
        namespace = ""
    end

    for k, v in pairs(t1) do
        k = _M.lower_underscore_naming(k)
        keys[k] = true
        t1[k] = v
    end

    for k, v in pairs(t2) do
        k = _M.lower_underscore_naming(k)
        keys[k] = true
        t2[k] = v
    end

    for k, v in pairs(keys) do
        local name = namespace .. "." .. k
        local v1 = t1[k]
        local v2 = t2[k]

        local t1 = type(v1)
        local t2 = type(v2)

        if t1 ~= t2 then
            print(format("%s: different type: %s %s, value: %s %s", name,
                    t1, t2, tostring(v1), tostring(v2)))
        elseif t1 == "table" then
            _M.table_diff(v1, v2, namespace .. "." .. k)
        elseif v1 ~= v2 then
            print(format("%s: different value: %s %s", name,
                    tostring(v1), tostring(v2)))
        end
    end
end

function _M.read_file(name)
    local f = assert(io.open(name, "r"))
    local content = f:read("*a")
    f:close()
    return content
end

function _M.write_file(name, content)
    local f = assert(io.open(name, "w"))
    f:write(content)
    f:close()
end

function _M.get_output_name(schema)
    return string.gsub(schema.requestedFiles[1].filename, "%.capnp", "_capnp")
end

function _M.hex_buf_str(buf, len)
    local str = ffi.string(buf, len)
    local t = {}
    for i = 1, len do
        table.insert(t, tohex(string.byte(str, i), 2))
    end
    return table.concat(t, " ")
end
function _M.print_hex_buf(buf, len)
    local str = _M.hex_buf_str(buf, len)
    print(str)
end

function _M.new_buf(hex, ct)
    if type(hex) ~= "table" then
        error("expected the first argument as a table")
    end
    local len = #hex
    local buf = ffi.new("char[?]", len)
    for i=1, len do
        buf[i - 1] = hex[i]
    end
    if not ct then
        ct = "uint32_t *"
    end
    return ffi.cast(ct, buf)
end

local function equal(a, b)
    if type(a) == "boolean" then
        a = a and 1 or 0
    end
    if type(b) == "boolean" then
        b = b and 1 or 0
    end
    return a == b
end

local function to_text_core(val, T, res)
    local typ = type(val)
    if typ == "table" then
        if #val > 0 then
            -- list
            insert(res, "[")
            for i = 1, #val do
                if i ~= 1 then
                    insert(res, ", ")
                end
                insert(res, '"')
                insert(res, val[i])
                insert(res, '"')
            end
            insert(res, "]")
        else
            -- struct
            insert(res, "(")
            local i = 1
            for _, item in pairs(T.fields) do
                local k = item.name
                local default = item.default
                if type(default) == "boolean" then
                    default = default and 1 or 0
                end
                if val[k] ~= nil then
--                    if not equal(val[k], default) then
                        if i ~= 1 then
                            insert(res, ", ")
                        end
                        insert(res, k)
                        insert(res, " = ")
                        to_text_core(val[k], T[k], res)
                        i = i + 1
 --                   end
                end
            end
            insert(res, ")")
        end
    elseif typ == "string" then
        if val == "Void" then
            insert(res, "void")
        else
            insert(res, '"')
            insert(res, val)
            insert(res, '"')
        end
    elseif typ == "boolean" then
        insert(res, val and "true" or "false")
    else
        if type(val) == "cdata" then
            --val = string.sub(tostring(val), 1, -3)
            val = tostring(val)
        end
        insert(res, val)
    end
end

function _M.to_text(val, T)
    local res = {}
    to_text_core(val, T, res)
    return concat(res)
end

local function get_type(typ)
    if not typ then
        return
    end

    for k, v in pairs(typ) do
        if k == "struct" then
            return k, typ[k].typeId
        end
        return k, get_type(typ[k].elementType)
    end
end

function _M.get_field_type(field)
    if field and field.slot and field.slot["type"] then
        return { get_type(field.slot["type"]) }
    end

    return
end
return _M
