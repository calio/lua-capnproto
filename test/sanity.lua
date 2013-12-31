
local lunit = require "lunitx"
local capnp = require "capnp"

if _VERSION >= 'Lua 5.2' then
    _ENV = lunit.module('simple','seeall')
else
    module( "simple", package.seeall, lunit.testcase )
end

local to_hex_string = function(seg)
    local t = {}
    for i = 1, seg.len do
        table.insert(t, bit.tohex(seg.data[i - 1], 2))
    end
    return table.concat(t, " ")
end

local assert_hex = function (expected, actual)
    assert_equal(expected, to_hex_string(actual))
end

local T1 = {
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
        s1 = { is_pointer = true }
    },
}

function test_new_segment()
    local seg = capnp.new_segment(8)
    assert_not_nil(seg)
    assert_equal(8, seg.len)
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

    assert_hex("01 08 ff ff 00 00 10 00 00 00 00 00 01 00 00 00 c3 f5 48 40 d5 04 b5 3f 11 2d 44 54 fb 21 09 40", seg)
end

function test_write_structp()
    local seg = capnp.new_segment(8) -- 32 bytes

    capnp.write_structp(seg.data, T1, 0)

    assert_hex("00 00 00 00 02 00 01 00", seg)
end

function test_write_structp1()
    local seg = capnp.new_segment(16) -- 32 bytes

    capnp.write_structp(seg.data + 8, T1, 2)

    assert_hex("00 00 00 00 00 00 00 00 08 00 00 00 02 00 01 00", seg)
end

function test_write_structp_seg()
    local seg = capnp.new_segment(16) -- 32 bytes
    seg.pos = 8 -- skip first 8 bytes

    capnp.write_structp_seg(seg, T1, 2)

    assert_hex("00 00 00 00 00 00 00 00 08 00 00 00 02 00 01 00", seg)
end

function test_init_root()
    local seg = capnp.new_segment(32) -- 32 bytes
    capnp.init_root(seg, T1)

    assert_hex("00 00 00 00 02 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00", seg)
end

function test_write_listp()
    local seg = capnp.new_segment(8)

    -- write_listp = function (buf, size, num, data_off)
    capnp.write_listp(seg.data, 2, 1, 0)

    assert_hex("01 00 00 00 0a 00 00 00", seg)
end

function test_write_list()
    local seg = capnp.new_segment(8)

    -- write_list = function (seg, size_type, num)
    local l = capnp.write_list(seg, 2, 8)

    assert_equal(2, l.size_type)
    assert_equal(1, l.actual_size)
    assert_equal(8, l.num)
end

function test_write_text()
    local seg = capnp.new_segment(16)

    -- write_text = function(seg, str)
    capnp.write_text(seg, "To err is human")
    assert_hex("54 6f 20 65 72 72 20 69 73 20 68 75 6d 61 6e 00", seg)
end

function test_write_data()
    local seg = capnp.new_segment(8)

    -- write_text = function(seg, str)
    capnp.write_text(seg, "\0\1\2\3\4\5\6\7")
    assert_hex("00 01 02 03 04 05 06 07", seg)
end

function test_list_newindex()
    local seg = capnp.new_segment(16)

    local num = 5
    local size_type =2
    capnp.write_listp(seg.data, size_type, num, 0) -- 2: 1 byte, 8: 8 items, 0: offset
    seg.pos = seg.pos + 8 -- 8: list pointer size
    local l = capnp.write_list(seg, size_type, num)

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
    local seg = capnp.new_segment(24)

    local s = capnp.init_root(seg, T1)
    local mt = {
        __newindex = capnp.struct_newindex
    }

    local struct = setmetatable(s, mt)
--[[
        i0 = { size = 32, offset = 0 },
        i1 = { size = 16, offset = 2 },
        i2 = { size = 8, offset = 7 },
        b0 = { size = 1, offset = 48 },
        b1 = { size = 1, offset = 49 },
        i3 = { size = 32, offset = 2 },
        ]]
    struct.i0 = 8
    struct.i1 = 7
    struct.b0 = true
    struct.b1 = false
    struct.i3 = 9

    assert_hex("00 00 00 00 02 00 01 00 08 00 00 00 07 00 01 00 09 00 00 00 00 00 00 00", seg)
end
