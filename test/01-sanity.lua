local ffi = require "ffi"
local lunit = require "lunitx"
local capnp = require "capnp"
local util = require "util"
local handwritten = require "handwritten_capnp"


local format = string.format


local T1 = handwritten.T1

if _VERSION >= 'Lua 5.2' then
    _ENV = lunit.module('simple','seeall')
else
    module( "simple", package.seeall, lunit.testcase )
end

function assert_equalf(expected, actual)
    if math.abs(expected - actual) < 0.000001 then
        assert_true(true)
        return
    end
    error(format("expected %s, got %s", expected, actual))
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

-----------------------------------------------------------------

function test_write_plain_val()
    local seg = { len = 32, pos = 0 }
    seg.data = ffi.new("char[?]", 32) -- 32 bytes

    capnp.write_struct_field(seg.data, true, "bool", 1, 0)
    capnp.write_struct_field(seg.data, 8, "uint8", 8, 1)
    capnp.write_struct_field(seg.data, 65535, "uint16", 16, 1)
    capnp.write_struct_field(seg.data, 1048576, "uint32", 32, 1)
    capnp.write_struct_field(seg.data, 4294967296, "uint64", 64, 1)
    capnp.write_struct_field(seg.data, 3.14, "float32", 32, 4)
    capnp.write_struct_field(seg.data, 1.41421, "float32", 32, 5)
    capnp.write_struct_field(seg.data, 3.14159265358979, "float64", 64, 3)

    seg.pos = seg.pos + 32
    assert_hex("01 08 ff ff 00 00 10 00 00 00 00 00 01 00 00 00 c3 f5 48 40 d5 04 b5 3f 11 2d 44 54 fb 21 09 40", seg)
end

function test_fix_float_default()
    assert_equal(0, capnp.fix_float32_default(3.14, 3.14))
    assert_equal(0, capnp.fix_float64_default(3.1415926, 3.1415926))
end

function test_write_plain_val_with_default()
    local seg = { len = 32, pos = 0 }
    seg.data = ffi.new("char[?]", 32) -- 32 bytes

    capnp.write_struct_field(seg.data, true, "bool", 1, 0, 1)
    capnp.write_struct_field(seg.data, 8, "uint8", 8, 1, 8)
    capnp.write_struct_field(seg.data, 65535, "uint16", 16, 1, 65535)
    capnp.write_struct_field(seg.data, 1048576, "uint32", 32, 1, 1048576)
    capnp.write_struct_field(seg.data, 4294967296, "uint64", 64, 1, 4294967296)
    capnp.write_struct_field(seg.data, 3.14, "float32", 32, 4, 3.14)
    capnp.write_struct_field(seg.data, 1.41421, "float32", 32, 5, 1.41421)
    capnp.write_struct_field(seg.data, 3.14159265358979, "float64", 64, 3, 3.14159265358979)

    seg.pos = seg.pos + 32
    assert_hex("00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00", seg)
end

function test_write_plain_val1()
    local seg = { len = 32, pos = 0 }
    seg.data = ffi.new("char[?]", 32) -- 32 bytes

    capnp.write_struct_field(seg.data, -1, "int8", 8, 0)

    seg.pos = seg.pos + 32
    assert_hex("ff 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00", seg)
end

