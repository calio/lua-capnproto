
local lunit = require "lunitx"
local capnp = require "capnp"

if _VERSION >= 'Lua 5.2' then
    _ENV = lunit.module('simple','seeall')
else
    module( "simple", package.seeall, lunit.testcase )
end

function test_new_segment()
    local seg = capnp.new_segment(8)
    assert_not_nil(seg)
    assert_equal(8, seg.len)
    assert_equal(0, seg.pos)
end

function to_hex_string(seg)
    local t = {}
    for i = 1, seg.len do
        table.insert(t, bit.tohex(seg.data[i - 1], 2))
    end
    return table.concat(t, " ")
end

function assert_hex(expected, actual)
    assert_equal(expected, to_hex_string(actual))
end


function test_write_plain_val()
    -- |0|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|
    -- |0|1|           |   32                   |
    local seg = capnp.new_segment(16)

    -- write_val(buf, val, size, off)
    capnp.write_val(seg.data, true, 1, 0)
    capnp.write_val(seg.data, 8, 8, 1)
    capnp.write_val(seg.data, 65535, 16, 1)
    capnp.write_val(seg.data, 1048576, 32, 1)
    capnp.write_val(seg.data, 4294967296, 64, 1)
    capnp.write_val(seg.data, 3.14, 32, 5)
    capnp.write_val(seg.data, 1.41421, 32, 6)
    capnp.write_val(seg.data, 3.14159265358979, 64, 4)

    assert_hex("01 00 08 00 c3 f5 48 40 03 00 00 00 00 00 00 00", seg)
end
