
local lunit = require "lunitx"
local capnp = require "capnp"
local handwritten = require "handwritten_capnp"

local T1 = handwritten.T1

if _VERSION >= 'Lua 5.2' then
    _ENV = lunit.module('simple','seeall')
else
    module( "simple", package.seeall, lunit.testcase )
end

local to_hex_string = function(seg)
    local t = {}
    for i = 1, seg.pos do
        table.insert(t, bit.tohex(seg.data[i - 1], 2))
    end
    return table.concat(t, " ")
end

local assert_hex = function (expected, actual)
    assert_equal(expected, to_hex_string(actual))
end

local function assert_hex_string(expected, actual)
    local t = {}
    for i = 1, #actual do
        table.insert(t, bit.tohex(string.byte(actual, i), 2))
    end
    assert_equal(expected, table.concat(t, " "))
end

--[[
local T1 = {
    T2 = {
        id = 17202330444354522981,
        displayName = "proto/test.capnp:T1.T2",
        dataWordCount = 2,
        pointerCount = 0,
        size = 16,
        fields = {
            f0 = { size = 32, offset = 0 },
            f1 = { size = 64, offset = 1 },
        },
    },

    id = 13624321058757364083,
    displayName = "test.capnp:T1",
    dataWordCount = 2,
    pointerCount = 1,
    size = 24,
    fields = {
        i0 = { size = 32, offset = 0 },
        i1 = { size = 16, offset = 2 },
        i2 = { size = 8, offset = 7 },
        b0 = { size = 1, offset = 48 },
        b1 = { size = 1, offset = 49 },
        i3 = { size = 32, offset = 2 },
        s0 = { size = 8, offset = 0, is_pointer = true, is_struct = true }
    },
}
T1.fields.s0.struct_schema = T1.T2
]]

function test_new_segment()
    local seg = capnp.new_segment()
    assert_not_nil(seg)
    assert_equal(4096, seg.len)
    assert_equal(0, seg.pos)
end

function test_write_plain_val()
    local seg = capnp.new_segment(32) -- 32 bytes

    -- write_val(buf, val, size, off)
    capnp.write_val(seg.data, true, 1, 0)
    capnp.write_val(seg.data, 8, 8, 1)
    capnp.write_val(seg.data, 65535, 16, 1)
    capnp.write_val(seg.data, 1048576, 32, 1)
    capnp.write_val(seg.data, 4294967296, 64, 1)
    capnp.write_val(seg.data, 3.14, 32, 4)
    capnp.write_val(seg.data, 1.41421, 32, 5)
    capnp.write_val(seg.data, 3.14159265358979, 64, 3)

    seg.pos = seg.pos + 32
    assert_hex("01 08 ff ff 00 00 10 00 00 00 00 00 01 00 00 00 c3 f5 48 40 d5 04 b5 3f 11 2d 44 54 fb 21 09 40", seg)
end

function test_write_structp()
    local seg = capnp.new_segment() -- 32 bytes

    capnp.write_structp(seg.data, T1, 0)

    seg.pos = seg.pos + 8
    assert_hex("00 00 00 00 02 00 03 00", seg)
end

function test_write_structp1()
    local seg = capnp.new_segment()

    capnp.write_structp(seg.data + 8, T1, 2)
    seg.pos = seg.pos + 16

    assert_hex("00 00 00 00 00 00 00 00 08 00 00 00 02 00 03 00", seg)
end

function test_write_structp_seg()
    local seg = capnp.new_segment(16) -- 32 bytes
    seg.pos = 8 -- skip first 8 bytes

    capnp.write_structp_seg(seg, T1, 2)

    assert_hex("00 00 00 00 00 00 00 00 08 00 00 00 02 00 03 00", seg)
end

function test_write_struct()
    local seg = capnp.new_segment() -- 32 bytes

    seg.pos = seg.pos + 8
    capnp.write_struct(seg.data, seg, T1)

    assert_hex("00 00 00 00 02 00 03 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00", seg)
end

function test_write_listp()
    local seg = capnp.new_segment(8)

    -- write_listp = function (buf, size, num, data_off)
    capnp.write_listp(seg.data, 2, 1, 0)

    seg.pos = seg.pos + 8
    assert_hex("01 00 00 00 0a 00 00 00", seg)
end

