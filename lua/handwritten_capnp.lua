-- require "luacov"
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
local parse_struct_buf  = capnp.parse_struct_buf
local parse_listp_buf   = capnp.parse_listp_buf
local parse_list_data   = capnp.parse_list_data
local ffi_new           = ffi.new
local ffi_string        = ffi.string
local ffi_cast          = ffi.cast
local ffi_copy          = ffi.copy
local ffi_fill          = ffi.fill

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
    displayName = "proto/example.capnp:T1",
    dataWordCount = 5,
    pointerCount = 5,
    discriminantCount = 3,
    discriminantOffset = 10,

    calc_size_struct = function(data)
        local size = 80
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
        -- data
        if data.d0 then
            size = size + round8(#data.d0)
        end
        -- composite list
        if data.ls0 then
            size = size + 8
            local num = #data.ls0
            for i=1, num do
                size = size + _M.T1.T2.calc_size_struct(data.ls0[i])
            end
        end

        return size
    end,

    calc_size = function(data)
        local size = 16 -- header + root struct pointer
        return size + _M.T1.calc_size_struct(data)
    end,

    flat_serialize = function(data, buf)
        local pos = 80
        local dscrm
        if data.i0 and (type(data.i0) == "number"
                or type(data.i0) == "boolean") then

            write_val(buf, data.i0, 32, 0)
        end
        if data.i1 and (type(data.i1) == "number"
                or type(data.i1) == "boolean") then

            write_val(buf, data.i1, 16, 2)
        end
        if data.b0 and (type(data.b0) == "number"
                or type(data.b0) == "boolean") then

            write_val(buf, data.b0, 1, 48)
        end
        if data.i2 and (type(data.i2) == "number"
                or type(data.i2) == "boolean") then

            write_val(buf, data.i2, 8, 7)
        end
        if data.b1 and (type(data.b1) == "number"
                or type(data.b1) == "boolean") then

            write_val(buf, data.b1, 1, 49)
        end
        if data.i3 and (type(data.i3) == "number"
                or type(data.i3) == "boolean") then

            write_val(buf, data.i3, 32, 2)
        end
        if data.s0 and type(data.s0) == "table" then
            local data_off = get_data_off(_M.T1, 0, pos)
            write_structp_buf(buf, _M.T1, _M.T1.T2, 0, data_off)
            local size = _M.T1.T2.flat_serialize(data.s0, buf + pos)
            pos = pos + size
        end
        if data.e0 and type(data.e0) == "string" then
            local val = get_enum_val(data.e0, _M.T1.EnumType1, "T1.e0")
            write_val(buf, val, 16, 6)
        end
        if data.l0 and type(data.l0) == "table" then
            local data_off = get_data_off(_M.T1, 1, pos)

            local len = #data.l0
            write_listp_buf(buf, _M.T1, 1, 2, len, data_off)

            for i=1, len do
                write_val(buf + pos, data.l0[i], 8, i - 1) -- 8 bits
            end
            pos = pos + round8(len * 1) -- 1 ** actual size
        end
        if data.t0 and type(data.t0) == "string" then
            local data_off = get_data_off(_M.T1, 2, pos)

            local len = #data.t0 + 1
            write_listp_buf(buf, _M.T1, 2, 2, len, data_off)

            ffi_copy(buf + pos, data.t0)
            pos = pos + round8(len)
        end
        if data.e1 and type(data.e1) == "string" then
            local val = get_enum_val(data.e1, _M.EnumType2, "T1.e1")
            write_val(buf, val, 16, 7)
        end
        if data.d0 and type(data.d0) == "string" then
            local data_off = get_data_off(_M.T1, 3, pos)

            local len = #data.d0
            write_listp_buf(buf, _M.T1, 3, 2, len, data_off)

            ffi_copy(buf + pos, data.d0)
            pos = pos + round8(len)
        end
        if data.ui0 then
            dscrm = 0
        end
        if data.ui0 and (type(data.ui0) == "number"
                or type(data.ui0) == "boolean") then

            write_val(buf, data.ui0, 32, 4)
        end
        if data.ui1 then
            dscrm = 1
        end
        if data.ui1 and (type(data.ui1) == "number"
                or type(data.ui1) == "boolean") then

            write_val(buf, data.ui1, 32, 4)
        end
        if data.uv0 then
            dscrm = 2
        end
        if data.g0 and type(data.g0) == "table" then
            -- groups are just namespaces, field offsets are set within parent
            -- structs
            _M.T1.g0.flat_serialize(data.g0, buf)
        end

        if data.u0 and type(data.u0) == "table" then
            -- groups are just namespaces, field offsets are set within parent
            -- structs
            _M.T1.u0.flat_serialize(data.u0, buf)
        end

        if data.ls0 then
            local num, size, old_pos = #data.ls0, 0, pos
            local data_off = get_data_off(_M.T1, 4, pos)

            -- write tag
            capnp.write_composite_tag(buf + pos, _M.T1.T2, num)
            pos = pos + 8 -- tag

            -- write data
            for i=1, num do
                pos = pos + _M.T1.T2.flat_serialize(data.ls0[i], buf + pos)
            end

            -- write list pointer
            write_listp_buf(buf, _M.T1, 4, 7, (pos - old_pos - 8) / 8, data_off) -- TODO get size later
        end

        if dscrm then
            _M.T1.which(buf, 10, dscrm) --buf, discriminantOffset, discriminantValue
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

    which = function(buf, offset, n)
        if n then
            -- set value
            write_val(buf, n, 16, offset)
        else
            -- get value
            return read_val(buf, "uint16", 16, offset)
        end
    end,

    parse_struct_data = function(buf, data_word_count, pointer_count, tab)
        local s = tab
        local dscrm = _M.T1.which(buf, 10) --buf, dscrmriminantOffset, dscrmriminantValue

        s.i0 = read_val(buf, "uint32", 32, 0)
        s.i1 = read_val(buf, "uint16", 16, 2)
        s.b0 = read_val(buf, "bool", 1, 48)
        s.i2 = read_val(buf, "int8", 8, 7)
        s.b1 = read_val(buf, "bool", 1, 49)
        s.i3 = read_val(buf, "int32", 32, 2)

        local p = buf + (5 + 0) * 2 -- buf, dataWordCount, offset
        local off, dw, pw = parse_struct_buf(p)
        if off and dw and pw then
            if not s.s0 then
                s.s0 = new_tab(0, 2)
            end
            _M.T1.T2.parse_struct_data(p + 2 + off * 2, dw, pw, s.s0)
        else
            s.s0 = nil
        end
        local val = read_val(buf, "uint16", 16, 6)
        s.e0 = get_enum_val(val, _M.T1.EnumType1Str)

        -- list
        local off, size, num = parse_listp_buf(buf, _M.T1, 1)
        if off and num then
            s.l0 = parse_list_data(buf + (5 + 1 + 1 + off) * 2, size, "int8", num) -- dataWordCount + offset + pointerSize + off
        else
            s.l0 = nil
        end

        local off, size, num = parse_listp_buf(buf, _M.T1, 2)
        if off and num then
            s.t0 = ffi.string(buf + (5 + 2 + 1 + off) * 2, num - 1) -- dataWordCount + offset + pointerSize + off
        else
            s.t0 = nil
        end
        local val = read_val(buf, "uint16", 16, 7)
        s.e1 = get_enum_val(val, _M.EnumType2Str)

        local off, size, num = parse_listp_buf(buf, _M.T1, 3)
        if off and num then
            s.d0 = ffi.string(buf + (5 + 3 + 1 + off) * 2, num) -- dataWordCount + offset + pointerSize + off
        else
            s.d0 = nil
        end

        if dscrm == 0 then
        s.ui0 = read_val(buf, "int32", 32, 4)

        else
            s.ui0 = nil
        end

        if dscrm == 1 then
        s.ui1 = read_val(buf, "int32", 32, 4)

        else
            s.ui1 = nil
        end

        if dscrm == 2 then
        s.uv0 = read_val(buf, "void", 0, 0)

        else
            s.uv0 = nil
        end

        if not s.g0 then
            s.g0 = new_tab(0, 4)
        end
        _M.T1.g0.parse_struct_data(buf, _M.T1.dataWordCount, _M.T1.pointerCount,
                s.g0)

        if not s.u0 then
            s.u0 = new_tab(0, 4)
        end
        _M.T1.u0.parse_struct_data(buf, _M.T1.dataWordCount, _M.T1.pointerCount,
                s.u0)

        -- composite list
        local off, size, words = parse_listp_buf(buf, _M.T1, 4)
        if off and words then
            local start = (5 + 4 + 1 + off) * 2-- dataWordCount + offset + pointerSize + off
            local num, dt, pt = capnp.read_composite_tag(buf + start)
            start = start + 2 -- 2 * 32bit
            if not s.ls0 then
                s.ls0 = new_tab(num, 0)
            end
            for i=1, num do
                if not s.ls0[i] then
                    s.ls0[i] = new_tab(0, 2)
                end
                _M.T1.T2.parse_struct_data(buf + start, dt, pt, s.ls0[i])
                start = start + (dt + pt) * 2
            end
        else
            s.ls0 = nil
        end
        return s
    end,

    parse = function(bin, tab)
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

        p = p + pos / 4

        if not tab then
            tab = new_tab(0, 8)
        end
        local off, dw, pw = parse_struct_buf(p)
        if off and dw and pw then
            return _M.T1.parse_struct_data(p + 2 + off * 2, dw, pw, tab)
        else
            return nil
        end
    end,
}

