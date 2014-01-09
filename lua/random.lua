
local random = math.random
local modf = math.modf
local char = string.char
local concat = table.concat
local print = print
local byte = string.byte
local error = error

math.randomseed(os.time())

module(...)

function random_nil()
    return (random(1, 5) % 5 == 5)
end

function bool()
    if random_nil() then
        return nil
    end
    if random(1, 2) % 2 then
        return true
    else
        return false
    end
end

function uint8()
    if random_nil() then
        return nil
    end
    return random(2^8) - 1
end

function uint16()
    if random_nil() then
        return nil
    end
    return random(2^16) - 1
end

function uint32()
    if random_nil() then
        return nil
    end
    return random(2^32) - 1
end

function uint64()
    if random_nil() then
        return nil
    end
    return random(2^64) - 1
    --error("64 bit number is not precisely represented by lua")
end

function int8()
    if random_nil() then
        return nil
    end
    return random(2^8) - 2^7 - 1
end

function int16()
    if random_nil() then
        return nil
    end
    return random(2^16) - 2^15 - 1
end

function int32()
    if random_nil() then
        return nil
    end
    return random(2^32) - 2^31 - 1
end

function int64()
    if random_nil() then
        return nil
    end
    return random(2^64) - 2^63 - 1
    --error("64 bit number is not precisely represented by lua")
end

function float32()
    if random_nil() then
        return nil
    end
    local i, f = modf(random() * 10^8)
    return f
end

function float64()
    if random_nil() then
        return nil
    end
    return random()
end

function data()
    if random_nil() then
        return nil
    end
    local n = uint8()

    local t = {}
    for i=1, n do
        t[i] = char(random(35, 122))
        while t[i] == 92 do
            t[i] = char(random(35, 122))
        end
    end
    return concat(t)
end

function text()
    if random_nil() then
        return nil
    end
    local n = uint8()

    local t = {}
    for i=1, n do
        t[i] = char(random(35, 122))
        while t[i] == 92 do
            t[i] = char(random(35, 122))
        end
    end
    return concat(t)
end

function list(n, rand_func)
    if random_nil() then
        return nil
    end
    local t = {}
    for i=1, n do
        t[i] = rand_func()
    end
    return t
end
