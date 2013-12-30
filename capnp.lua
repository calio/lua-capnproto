
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

_M.read_val = function(buf, vtype, size, off)
end

-- segment size in word
-- TODO support 64 bit float number
_M.write_val = function(buf, val, size, off)

    local p = ffi.cast("int32_t *", buf)

    if type(val) == "boolean" then
        --print("boolean")
        val = val and 1 or 0
    else
        local i, f = math.modf(val)
        -- float number
        if (f ~= 0) then
            if size == 32 then
        --print("float32")
                p = ffi.cast("float *", p)
            elseif size == 64 then
        --print("float64")
                p = ffi.cast("double *", p)
            else
                error("float size other than 32 and 64")
            end
        else
            if size == 64 then
        --print("int64")
                p = ffi.cast("int64_t *", buf)
            else
        --print("int32")
            end
        end
    end


    local bit_off = size * off -- offset in bits
    local n, s
    if size <= 32 then
        n = math.floor(bit_off / 32) -- offset in 4 bytes
        s = bit_off % 32     -- offset within 4 bytes
    elseif size == 64 then
        n = math.floor(bit_off / 64) -- offset in 8 bytes
        s = bit_off % 64     -- offset within 8 bytes
    end

    --print(string.format("n %d, s %d, %d\n", n, s, val))

    -- shift returns 32 bit number
    if (size < 32) then
        p[n] = bor(tonumber(p[n]), lshift(val, s))
    else
        -- 32 bit or 64 bit
        p[n] = val
    end
end

_M.write_structp = function (buf, T, data_off)
    --print(string.format("%s, pointer count:%d, data word count:%d", T.displayName, T.pointerCount, T.dataWordCount))
    local p = ffi.cast("int32_t *", buf)
    p[0] = lshift(data_off, 2)
    p[1] = lshift(T.pointerCount, 16) + T.dataWordCount
end

_M.write_structp_seg = function(seg, T, data_off)
    local p = ffi.cast("int32_t *", seg.data + seg.pos)

    --print(string.format("%s, pointer count:%d, data word count:%d", T.displayName, T.pointerCount, T.dataWordCount))
    -- A = 0
    _M.write_structp(p, T, data_off)
    seg.pos = seg.pos + 8 -- 64 bits -> 8 bytes
end

-- allocate space for struct body
_M.write_struct = function(seg, T)
    -- TODO buf must be in segment
    local buf = seg.data + seg.pos

    --local offset = seg.data + seg.offset - buf
    --capnp.write_structp_seg(buf, T, offset)

    local struct = {
        segment         = seg,
        --header_pos      = buf,
        data_pos        = seg.data + seg.pos,
        pointer_pos     = seg.data + seg.pos + T.dataWordCount * 8,
        T               = T,
    }
    seg.pos = seg.pos + T.dataWordCount * 8 + T.pointerCount * 8

    return struct
end

return _M