_M.T1.T2 = {
    id = 17202330444354522981,
    displayName = "proto/example.capnp:T1.T2",
    dataWordCount = 2,
    pointerCount = 0,

    calc_size_struct = function(data)
        local size = 16
        return size
    end,

    calc_size = function(data)
        local size = 16 -- header + root struct pointer
        return size + _M.T1.T2.calc_size_struct(data)
    end,

    flat_serialize = function(data, buf)
        local pos = 16
        if data.f0 and (type(data.f0) == "number"
                or type(data.f0) == "boolean") then

            write_val(buf, data.f0, 32, 0)
        end
        if data.f1 and (type(data.f1) == "number"
                or type(data.f1) == "boolean") then

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
        _M.T1.T2.flat_serialize(data, buf + 16)

        return ffi_string(buf, size)
    end,

    parse_struct_data = function(buf, data_word_count, pointer_count, tab)
        local s = tab
        s.f0 = read_val(buf, "float32", 32, 0)
        s.f1 = read_val(buf, "float64", 64, 1)
        return s
    end,

    parse = function(bin, tab)
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

        p = p + pos / 4

        if not tab then
            tab = new_tab(0, 8)
        end
        local off, dw, pw = parse_struct_buf(p)
        if off and dw and pw then
            return _M.T1.T2.parse_struct_data(p + 2 + off * 2, dw, pw, tab)
        else
            return nil
        end
    end,

}
_M.T1.EnumType1 = {
    ["enum1"] = 0,
    ["enum2"] = 1,
    ["enum3"] = 2,
}
_M.T1.EnumType1Str = {
    [0] = "enum1",
    [1] = "enum2",
    [2] = "enum3",
}

