local ffi = require "ffi"
local capnp = require "capnp"
local bit = require "bit"

local ceil              = math.ceil
local write_val         = capnp.write_val
local read_val          = capnp.read_val
local get_enum_val      = capnp.get_enum_val
local get_data_off      = capnp.get_data_off
local write_listp_buf   = capnp.write_listp_buf
local write_structp_buf = capnp.write_structp_buf
local write_structp     = capnp.write_structp
local ffi_new           = ffi.new
local ffi_string        = ffi.string
local ffi_cast          = ffi.cast
local ffi_copy          = ffi.copy
local ffi_fill          = ffi.fill
local band, bor, bxor = bit.band, bit.bor, bit.bxor
local lshift, rshift, rol = bit.lshift, bit.rshift, bit.rol

local ok, new_tab = pcall(require, "table.new")

if not ok then
    new_tab = function (narr, nrec) return {} end
end

local round8 = function(size)
    return ceil(size / 8) * 8
end

local str_buf
local default_segment_size = 4096

local function get_str_buf(size)
    if size > default_segment_size then
        return ffi_new("char[?]", size)
    end

    if not str_buf then
        str_buf = ffi_new("char[?]", default_segment_size)
    end
    return str_buf
end

local _M = new_tab(2, 8)

_M.T1 = {
    id = 13624321058757364083,
    displayName = "proto/test.capnp:T1",
    dataWordCount = 2,
    pointerCount = 3,

    calc_size_struct = function(data)
        local size = 40 -- 5 words
        -- struct
        if data.s0 then
            size = size + _M.T1.T2.calc_size_struct(data.s0)
        end
        -- list
        if data.l0 then
            size = size + round8(#data.l0 * 1) -- num * acutal size
        end
        -- text
        if data.t0 then
            size = size + round8(#data.t0 + 1) -- size 1, including trailing NULL
        end
        return size
    end,

    calc_size = function(data)
        local size = 16 -- header + root struct pointer
        return size + _M.T1.calc_size_struct(data)
    end,

    flat_serialize = function(data, buf)
        local pos = 40 -- 5 words

        if data.i0 then
            write_val(buf, data.i0, 32, 0)
        end
        if data.i1 then
            write_val(buf, data.i1, 16, 2)
        end
        if data.b0 then
            write_val(buf, data.b0, 1, 48)
        end
        if data.i2 then
            write_val(buf, data.i2, 8, 7)
        end
        if data.b1 then
            write_val(buf, data.b1, 1, 49)
        end
        if data.i3 then
            write_val(buf, data.i3, 32, 2)
        end
        if data.s0 then
            local data_off = get_data_off(_M.T1, 0, pos)
            write_structp_buf(buf, _M.T1, _M.T1.T2, 0, data_off)
            local size = _M.T1.T2.flat_serialize(data.s0, buf + pos)
            pos = pos + size
        end
        if data.e0 then
            local val = get_enum_val(data.e0, _M.T1.EnumType1)
            write_val(buf, val, 16, 6)
        end
        if data.l0 then
            local data_off = get_data_off(_M.T1, 1, pos)

            local len = #data.l0
            write_listp_buf(buf, _M.T1, 1, 2, len, data_off)

            for i=1, len do
                write_val(buf + pos, data.l0[i], 8, i - 1) -- 8 bits
            end
            pos = pos + round8(len * 1) -- 1 ** actual size
        end
        if data.t0 then
            local data_off = get_data_off(_M.T1, 2, pos)

            local len = #data.t0 + 1
            write_listp_buf(buf, _M.T1, 2, 2, len, data_off)

            ffi_copy(buf + pos, data.t0)
            pos = pos + round8(len)
        end

        if data.e1 then
            local val = get_enum_val(data.e1, _M.EnumType2)
            write_val(buf, val, 16, 7)
        end
        return pos
    end,

    serialize = function(data, buf, size)
        if not buf then
            size = _M.T1.calc_size(data)

            buf = get_str_buf(size)
        end
        ffi_fill(buf, size)
        local p = ffi_cast("int32_t *", buf)

        p[0] = 0                                    -- 1 segment
        p[1] = (size - 8) / 8

        write_structp(buf + 8, _M.T1, 0)
        _M.T1.flat_serialize(data, buf + 16)

        return ffi_string(buf, size)
    end,

    parse_struct_data = function(buf, data_word_count, pointer_count)
        local s = new_tab(0, 8)
        s.i0 = read_val(buf, "uint32", 32, 0)
        s.i1 = read_val(buf, "uint16", 16, 2)
        s.b0 = read_val(buf, "bool", 1, 48)
        s.i2 = read_val(buf, "int8", 8, 7)
        s.b1 = read_val(buf, "bool", 1, 49)
        s.i3 = read_val(buf, "int32", 32, 2)
        -- dataWordCount + offset
        print(ffi.typeof(buf))
        s.s0 = _M.T1.T2.parse_struct(buf + (2 + 0) * 2)
        --[[
        s.e0
        s.l0
        s.t0
        s.e1
        ]]
        return s
    end,

    parse_struct = function(buf)
        local p = buf
        local sig = band(p[0], 0x03)

        if sig ~= 0 then
            error("corrupt data, expected struct signiture 0 but have " .. sig)
        end

        local offset = rshift(p[0], 2)
        local data_word_count = band(p[1], 0xffff)
        local pointer_count = rshift(p[1], 16)

        return _M.T1.parse_struct_data(p + 2 + offset * 2, data_word_count,
                pointer_count)
    end,

    parse = function(bin)
        if #bin < 16 then
            return nil, "message too short"
        end

        local p = ffi_cast("uint32_t *", bin)
        local nsegs = p[0] + 1
        local sizes = {}
        for i=1, nsegs do
            sizes[i] = p[i] * 8
        end

        local pos = round8(4 + nsegs * 4)

        p = p + pos/4

        return _M.T1.parse_struct(p)
    end
}

_M.T1.T2 = {
    id = 17202330444354522981,
    displayName = "proto/test.capnp:T1.T2",
    dataWordCount = 2,
    pointerCount = 0,

    calc_size_struct = function(data)
        local size = 16
        return size
    end,

    calc_size = function(data)
        local size = 16
        return size + _M.T1.T2.calc_size_struct(data)
    end,

    flat_serialize = function(data, buf)
        local pos = 16 -- 2 words

        if data.f0 then
            write_val(buf, data.f0, 32, 0)
        end
        if data.f1 then
            write_val(buf, data.f1, 64, 1)
        end
        return pos
    end,

    serialize = function(data, buf, size)
        if not buf then
            size = _M.T1.T2.calc_size(data)

            buf = get_str_buf(size)
        end
        ffi_fill(buf, size)
        local p = ffi_cast("int32_t *", buf)

        p[0] = 0                                    -- 1 segment
        p[1] = (size - 8) / 8

        write_structp(buf + 8, _M.T1.T2, 0)
        _M.T1.flat_serialize(data, buf + 16)

        return ffi_string(buf, size)
    end,

    parse_struct_data = function(buf, data_word_count, pointer_count)
        local s = new_tab(0, 2)
        s.f0 = read_val(buf, "float32", 32, 0)
        s.f1 = read_val(buf, "float64", 64, 1)
        return s
    end,

    parse_struct = function(buf)
        local p = buf
        local sig = band(p[0], 0x03)

        if sig ~= 0 then
            error("corrupt data, expected struct signiture 0 but have " .. sig)
        end

        local offset = rshift(p[0], 2)
        local data_word_count = band(p[1], 0xffff)
        local pointer_count = rshift(p[1], 16)

        return _M.T1.T2.parse_struct_data(p + 2 + offset * 2, data_word_count,
                pointer_count)
    end,


}

_M.T1.EnumType1 = {
    enum1 = 0,
    enum2 = 1,
    enum3 = 2,
}

_M.EnumType2 = {
    enum5 = 0,
    enum6 = 1,
    enum7 = 2,
}

return _M