function test_read_struct_field()
    local seg = { len = 32, pos = 0 }
    seg.data = ffi.new("char[?]", 32) -- 32 bytes

    -- write_struct_field(buf, val, size, off)
    capnp.write_struct_field(seg.data, true, "bool", 1, 0)
    capnp.write_struct_field(seg.data, 8, "uint8", 8, 1)
    capnp.write_struct_field(seg.data, 65535, "uint16", 16, 1)
    capnp.write_struct_field(seg.data, 1048576, "uint32", 32, 1)
    capnp.write_struct_field(seg.data, 4294967296, "uint64", 64, 1)
    capnp.write_struct_field(seg.data, 3.14, "float32", 32, 4)
    capnp.write_struct_field(seg.data, 1.41421, "float32", 32, 5)
    capnp.write_struct_field(seg.data, 3.14159265358979, "float64", 64, 3)

    assert_equal(true,          capnp.read_struct_field(seg.data, "bool", 1, 0))
    assert_equal(8,             capnp.read_struct_field(seg.data, "int8", 8, 1))
    assert_equal(65535,         capnp.read_struct_field(seg.data, "uint16", 16, 1))
    assert_equal(1048576,       capnp.read_struct_field(seg.data, "int32", 32, 1))
    -- TODO make this work
    -- assert_equal('4294967296',    capnp.read_struct_field(seg.data, "uint64", 64, 1))
    -- TODO make this work
    assert_equalf(3.14,          capnp.read_struct_field(seg.data, "float32", 32, 4))
    assert_equalf(1.41421,       capnp.read_struct_field(seg.data, "float32", 32, 5))
    assert_equal(3.14159265358979, capnp.read_struct_field(seg.data, "float64", 64, 3))
end

function test_read_struct_field_with_default()
    local seg = { len = 32, pos = 0 }
    seg.data = ffi.new("char[?]", 32) -- 32 bytes

    assert_equal(true,          capnp.read_struct_field(seg.data, "bool", 1, 0, 1))
    assert_equal(8,             capnp.read_struct_field(seg.data, "int8", 8, 1, 8))
    assert_equal(65535,         capnp.read_struct_field(seg.data, "uint16", 16, 1, 65535))
    assert_equal(1048576,       capnp.read_struct_field(seg.data, "int32", 32, 1, 1048576))
    assert_equal(3456789012,       capnp.read_struct_field(seg.data, "uint32", 32, 1, 3456789012))
    -- TODO 64 bit number support
    assert_equal(-123456789012345LL,    capnp.read_struct_field(seg.data, "int64", 64, 1, -123456789012345LL))
    assert_equal(345678901234567890ULL,    capnp.read_struct_field(seg.data, "uint64", 64, 1, 345678901234567890ULL))
    -- TODO make this work
    assert_equalf(3.14,          capnp.read_struct_field(seg.data, "float32", 32, 4, 3.14))
    assert_equalf(1.41421,       capnp.read_struct_field(seg.data, "float32", 32, 5, 1.41421))
    assert_equal(3.14159265358, capnp.read_struct_field(seg.data, "float64", 64, 3, 3.14159265358))
end

--[[
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

function test_write_listp()
    local seg = capnp.new_segment(8)

    -- write_listp = function (buf, size, num, data_off)
    capnp.write_listp(seg.data, 2, 1, 0)

    seg.pos = seg.pos + 8
    assert_hex("01 00 00 00 0a 00 00 00", seg)
end
]]


function test_read_struct_buf()
    local buf = util.new_buf({ 0x10, 0x00, 0x00, 0x00, 0x02, 0x00, 0x04, 0x00 })
    local off, dw, pw = capnp.read_struct_buf(buf)
    assert_equal(4, off)
    assert_equal(2, dw)
    assert_equal(4, pw)
end

function test_far_pointer_to_struct()
    local buf = util.new_buf({
        01, 00, 00, 00,     01, 00, 00, 00, -- 2 segs           seg1: 1 word
        02, 00, 00, 00,     00, 00, 00, 00, -- seg2: 4 word     padding
        0x0a, 00, 00, 00,   01, 00, 00, 00, -- far pointer      seg:1, offset:1
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, -- start of seg 2
        08, 00, 00, 00,     02, 00, 04, 00, -- struct pointer
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, -- start of seg 2
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, -- start of seg 2
    })
    local header = {
        base = buf,
        header_size = 2,
        seg_sizes = { 1, 2, },
    }

    local off, dw, pw = capnp.read_struct_buf(buf + 4, header)
    assert_equal(4, off)
    assert_equal(2, dw)
    assert_equal(4, pw)
end

