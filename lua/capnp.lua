local ffi = require "ffi"
local bit = require "bit"

local tobit     = bit.tobit
local bnot      = bit.bnot
local band, bor, bxor = bit.band, bit.bor, bit.bxor
local lshift, rshift, rol = bit.lshift, bit.rshift, bit.rol

local typeof    = ffi.typeof
local cast      = ffi.cast
local ffistr    = ffi.string
local format    = string.format
local lower     = string.lower
local ceil      = math.ceil
local floor     = math.floor
local byte      = string.byte
local type      = type
local modf      = math.modf
local substr    = string.sub

-- works only with Little Endian
assert(ffi.abi("le") == true)
assert(ffi.sizeof("float") == 4)
assert(ffi.sizeof("double") == 8)


local round8 = function(size)
    return ceil(size / 8) * 8
end

local SEGMENT_SIZE = 4096


local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(2, 32)


local function get_bit_offset(bit_off, size)
    local n, s
    n = floor(bit_off / size)
    s = bit_off % size

    return n, s
end

local pint8    = typeof("int8_t *")
local pint16   = typeof("int16_t *")
local pint32   = typeof("int32_t *")
local pint64   = typeof("int64_t *")
local puint8   = typeof("uint8_t *")
local puint16  = typeof("uint16_t *")
local puint32  = typeof("uint32_t *")
local puint64  = typeof("uint64_t *")
local pbool    = typeof("uint8_t *")
local pfloat32 = typeof("float *")
local pfloat64 = typeof("double *")

local pointer_map = {
    int8    = typeof("int8_t *"),
    int16   = typeof("int16_t *"),
    int32   = typeof("int32_t *"),
    int64   = typeof("int64_t *"),
    uint8   = typeof("uint8_t *"),
    uint16  = typeof("uint16_t *"),
    uint32  = typeof("uint32_t *"),
    uint64  = typeof("uint64_t *"),
    bool    = typeof("uint8_t *"),
    float32 = typeof("float *"),
    float64 = typeof("double *"),
}

local function get_pointer_from_type(buf, field_type)
    local t = pointer_map[field_type]
    if not t then
        error("not supported type: " .. field_type)
    end

    return cast(t, buf)
end

local function get_pointer_from_val(buf, size, val)
    local p = buf
    if size == 1 then
        p = cast(puint8, buf)
    else
        local i, f = modf(val)
        -- float number
        if (f ~= 0) then
            if size == 32 then
                p = cast(pfloat32, p)
            elseif size == 64 then
                p = cast(pfloat64, p)
            else
                error("float size other than 32 and 64")
            end
        else
            if size == 64 then
                p = cast(puint64, buf)
            elseif size == 32 then
                p = cast(puint32, buf)
            elseif size == 16 then
                p = cast(puint16, buf)
            elseif size == 8 then
                p = cast(puint8, buf)
            else
                error("unknown in size " .. size)
            end
        end
    end
    return p
end

-- default: optional
function _M.read_val(buf, field_type, size, off, default)
    if field_type == "void" then
        return "Void"
    end

    local p = get_pointer_from_type(buf, field_type)

    local val
    if size >= 8 then
        local n, s = get_bit_offset(size * off, size)
        val = p[n]
    else
        local n, s = get_bit_offset(size * off, 8)
        local mask = 2^size - 1
        mask = lshift(mask, s)
        val = rshift(band(mask, p[n]), s)
    end

    -- TODO int64/uint64 support
    if default then
        val = bxor(val, default)
    end

    if field_type == "bool" then
        if val and val ~= 0 then
            return true
        else
            return false
        end
    end

    if field_type == "int64" or field_type == "uint64" then
        return substr(tostring(val), 1, -4)
    else
        return tonumber(val)
    end
end

function _M.read_text(buf, header, T, offset, default)
    local res
    local data_off, size, num = _M.read_listp_buf(buf, header, T, 2)
    if data_off and num then
        res = ffistr(buf + (T.dataWordCount + offset + 1 + data_off) * 2, num - 1) -- dataWordCount + offset + pointerSize + data_off
    else
        res = default
    end
    return res
end

-- default: optional
function _M.write_val(buf, val, size, off, default)
    local p = get_pointer_from_val(buf, size, val)

    if type(val) == "boolean" then
        val = val and 1 or 0
    end

    if default then
        val = bxor(val, default)
    end

    if size >= 8 then
        local n, s = get_bit_offset(size * off, size)
        p[n] = val
    else
        local n, s = get_bit_offset(size * off, 8)
        p[n] = bor(p[n], lshift(val, s))
    end
    --print(string.format("n %d, s %d, %d\n", n, s, val))

end

function _M.get_data_off(T, offset, pos)
    return (pos - T.dataWordCount * 8 - offset * 8 - 8) / 8
