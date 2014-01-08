local lower = string.lower
local upper = string.upper
local gsub = string.gsub
module(...)

function lower_underscore_naming(name)
    return lower(gsub(name, "(%u+)", "_%1"))
end

function upper_underscore_naming(name)
    return upper(gsub(name, "(%u+)", "_%1"))
end

-- capnp only allow camel naming for enums
function camel_naming(name)
    return name
end