function test_far_pointer_to_list()
    local buf = util.new_buf({
        01, 00, 00, 00,     01, 00, 00, 00, -- 2 segs           seg1: 1 word
        03, 00, 00, 00,     00, 00, 00, 00, -- seg2: 3 word     padding
        02, 00, 00, 00,     01, 00, 00, 00, -- far pointer      seg 1
        05, 00, 00, 00,     0x27, 00, 00, 00, -- list pointer
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        00, 00, 00, 00,     00, 00, 00, 00,
    })
    local header = {
        base = buf,
        header_size = 2,
        seg_sizes = { 1, 2, },
    }
    local T = {
        dataWordCount = 0
    }
    local off, size_type, num = capnp.read_listp_struct(buf + 4, header, T, 0)
    assert_equal(2, off)
    assert_equal(7, size_type)
    assert_equal(4, num)
end

function test_write_text()
    local buf = ffi.new("char[?]", 8 * 4)
    local p32 = ffi.cast("int32_t *", buf)
    capnp.write_text(p32, "12345678", 1)

    assert_equal("05 00 00 00 4a 00 00 00 00 00 00 00 00 00 00 00 31 32 33 34 35 36 37 38 00 00 00 00 00 00 00 00", util.hex_buf_str(buf, 32))
end

function test_write_list_data_num()
    local buf = ffi.new("char[?]", 8 * 2)
    local p32 = ffi.cast("int32_t *", buf)

    capnp.write_list_data(p32, { -1, -2, -3, -4, 0, 1, 2, 3 }, 0, "int8")
    assert_equal("ff fe fd fc 00 01 02 03 00 00 00 00 00 00 00 00", util.hex_buf_str(buf, 16))
end

function test_write_list_data_bool()
    local buf = ffi.new("char[?]", 8)
    local p32 = ffi.cast("int32_t *", buf)

    capnp.write_list_data(p32, { true, false, true }, 0, "bool")
    assert_equal("05 00 00 00 00 00 00 00", util.hex_buf_str(buf, 8))
end

function test_write_list_data_data()
    local buf = ffi.new("char[?]", 8 * 7)
    local p32 = ffi.cast("int32_t *", buf)

    capnp.write_list_data(p32, { "\1\2\3", "\4\5\6\7", "\9\10\11\12\13\14\15\16\17" }, 24, "data") -- writes 3 list pointer first, then list data
    assert_equal("09 00 00 00 1a 00 00 00 09 00 00 00 22 00 00 00 09 00 00 00 4a 00 00 00 01 02 03 00 00 00 00 00 04 05 06 07 00 00 00 00 09 0a 0b 0c 0d 0e 0f 10 11 00 00 00 00 00 00 00", util.hex_buf_str(buf, 56))
end

function test_write_list_data_text()
    local buf = ffi.new("char[?]", 8 * 7)
    local p32 = ffi.cast("int32_t *", buf)

    capnp.write_list_data(p32, { "ab", "def", "ijklmnop" }, 24, "text") -- writes 3 list pointer first, then list data
    assert_equal("09 00 00 00 1a 00 00 00 09 00 00 00 22 00 00 00 09 00 00 00 4a 00 00 00 61 62 00 00 00 00 00 00 64 65 66 00 00 00 00 00 69 6a 6b 6c 6d 6e 6f 70 00 00 00 00 00 00 00 00", util.hex_buf_str(buf, 56))
end

function test_write_list_data_list()
    local buf = ffi.new("char[?]", 8 * 9)
    local p32 = ffi.cast("int32_t *", buf)

    -- list of text
    capnp.write_list_data(p32, { {"ab", "def"}, {"ijklmnop"} }, 16, "list", "text") -- writes 3 list pointer first, then list data
    assert_equal("05 00 00 00 16 00 00 00 11 00 00 00 0e 00 00 00 05 00 00 00 1a 00 00 00 05 00 00 00 22 00 00 00 61 62 00 00 00 00 00 00 64 65 66 00 00 00 00 00 01 00 00 00 4a 00 00 00 69 6a 6b 6c 6d 6e 6f 70 00 00 00 00 00 00 00 00", util.hex_buf_str(buf, 72))
end