_M.T1.g0 = {
    id = 10312822589529145224,
    displayName = "proto/example.capnp:T1.g0",
    dataWordCount = 5,
    pointerCount = 5,
    isGroup = true,

    -- size is included in the parent struct, so no need to calculate size here
    flat_serialize = function(data, buf)
        local pos = 80
        local dscrm
        if data.ui2 and (type(data.ui2) == "number"
                or type(data.ui2) == "boolean") then

            write_val(buf, data.ui2, 32, 6)
        end
    end,

    parse_struct_data = function(buf, data_word_count, pointer_count, tab)
        local s = tab
        s.ui2 = read_val(buf, "uint32", 32, 6)
        return s
    end,
}
_M.T1.u0 = {
    id = 12188145960292142197,
    displayName = "proto/example.capnp:T1.u0",
    dataWordCount = 5,
    pointerCount = 5,
    discriminantCount = 3,
    discriminantOffset = 14,
    isGroup = true,

    flat_serialize = function(data, buf)
        local pos = 80
        local dscrm
        if data.ui3 then
            dscrm = 0
        end

        if data.ui3 and (type(data.ui3) == "number"
                or type(data.ui3) == "boolean") then

            write_val(buf, data.ui3, 16, 11)
        end
        if data.uv1 then
            dscrm = 1
        end

        if data.ug0 then
            dscrm = 2
        end

        if data.ug0 and type(data.ug0) == "table" then
            -- groups are just namespaces, field offsets are set within parent
            -- structs
            _M.T1.u0.ug0.flat_serialize(data.ug0, buf)
        end

        if dscrm then
            _M.T1.u0.which(buf, 14, dscrm) --buf, discriminantOffset, discriminantValue
        end
        return pos
    end,
    which = function(buf, offset, n)
        if n then
            -- set value
            write_val(buf, n, 16, offset)
        else
            -- get value
            return read_val(buf, "uint16", 16, offset)
        end
    end,

    parse_struct_data = function(buf, data_word_count, pointer_count, tab)
        local s = tab

        local dscrm = _M.T1.u0.which(buf, 14) --buf, dscrmriminantOffset, dscrmriminantValue


        if dscrm == 0 then
        s.ui3 = read_val(buf, "uint16", 16, 11)

        else
            s.ui3 = nil
        end

        if dscrm == 1 then
        s.uv1 = read_val(buf, "void", 0, 0)

        else
            s.uv1 = nil
        end

        if dscrm == 2 then

        if not s.ug0 then
            s.ug0 = new_tab(0, 4)
        end
        _M.T1.u0.ug0.parse_struct_data(buf, _M.T1.u0.dataWordCount, _M.T1.u0.pointerCount,
                s.ug0)

        else
            s.ug0 = nil
        end

        return s
    end,
}
_M.T1.u0.ug0 = {
    id = 17270536655881866717,
    displayName = "proto/example.capnp:T1.u0.ug0",
    dataWordCount = 5,
    pointerCount = 5,
    isGroup = true,

    flat_serialize = function(data, buf)
        local pos = 80
        local dscrm
        if data.ugu0 and (type(data.ugu0) == "number"
                or type(data.ugu0) == "boolean") then

            write_val(buf, data.ugu0, 32, 8)
        end
        return pos
    end,
    parse_struct_data = function(buf, data_word_count, pointer_count, tab)
        local s = tab
        s.ugv0 = read_val(buf, "void", 0, 0)
        s.ugu0 = read_val(buf, "uint32", 32, 8)

        return s
    end,
}


_M.EnumType2 = {
    ["enum5"] = 0,
    ["enum6"] = 1,
    ["enum7"] = 2,
}


_M.EnumType2Str = {
    [0] = "enum5",
    [1] = "enum6",
    [2] = "enum7",
}

return _M
