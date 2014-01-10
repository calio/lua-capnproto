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
local byte      = string.byte
local type      = type
local modf      = math.modf

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

function _M.write_val(buf, val, size, off)
    local p = ffi.cast("uint32_t *", buf)

    if type(val) == "boolean" then
        val = val and 1 or 0
        p = ffi.cast("uint8_t *", buf)
    else
        local i, f = modf(val)
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
                p = ffi.cast("uint64_t *", buf)
            elseif size == 32 then
                p = ffi.cast("uint32_t *", buf)
            elseif size == 16 then
                p = ffi.cast("uint16_t *", buf)
            elseif size == 8 then
                p = ffi.cast("uint8_t *", buf)
            else
                error("unknown in size " .. size)
            end
        end
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

function _M.write_structp(buf, T, data_off)
    local p = ffi.cast("int32_t *", buf)
    p[0] = lshift(data_off, 2)
    p[1] = lshift(T.pointerCount, 16) + T.dataWordCount
end

function _M.write_structp_buf(buf, T, TSub, offset, data_off)
    local p = ffi.cast("int32_t *", buf)
    local base = T.dataWordCount * 2 + offset * 2
    p[base] = lshift(data_off, 2)
    p[base + 1] = lshift(TSub.pointerCount, 16) + TSub.dataWordCount
end


function _M.get_enum_val(v, enum_schema, name)
    local r = enum_schema[v]
    if not r then
        print("Unknown enum val: " .. v)
        --error("Unknown enum val:" .. v)
        return 0
    end
    return r
end

function _M.write_listp_buf(buf, T, offset, size_type, num, data_off)
    local p = ffi.cast("int32_t *", buf)
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

return _M
