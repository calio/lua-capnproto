local ffi = require "ffi"
local capnp = require "capnp" 

local ceil              = math.ceil
local write_val         = capnp.write_val
local get_enum_val      = capnp.get_enum_val
local get_data_off      = capnp.get_data_off
local write_listp_buf   = capnp.write_listp_buf
local write_structp_buf = capnp.write_structp_buf
local write_structp     = capnp.write_structp

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
        return ffi.new("char[?]", size)
    end

    if not str_buf then
        str_buf = ffi.new("char[?]", default_segment_size)
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

            ffi.copy(buf + pos, data.t0)
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
        local p = ffi.cast("int32_t *", buf)

        p[0] = 0                                    -- 1 segment
        p[1] = (size - 8) / 8

        write_structp(buf + 8, _M.T1, 0)
        _M.T1.flat_serialize(data, buf + 16)

        return ffi.string(buf, size)
    end,

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
    end
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
