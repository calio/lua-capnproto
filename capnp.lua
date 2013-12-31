local ffi = require "ffi"
local bit = require "bit"

local tobit = bit.tobit
local bnot = bit.bnot
local band, bor, bxor = bit.band, bit.bor, bit.bxor
local lshift, rshift, rol = bit.lshift, bit.rshift, bit.rol

-- works only with Little Endian
assert(ffi.abi("le") == true)

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
    local p = ffi.cast("int32_t *", buf)
    p[0] = lshift(data_off, 2)
    p[1] = lshift(T.pointerCount, 16) + T.dataWordCount
end

_M.write_structp_seg = function(seg, T, data_off)
    local p = ffi.cast("int32_t *", seg.data + seg.pos)

    -- A = 0
    _M.write_structp(p, T, data_off)
    seg.pos = seg.pos + 8 -- 64 bits -> 8 bytes
end

-- allocate space for struct body
_M.write_struct = function(seg, T)
    local buf = seg.data + seg.pos

    --local offset = seg.data + seg.offset - buf
    --_M.write_structp_seg(buf, T, offset)

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

_M.init_root = function (segment, T)
    assert(T)
    _M.write_structp_seg(segment, T, 0) -- offset 0 (in words)
    return _M.write_struct(segment, T)
end

_M.get_enum_val = function (v, enum_name, T)
    assert(enum_name)
    return T[enum_name][v]
end

_M.write_listp = function (buf, size_type, num, data_off)
    local p = ffi.cast("int32_t *", buf)
    assert(size_type <= 7)
    -- List: A = 1
    p[0] = lshift(data_off, 2) + 1
    p[1] = lshift(num, 3) + size_type
end

-- see http://kentonv.github.io/_Mroto/encoding.html#lists
local list_size_map = {
    [0] = 0,
    [1] = 0.125,
    [2] = 1,
    [3] = 2,
    [4] = 4,
    [5] = 8,
    [6] = 8,
    -- 7 = ?,
}

local round8 = function(size)
    return math.ceil(size / 8) * 8
end

-- in here size is not the actual size, use list_size_map to get actual size
_M.write_list = function (seg, size_type, num)
    local buf = seg.data + seg.pos

    local actual_size = assert(list_size_map[size_type])
    local list = {
        segment         = seg,
        data            = seg.data + seg.pos,
        size_type       = size_type,
        actual_size     = actual_size,
        num             = num,
    }

    if actual_size == 64 then
        list.data = ffi.cast("int64_t *", list.data)
    elseif actual_size == 32 then
        list.data = ffi.cast("int32_t *", list.data)
    elseif actual_size == 16 then
        list.data = ffi.cast("int16_t *", list.data)
    elseif actual_size <= 8 then
        list.data = ffi.cast("int8_t *", list.data)
    else
        error("unsupported size: " .. tostring(actual_size))
    end

    local list_size = round8(actual_size * num)
    print("list size", list_size)

    seg.pos = seg.pos + list_size

    return list
end

_M.write_text = function(seg, str)
    -- TODO check if str is valid utf8
    return _M.write_data(seg, str)
end

_M.write_data = function(seg, str)
    if seg.len - seg.pos < #str then
        return nil, "not enough space in segment"
    end
    ffi.copy(seg.data + seg.pos, str)
    seg.pos = seg.pos + round8(#str + 1) -- include trailing NULL
    return true
end


_M.list_newindex = function (t, k, v)
    local num = assert(rawget(t, "num"))

    if k > num then
        error("access out of boundry")
    end

    assert(k > 0)
    local data = assert(rawget(t, "data"))
    local actual_size = assert(rawget(t, "actual_size"))

    print("list_newindex", k, v, num, actual_size)

    if actual_size == 0 then
        -- do nothing
    elseif actual_size == 0.125 then
        if v == 1 then
            local n = math.floor(k / 8)
            local s = k % 8
            data[n] = bor(data[n], lshift(1, s))
        end
    else
        data[k - 1] = v
    end
end

_M.struct_newindex = function (t, k, v)
    --print(string.format("%s, %s\n", k, v))
    local T = rawget(t, "T")
    local schema = T.fields
    local field = schema[k]

    -- TODO deal with unknown value
    if field.is_enum then
        v = _M.get_enum_val(v, field.enum_name, T)
    end

    if field.is_data or field.is_text  then
        local segment = assert(rawget(t, "segment"))
        local data_pos = assert(rawget(t, "pointer_pos")) + field.offset * 8 -- l0.offset * l0.size (pointer size is 8)
        local data_off = ((segment.data + segment.pos) - (data_pos + 8)) / 8 -- unused memory pos - list pointer end pos, result in bytes. So we need to divide this value by 8 to get word offset

        print("t0", data_off, #v)
        _M.write_listp(data_pos, 2, #v + 1,  data_off) -- 2: l0.size

        local ok, err
        if field.is_data then
            ok, err = _M.write_data(segment, v) -- 2: l0.size
        else
            ok, err = _M.write_text(segment, v)
        end
        if not ok then
            error(err)
        end
    end

    local size = assert(field.size)
    local offset = assert(field.offset)
    if field.is_pointer then
        ftype = schema[k].ftype
        if ftype == "data" then
            error("not implemented")
            --bwrite_listp(rawget(t, "pointer_pos"), 1, #v, )
        end
    else
        _M.write_val(rawget(t, "data_pos"), v, size, offset)
    end
end

return _M
