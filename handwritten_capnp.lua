local ffi = require "ffi" local capnp = require "capnp" 

local ceil      = math.ceil
local floor     = math.floor

local ok, new_tab = pcall(require, "table.new")

if not ok then
    new_tab = function (narr, nrec) return {} end
end

local round8 = function(size)
    return ceil(size / 8) * 8
end

local _M = new_tab(2, 8)

_M.T1 = {
    id = 13624321058757364083,
    displayName = "proto/test.capnp:T1",
    dataWordCount = 2,
    pointerCount = 3,

    calc_size = function(data)
        local size = 16 -- header + root struct pointer
        if data.s0 then
            size = size + 16 -- 2 word
        end

        if data.l0 then
            size = size + round8(#data.l0 * 1) -- num * acutal size
        end

        if data.t0 then
            size = size + round8(#data.t0 + 1) -- size 1, including trailing NULL
        end
        return size + 40 -- 5 words
    end,

    flat_serialize = function(data, buf)
        local pos = 40 -- 5 words

        if data.i0 then
            capnp.write_val(buf, data.i0, 32, 0)
        end
        if data.i1 then
            capnp.write_val(buf, data.i1, 16, 2)
        end
        if data.b0 then
            capnp.write_val(buf, data.b0, 1, 48)
        end
        if data.i2 then
            capnp.write_val(buf, data.i2, 8, 7)
        end
        if data.b1 then
            capnp.write_val(buf, data.b1, 1, 49)
        end
        if data.i3 then
            capnp.write_val(buf, data.i3, 32, 2)
        end
        if data.e0 then
            local val = capnp.get_enum_val(data.e0, _M.T1.EnumType1)
            capnp.write_val(buf, val, 16, 6)
        end
        if data.e1 then
            local val = capnp.get_enum_val(data.e1, _M.EnumType2)
            capnp.write_val(buf, val, 16, 7)
        end
        if data.s0 then
            local data_off = capnp.get_data_off(_M.T1, 0, pos)
            capnp.write_structp_buf(buf, _M.T1.T2, 0, data_off)
            local size = _M.T1.T2.flat_serialize(data.s0, buf + pos)
            pos = pos + size
        end
        if data.l0 then
            local data_off = capnp.get_data_off(_M.T1, 1, pos)

            local len = #data.l0
            capnp.write_listp_buf(buf, _M.T1, 1, 2, len, data_off)

            for i=1, len do
                capnp.write_val(buf + pos, data.l0[i], 8, i - 1) -- 8 bits
            end
            pos = pos + round8(len * 1) -- 1 ** actual size
        end
        if data.t0 then
            local data_off = capnp.get_data_off(_M.T1, 2, pos)

            local len = #data.t0 + 1
            capnp.write_listp_buf(buf, _M.T1, 2, 2, len, data_off)

            ffi.copy(buf + pos, data.t0)
            pos = pos + round8(len)
        end

        return pos
    end,

    serialize = function(data, buf, size)
        if not buf then
            size = _M.T1.calc_size(data)

            buf = ffi.new("char[?]", size)
        end
        local p = ffi.cast("int32_t *", buf)

        p[0] = 0                                    -- 1 segment
        p[1] = (size - 8) / 8

        capnp.write_structp(buf + 8, _M.T1, 0)
        _M.T1.flat_serialize(data, buf + 16)

        return ffi.string(buf, size)
    end

}

_M.T1.T2 = {
    id = 17202330444354522981,
    displayName = "proto/test.capnp:T1.T2",
    dataWordCount = 2,
    pointerCount = 0,

    calc_size = function(data)
        local size = 16
        return size + 16
    end,

    flat_serialize = function(data, buf)
        local pos = 16 -- 2 words

        if data.f0 then
            capnp.write_val(buf, data.f0, 32, 0)
        end
        if data.f1 then
            capnp.write_val(buf, data.f1, 64, 1)
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
