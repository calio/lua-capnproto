
local ffi = require "ffi"
local bit = require "bit"

local tobit = bit.tobit
local bnot = bit.bnot
local band, bor, bxor = bit.band, bit.bor, bit.bxor
local lshift, rshift, rol = bit.lshift, bit.rshift, bit.rol


-- FIXME prealloc
local _M = {}
-- in bytes
_M.new_segment = function(size)
    local segment = {
        pos = 0, -- point to free space
        used = 0, -- bytes used
        len = 0,
    }

    if size % 8 ~= 0 then
        error("size should be devided by 8")
    end
    -- set segment size
    --local word_size = 1 + T.dataWordCount + T.pointerCount
    segment.data = ffi.new("int8_t[?]", size)
    segment.len = size

    return segment
end

-- segment size in word
-- TODO support 64 bit float number
_M.write_val = function(buf, val, size, off)
    if type(val) == "boolean" then
        val = val and 1 or 0
    end

    local p = ffi.cast("int32_t *", buf)
    local bit_off = size * off -- offset in bits
    local n = math.floor(bit_off / 32) -- offset in 4 bytes
    local s = bit_off % 32     -- offset within 4 bytes

    print(string.format("n %d, s %d, %d\n", n, s, val))
    buf = ffi.cast("int32_t *", buf)

    -- shift returns 32 bit number
    if (size < 32) then
        buf[n] = bor(tonumber(buf[n]), lshift(val, s))
    elseif (size == 32) then
        local i, f = math.modf(val)
        if (f ~= 0) then
            buf = ffi.cast("float *", buf)
        end
        buf[n] = val
    else
        error("not supported size: " .. size)
    end
end

return _M
