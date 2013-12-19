local ffi = require "ffi"
local bit = require "bit"

local tobit = bit.tobit
local bnot = bit.bnot
local band, bor, bxor = bit.band, bit.bor, bit.bxor
local lshift, rshift, rol = bit.lshift, bit.rshift, bit.rol

local _M = {}

local buffer
local buffer_offset = 0

-- buffer size in word
local bwrite = function(buf, val, size, off)
    if type(val) == "boolean" then
        val = val and 1 or 0
    end

    local bit_off = size * off
    local n = math.floor(bit_off / 64)
    local s = bit_off % 64

    if (size == 64) then
        print(string.format("n %d, s %d, %d\n", n, s, val))
        buf[n] = bor(tonumber(buf[n]), lshift(val, s))
    elseif (size < 64) then
        n = math.floor(bit_off / 32)
        s = bit_off % 32
        print(string.format("n %d, s %d, %d\n", n, s, val))
        buf = ffi.cast("int32_t *", buf)
        buf[n] = bor(tonumber(buf[n]), lshift(val, s))
    else
        error("not supported size: " .. size)
    end
end

function serialize_header(segs, sizes)
    assert(type(sizes) == "table")
    -- in bytes
    local size = 4 + segs * 4
    local words = math.ceil(size / 64)
    local buf = ffi.new("int32_t[?]", words * 2)

    buf[0] = segs - 1
    for i=1, segs do
        buf[i] = assert(math.ceil(sizes[i]/8))
    end

    return ffi.string(ffi.cast("char *", buf), size)
end

function serialize(T)
    local msg_size = (T.dataWordCount + 1) * 8
    return serialize_header(1, {msg_size}) .. serialize_struct(T)
    --return ffi.string(buffer, msg_size)
end

function serialize_struct(T)
    local msg_size = (T.dataWordCount + 1) * 8
    return ffi.string(buffer, msg_size)
end

_M.T1 = {
    id = 13624321058757364083,
    displayName = "test.capnp:T1",
    dataWordCount = 2,
    fields = {
        i0 = { size = 32, offset = 0 },
        i1 = { size = 16, offset = 2 },
        i2 = { size = 8, offset = 7 },
        b0 = { size = 1, offset = 48 },
        b1 = { size = 1, offset = 49 },
        i3 = { size = 32, offset = 2 },
    },

    serialize = function(message)
        return rawget(messaga)
    end
    ,

    new = function(self)
        buffer = ffi.new("int64_t[?]", 1 + self.dataWordCount)
        buffer[0] = 0x0000000200000000
        buffer_offset = buffer_offset + 1

        local mt = {
            __newindex = function (t, k, v)
                print(string.format("%s, %s\n", k, v))
                local schema = self.fields
                local size = assert(schema[k].size)
                local offset = assert(schema[k].offset)
                print(string.format("%d, %d\n", size, offset))
                bwrite(buffer + buffer_offset, v, size, offset)
            end
        }
        return setmetatable({
        }, mt)
    end
}

return _M
