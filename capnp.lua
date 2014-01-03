local ffi = require "ffi"
local bit = require "bit"

local tobit     = bit.tobit
local bnot      = bit.bnot
local band, bor, bxor = bit.band, bit.bor, bit.bxor
local lshift, rshift, rol = bit.lshift, bit.rshift, bit.rol

local format    = string.format
local lower     = string.lower
local ceil      = math.ceil
local floor     = math.floor

-- works only with Little Endian
assert(ffi.abi("le") == true)
assert(ffi.sizeof("float") == 4)
assert(ffi.sizeof("double") == 8)


local round8 = function(size)
    return ceil(size / 8) * 8
end

local SEGMENT_SIZE = 4096

ffi.cdef([[
typedef struct seg {
    int         pos;
    int         len;
    char       data[]] .. SEGMENT_SIZE .. [[];
    struct seg *next;
} segment;
]])

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(2, 32)

-- segment.len in bytes
function _M.new_segment()
    local segment = ffi.new("segment")

    segment.pos = 0
    segment.len = SEGMENT_SIZE

    return segment
end

function _M.write_val(buf, val, size, off)
    local p = ffi.cast("int32_t *", buf)

    if type(val) == "boolean" then
        val = val and 1 or 0
    else
        local i, f = math.modf(val)
        -- float number
        if (f ~= 0) then
            if size == 32 then
                p = ffi.cast("float *", p)
            elseif size == 64 then
                p = ffi.cast("double *", p)
            else
                error("float size other than 32 and 64")
            end
        else
            if size == 64 then
                p = ffi.cast("int64_t *", buf)
            else
                --print("int32")
            end
        end
    end


    local bit_off = size * off -- offset in bits
    local n, s
    if size <= 32 then
        n = floor(bit_off / 32) -- offset in 4 bytes
        s = bit_off % 32     -- offset within 4 bytes
    elseif size == 64 then
        n = floor(bit_off / 64) -- offset in 8 bytes
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

function _M.write_structp(buf, T, data_off)
    local p = ffi.cast("int32_t *", buf)
    p[0] = lshift(data_off, 2)
    p[1] = lshift(T.pointerCount, 16) + T.dataWordCount
end

function _M.write_structp_seg(seg, T, data_off)
    -- A = 0
    _M.write_structp(seg.data + seg.pos, T, data_off)
    seg.pos = seg.pos + 8 -- 64 bits -> 8 bytes
end

-- allocate space for struct body
function _M.write_struct(seg, T)
    local struct = {
        segment         = seg,
        data_pos        = seg.data + seg.pos,
        pointer_pos     = seg.data + seg.pos + T.dataWordCount * 8,
        T               = T,
    }
    seg.pos = seg.pos + T.dataWordCount * 8 + T.pointerCount * 8

    return struct
end

function _M.init_root(segment, T)
    --assert(T)
    _M.write_structp_seg(segment, T, 0) -- offset 0 (in words)
    return _M.write_struct(segment, T)
end

function _M.get_enum_val(v, enum_schema)
    assert(enum_schema)
    v = lower(v)
    local r = enum_schema[v]
    if not r then
        v = 
        error("Unknown enum val:" .. v)
    end
    return r
end

function _M.write_listp(buf, size_type, num, data_off)
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

-- in here size is not the actual size, use list_size_map to get actual size
function _M.write_list(seg, size_type, num)
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

    seg.pos = seg.pos + list_size

    return list
end

function _M.write_text(seg, str)
    -- TODO check if str is valid utf8
    return _M.write_data(seg, str)
end

function _M.write_data(seg, str)
    if seg.len - seg.pos < #str then
        return nil, format("not enough space in segment, pos:%d len:%d",
                seg.pos, seg.len)
    end
    ffi.copy(seg.data + seg.pos, str)

    -- include trailing NULL, align to word boundry
    seg.pos = seg.pos + round8(#str + 1)
    return true
end


function _M.list_newindex(t, k, v)
    local num = t.num

    if k > num then
        error("access out of boundry")
    end

    assert(k > 0)
    local data = t.data
    local actual_size = t.actual_size

    --print("list_newindex", k, v, num, actual_size)

    if actual_size == 0 then
        -- do nothing
    elseif actual_size == 0.125 then
        if v == 1 then
            local n = floor(k / 8)
            local s = k % 8
            data[n] = bor(data[n], lshift(1, s))
        end
    else
        data[k - 1] = v
    end
end

function _M.struct_newindex(t, k, v)
    local T = t.T
    local fields = T.fields
    local field = fields[k]
    local size = assert(field.size)
    local offset = assert(field.offset)

    if not field then
        error("Field not fount: " .. k)
    end

    -- TODO deal with unknown value
    if field.is_enum then
        if not field.enum_schema then
            error("No enum schema: " .. field.name)
        end
        v = _M.get_enum_val(v, field.enum_schema)
    end

    if field.is_pointer then
        error("use init_<field_name> method")
    elseif field.is_data or field.is_text then
        local segment = t.segment
        local data_pos = t.pointer_pos + field.offset * 8 -- pointer size is 8

        -- unused memory pos - list pointer end pos, result in bytes.
        -- We need to divide this value by 8 to get word offset
        local data_off = ((segment.data + segment.pos) - (data_pos + 8)) / 8

        --print("t0", data_off, #v)
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
    else
        _M.write_val(t.data_pos, v, size, offset)
    end
end

function _M.serialize_header(seg_sizes)
    assert(type(seg_sizes) == "table")
    local num = #seg_sizes

    assert(num > 0)
    local size = 4 + num * 4    -- in bytes
    size = round8(size)         -- align to word boundry
--print(size, num, "\n")

    local buf   = ffi.new("char[?]", size)
    local p     = ffi.cast("int32_t *", buf)

    p[0] = num - 1
    for i=1, num do
        p[i] = round8(seg_sizes[i]) / 8
    end

    return ffi.string(buf, size)
end

local _debug_segment_info = function(segment)
    print(format("data: %d, pos: %d, len: %d",
            tonumber(ffi.cast("intptr_t", segment.data)),
            segment.pos, segment.len))
end

function _M.serialize(msg)
    local segment = msg.segment
    --FIXME multi header
    return _M.serialize_header({ segment.pos })
            .. ffi.string(segment.data, segment.pos)
end

function _M.init_new_struct(struct)
    struct.serialize = function(self)
        return _M.serialize(self)
    end

    local mt = {
        __newindex = _M.struct_newindex
    }
    return setmetatable(struct, mt)
end
return _M