function test_write_listd()
    local seg = capnp.new_segment()

    -- write_list = function (seg, size_type, num)
    local l = capnp.write_listd(seg, 2, 8)

    assert_equal(2, l.size_type)
    assert_equal(1, l.actual_size)
    assert_equal(8, l.num)
end

function test_write_text()
    local seg = capnp.new_segment()

    -- write_text = function(seg, str)
    capnp.write_text(seg, "To err is human")
    assert_hex("54 6f 20 65 72 72 20 69 73 20 68 75 6d 61 6e 00", seg)
end

function test_write_data()
    local seg = capnp.new_segment()

    -- write_text = function(seg, str)
    capnp.write_text(seg, "\0\1\2\3\4\5\6")
    assert_hex("00 01 02 03 04 05 06 00", seg)
end

function test_list_newindex()
    local seg = capnp.new_segment()

    local num = 5
    local size_type =2
    capnp.write_listp(seg.data, size_type, num, 0) -- 2: 1 byte, 8: 8 items, 0: offset
    seg.pos = seg.pos + 8 -- 8: list pointer size
    local l = capnp.write_listd(seg, size_type, num)

    local mt = {
        __newindex =  capnp.list_newindex
    }
    local list = setmetatable(l, mt)

    list[1] = 1
    list[2] = 2
    list[3] = 3
    list[4] = 4
    list[5] = 5

    assert_hex("01 00 00 00 2a 00 00 00 01 02 03 04 05 00 00 00", seg)
end

function test_struct_newindex()
    local seg = capnp.new_segment()

    -- allocate a word for struct pointer
    seg.pos = seg.pos + 8
    local s = capnp.write_struct(seg.data, seg, T1)
    local mt = {
        __newindex = capnp.struct_newindex
    }

    local struct = setmetatable(s, mt)

    struct.i0 = 8
    struct.i1 = 7
    struct.b0 = true
    struct.b1 = false
    struct.i3 = 9

    assert_hex("00 00 00 00 02 00 03 00 08 00 00 00 07 00 01 00 09 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00", seg)
end

function test_calc_size()
    local data = {
        i0 = 1,
    }

    assert_equal(56, capnp.calc_size(T1, data))
end

function test_calc_size1()
    local data = {
        i0 = 1,
        s0 = {
            f0 = 3.14
        },
    }

    assert_equal(72, capnp.calc_size(T1, data))
end

function test_calc_size2()
    local data = {
        i0 = 1,
        s0 = {
            f0 = 3.14
        },
        t0 = "1234567",
    }

    assert_equal(80, capnp.calc_size(T1, data))

    data.t0 = "12345678"

    assert_equal(88, capnp.calc_size(T1, data))

end

function test_flat_serialize()
    local data = {
        i0 = 1,
        i1 = 1,
        i2 = 1,
        b0 = true,
        b1 = false,
        i3 = 1,
    }

    local bin = capnp.flat_serialize(T1, data)
    assert_equal(56, #bin)
    assert_hex_string("00 00 00 00 06 00 00 00 00 00 00 00 02 00 03 00 01 00 00 00 01 00 01 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00", bin)
end

function test_flat_serialize1()
    local data = {
        i0 = 1,
        i1 = 1,
        i2 = 1,
        b0 = true,
        b1 = false,
        i3 = 1,
        e0 = "enum3",
        e1 = "enum7",
    }

    local bin = capnp.flat_serialize(T1, data)
    assert_equal(56, #bin)
    assert_hex_string("00 00 00 00 06 00 00 00 00 00 00 00 02 00 03 00 01 00 00 00 01 00 01 01 01 00 00 00 02 00 02 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00", bin)
end

function test_flat_serialize2()
    local data = {
        i0 = 1,
        i1 = 1,
        i2 = 1,
        b0 = true,
        b1 = false,
        i3 = 1,
        e0 = "enum3",
        s0 = {
            f0 = 3.14,
            f1 = 3.14159265358979,
        },
        e1 = "enum7",
    }

    local bin = capnp.flat_serialize(T1, data)
    assert_equal(72, #bin)
    assert_hex_string("00 00 00 00 08 00 00 00 00 00 00 00 02 00 03 00 01 00 00 00 01 00 01 01 01 00 00 00 02 00 02 00 08 00 00 00 02 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 c3 f5 48 40 00 00 00 00 11 2d 44 54 fb 21 09 40", bin)
end
