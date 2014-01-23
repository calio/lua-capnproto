local ffi = require "ffi"
local lower = string.lower
local upper = string.upper
local gsub = string.gsub
local format = string.format

local _M = {}

function _M.lower_underscore_naming(name)
    return lower(gsub(name, "(%u+)", "_%1"))
end

function _M.upper_underscore_naming(name)
    return upper(gsub(name, "(%u+)", "_%1"))
end

-- capnp only allow camel naming for enums
function _M.camel_naming(name)
    return name
end

function _M.parse_capnp_decode(infile, outfile)
    local f = io.open(infile)
    if not f then
        return nil, "Can't open file: " .. tostring(infile)
    end

    local s = f:read("*a")
    f:close()

    s = gsub(s, "%(", "{")
    s = gsub(s, "%)", "}")
    s = gsub(s, "%[", "{")
    s = gsub(s, "%]", "}")
    s = gsub(s, "%<", "'")
    s = gsub(s, "%>", "'")
    s = gsub(s, "id = (%d+)", "id = \"%1\"")
    s = gsub(s, "typeId = (%d+)", "typeId = \"%1\"")
    s = gsub(s, "([^\"])void([^\"])", "%1\"void\"%2")
    s = "return " .. s

    if outfile then
        local file = io.open(outfile, "w")
        file:write(s)
        file:close()
    end

    return assert(loadstring(s))()
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

function _M.write_file(name, content)
    local f = assert(io.open(name, "w"))
    f:write(content)
    f:close()
end

function _M.get_output_name(schema)
    return string.gsub(schema.requestedFiles[1].filename, "%.", "_")
end

function _M.print_hex_buf(buf, len)
    local str = ffi.string(buf, len)
    local t = {}
    for i = 1, len do
        table.insert(t, bit.tohex(string.byte(str, i), 2))
    end
    print(table.concat(t, " "))
end

return _M
