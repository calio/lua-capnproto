
local random = math.random
local modf = math.modf
local char = string.char
local concat = table.concat

math.randomseed(os.time())

module(...)

function bool()
    if random(1, 2) % 2 then
        return true
    else
        return false
    end
end

function uint8()
    return random(2^8) - 1
end

function uint16()
    return random(2^16) - 1
end

function uint32()
    return random(2^32) - 1
end

function uint64()
    error("64 bit number is not precisely represented by lua")
end

function int8()
    return random(2^8) - 2^7 - 1
end

function int16()
    return random(2^16) - 2^15 - 1
end

function int32()
    return random(2^32) - 2^31 - 1
end

function int64()
    error("64 bit number is not precisely represented by lua")
end

function float32()
    local i, f = modf(random() * 10^8)
    return f
end

function float64()
    return random()
end

function text()
    local n = uint8()

    local t = {}
    for i=1, n do
        t[i] = char(random(32, 126))
    end
    return concat(t)
end

function list(n, rand_func)
    local t = {}
    for i=1, n do
        t[i] = rand_func()
    end
    return t
end