end

function _M.read_composite_tag(buf)
    local p = ffi.cast("int32_t *", buf)
    local val = p[0]
    local sig = band(val, 0x03)
    if sig ~= 0 then
        error("corrupt data, expected struct signiture(composite list tag) 0 but have " .. sig)
    end

    local num = rshift(val, 2)   -- pointer offset (B) instead indicates the number of elements in the list
    val = p[1]
    local dt = band(val, 0xffff)
    local pt = rshift(val, 16)
    --p[1] = lshift(T.pointerCount, 16) + T.dataWordCount
    return num, dt, pt
end

function _M.write_composite_tag(buf, T, num)
    local p = ffi.cast("int32_t *", buf)
    p[0] = lshift(num, 2)   -- pointer offset (B) instead indicates the number of elements in the list
    p[1] = lshift(T.pointerCount, 16) + T.dataWordCount
end

function _M.write_structp(buf, T, data_off)
    local p = cast(pint32, buf)
    p[0] = lshift(data_off, 2)
    p[1] = lshift(T.pointerCount, 16) + T.dataWordCount
end

function _M.write_structp_buf(buf, T, TSub, offset, data_off)
    local p = cast(pint32, buf)
    local base = T.dataWordCount * 2 + offset * 2
    p[base] = lshift(data_off, 2)
    p[base + 1] = lshift(TSub.pointerCount, 16) + TSub.dataWordCount
end


function _M.get_enum_val(v, enum_schema, name)
    local r = enum_schema[v]
    if not r then
        print(name, "Unknown enum val: " .. v)
        --error("Unknown enum val:" .. v)
        return 0
    end
    return r
end

function _M.write_listp_buf(buf, T, offset, size_type, num, data_off)
    local p = cast(pint32, buf)
    local base = T.dataWordCount * 2 + offset * 2

    p[base] = lshift(data_off, 2) + 1
    p[base + 1] = lshift(num, 3) + size_type
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

function _M.read_list_data(p, size_type, elm_type, num)
    local t = new_tab(num, 0)

    local size = list_size_map[size_type]
    if not size then
        error("corrupt data, unknown size type: " .. size_type)
    end

    size = size * 8

    local p = get_pointer_from_type(p, elm_type)

    for i = 1, num do
        t[i] = p[i - 1]
    end

    return t
end

function read_list_pointer(buf)
    local p = buf
    local val = p[0]
    local offset = rshift(val, 2)

    val = p[1]
    local size_type = band(val, 0x07)
    local num = rshift(val, 3)

    return offset, size_type, num
end

function _M.read_listp_buf(buf, header, T, offset)
    local p = cast(pint32, buf)
    local base = T.dataWordCount * 2 + offset * 2

    local val = p[base]

    if p[base] == 0 and p[base + 1] == 0 then
        return
    end

    local sig = band(val, 0x03)
    if sig == 1 then
        --print("plain pointer")
        return read_list_pointer(p + base)
    elseif sig == 2 then
        --print("single far pointer")
        return read_far_pointer(p + base, header, read_list_pointer)
    else
        error("corrupt data, expected list signiture 1 or far pointer 2, but have " .. sig)
    end

end

function read_far_pointer(buf, header, parser)
    local p = buf

    local landing = rshift(band(p[0], 0x04), 2)

    assert(landing == 0, "double far pointer not supported yet")
    local offset = rshift(p[0], 3)
    local seg_id = tonumber(p[1])
    --print("landing, offset, seg_id:", landing, offset, seg_id)

    -- object pointer offset
    local op_offset = header.header_size
    for i=1, seg_id do
        op_offset = op_offset + header.seg_sizes[i]
    end
    op_offset = op_offset + offset  -- offset is in words
    --print("op_offset:", op_offset)
    local pp = header.base + op_offset * 2 -- header.base is uint32_t *

    local p_offset, r1, r2 = parser(pp)
    --print("p_offset:", p_offset)
    p_offset = p_offset + (pp - p) / 2 -- p and pp are uint32_t *

    return p_offset, r1, r2
end

function read_struct_pointer(p)
    local offset = rshift(p[0], 2)
    local data_word_count = band(p[1], 0xffff)
    local pointer_count = rshift(p[1], 16)

    return offset, data_word_count, pointer_count
end

function _M.read_struct_buf(buf, header)
    local p = buf
    if p[0] == 0 and p[1] == 0 then
        -- not set
        return
    end

    local sig = band(p[0], 0x03)

    if sig == 0 then
        return read_struct_pointer(p)
    elseif sig == 2 then
        return read_far_pointer(p, header, read_struct_pointer)
    else
        error("corrupt data, expected struct signiture 0 or far pointer 2, but have " .. sig)
    end
end

return _M
