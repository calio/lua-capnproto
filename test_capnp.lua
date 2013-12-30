local ffi = require "ffi"
local bit = require "bit"

local tobit = bit.tobit
local bnot = bit.bnot
local band, bor, bxor = bit.band, bit.bor, bit.bxor
local lshift, rshift, rol = bit.lshift, bit.rshift, bit.rol

local _M = {}

assert(ffi.abi("le") == true)

--[[
local segment = {
    data = "",
    offset = 0, -- in words
    size = 0, -- in bytes
}]]


local bwrite_pointer = function(buf, ftype, off)
    if ftype == "list" then

    end
end

-- segment size in word
local bwrite_plain = function(buf, val, size, off)
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

_M.serialize = function (msg)
    local segment = assert(rawget(msg, "segment"))
    --local msg_size = (T.dataWordCount + 1) * 8
    return serialize_header(1, { segment.pos }) .. ffi.string(segment.data, segment.pos)
end

function bwrite_listp(buf, elm_size, nelm, offset)
    buf.data[0] = 0x0000000000000001
    local p = ffi.cast("int32_t *", buf.data)
    --local offset = buf.offset -- FIXME
    p[0] = bor(tonumber(p[0]), rshift(offset, 2))
    p[1] = rshift(T.pointerCount, 16) + T.dataWordCount

    buf.offset = buf.offset + math.ceil(elm_size * nelm/64)
end

-- write struct pointer
function bwrite_structp(seg, T, data_off)
    local p = ffi.cast("int32_t *", seg.data + seg.pos)

    print(string.format("%s, pointer count:%d, data word count:%d", T.displayName, T.pointerCount, T.dataWordCount))
    -- A = 0
    p[0] = lshift(data_off, 2)
    p[1] = lshift(T.pointerCount, 16) + T.dataWordCount
    seg.pos = seg.pos + 8 -- 64 bits -> 8 bytes
end

-- allocate space for struct body
function bwrite_struct(seg, T)
    -- TODO buf must be in segment
    local buf = seg.data + seg.pos

    --local offset = seg.data + seg.offset - buf
    --bwrite_structp(buf, T, offset)

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

function init_root(segment, T)
    bwrite_structp(segment, T, 0) -- offset 0 (in words)
print(segment.pos)
    return bwrite_struct(segment, T)
end

-- in bytes
function new_segment(size)
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

function msg_newindex(t, k, v)
    print(string.format("%s, %s\n", k, v))
    local T = rawget(t, "T")
    local schema = T.fields
    local size = assert(schema[k].size)
    local offset = assert(schema[k].offset)
    if schema[k].is_pointer then
        ftype = schema[k].ftype
        if ftype == "data" then
            error("not implemented")
            --bwrite_listp(rawget(t, "pointer_pos"), 1, #v, )
        end
    else
        bwrite_plain(rawget(t, "data_pos"), v, size, offset)
    end

    --print(string.format("%d, %d\n", size, offset))
end

------------------------------------------------------------------

_M.T1 = {
    T2 = {
        id = 13624321058757364083,
        displayNmae = "test.capnp:T1.T2",
        dataWordCount = 2,
        pointerCount = 0,
        fields = {
            f0 = { size = 32, offset = 0 },
            f1 = { size = 64, offset = 1 },
        }

    },
    id = 13624321058757364083,
    displayName = "test.capnp:T1",
    dataWordCount = 2,
    pointerCount = 1,
    fields = {
        i0 = { size = 32, offset = 0 },
        i1 = { size = 16, offset = 2 },
        i2 = { size = 8, offset = 7 },
        b0 = { size = 1, offset = 48 },
        b1 = { size = 1, offset = 49 },
        i3 = { size = 32, offset = 2 },
        t0 = { is_pointer = true, ftype = "text" }
    },

    serialize = function(message)
        return rawget(messaga)
    end
    ,

    new = function(self)

        -- FIXME size
        local segment = new_segment(8000)
        local struct = init_root(segment, self)

        struct.init_s0 = function()
            local s = init_root(segment, self.T2)
            local mt = {
                __newindex =  msg_newindex
            }
            return setmetatable(s, mt)
        end
        local mt = {
            __newindex =  msg_newindex
        }
        return setmetatable(struct, mt)
    end
}

return _M
