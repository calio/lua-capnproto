local lower = string.lower
local upper = string.upper
local gsub = string.gsub

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
    s = gsub(s, "void", "\"void\"")
    s = "return " .. s

    if outfile then
        local file = io.open(outfile, "w")
        file:write(s)
        file:close()
    end

    return assert(loadstring(s))()
end

return _M
