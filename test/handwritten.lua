local ffi = require "ffi"
local lunit = require "lunitx"
local capnp = require "capnp"
local util = require "util"
local hw_capnp = require "handwritten_capnp"
--local format = string.format

local tdiff = util.table_diff


if _VERSION >= 'Lua 5.2' then
    _ENV = lunit.module('simple','seeall')
else
    module( "simple", package.seeall, lunit.testcase )
end

local copy = {}

function test_basic_value()
    local data = {
        i0 = 32,
    }

    local bin   = hw_capnp.T1.serialize(data)
    copy  = hw_capnp.T1.parse(bin, copy)
    assert_equal(data.i0, copy.i0)
    assert_equal(0, copy.i1)
    assert_equal(0, copy.i2)
    assert_equal(false, copy.b0)
    assert_equal(false, copy.b1)
    assert_equal(0, copy.i3)
    assert_equal("enum1", copy.e0)
    assert_equal("enum5", copy.e1)
    assert_nil(copy.s0)
    assert_nil(copy.l0)
    assert_nil(copy.t0)
end

function test_basic_value1()
    local data = {
        b0 = true,
    }

    local bin   = hw_capnp.T1.serialize(data)
    copy  = hw_capnp.T1.parse(bin, copy)
    assert_equal(0, copy.i0)
    assert_equal(0, copy.i1)
    assert_equal(0, copy.i2)
    assert_equal(true, copy.b0)
    assert_equal(false, copy.b1)
    assert_equal(0, copy.i3)
    assert_equal("enum1", copy.e0)
    assert_equal("enum5", copy.e1)
    assert_nil(copy.s0)
    assert_nil(copy.l0)
    assert_nil(copy.t0)
end

function test_basic_value2()
    local data = {
        i2 = -8,
    }

    local bin   = hw_capnp.T1.serialize(data)
    copy  = hw_capnp.T1.parse(bin, copy)
    assert_equal(0, copy.i0)
    assert_equal(0, copy.i1)
    assert_equal(-8, copy.i2)
    assert_equal(false, copy.b0)
    assert_equal(false, copy.b1)
    assert_equal(0, copy.i3)
    assert_equal("enum1", copy.e0)
    assert_equal("enum5", copy.e1)
    assert_nil(copy.s0)
    assert_nil(copy.l0)
    assert_nil(copy.t0)
end

function test_basic_value3()
    local data = {
        s0 = {},
    }

    local bin   = hw_capnp.T1.serialize(data)
    copy  = hw_capnp.T1.parse(bin, copy)
    assert_equal(0, copy.i0)
    assert_equal(0, copy.i1)
    assert_equal(0, copy.i2)
    assert_equal(false, copy.b0)
    assert_equal(false, copy.b1)
    assert_equal(0, copy.i3)
    assert_equal("enum1", copy.e0)
    assert_equal("enum5", copy.e1)
    assert_not_nil(copy.s0)
    assert_equal(0, copy.s0.f0)
    assert_equal(0, copy.s0.f1)
    assert_nil(copy.l0)
    assert_nil(copy.t0)
end

function test_basic_value4()
    local data = {
        s0 = {
            f0 = 3.14,
            f1 = 3.1415926535
        },
    }

    local bin   = hw_capnp.T1.serialize(data)
    copy  = hw_capnp.T1.parse(bin, copy)
    assert_equal(0, copy.i0)
    assert_equal(0, copy.i1)
    assert_equal(0, copy.i2)
    assert_equal(false, copy.b0)
    assert_equal(false, copy.b1)
    assert_equal(0, copy.i3)
    assert_equal("enum1", copy.e0)
    assert_equal("enum5", copy.e1)
    assert_not_nil(copy.s0)
    -- assert_equal(3.1400001049042, copy.s0.f0)
    assert_equal(3.1415926535, copy.s0.f1)
    assert_nil(copy.l0)
    assert_nil(copy.t0)
end

function test_basic_value4()
    local data = {
        l0 = { 1, -1, 127 }
    }

    local bin   = hw_capnp.T1.serialize(data)
    copy  = hw_capnp.T1.parse(bin, copy)
    assert_equal(0, copy.i0)
    assert_equal(0, copy.i1)
    assert_equal(0, copy.i2)
    assert_equal(false, copy.b0)
    assert_equal(false, copy.b1)
    assert_equal(0, copy.i3)
    assert_equal("enum1", copy.e0)
    assert_equal("enum5", copy.e1)
    assert_nil(copy.s0)
    assert_equal(3, #copy.l0)
    assert_equal(1, copy.l0[1])
    assert_equal(-1, copy.l0[2])
    assert_equal(127, copy.l0[3])
    assert_nil(copy.t0)
end

function test_basic_value5()
    local data = {
        t0 = "1234567890~!#$%^&*()-=_+[]{};':|,.<>/?"
    }

    local bin   = hw_capnp.T1.serialize(data)
    copy  = hw_capnp.T1.parse(bin, copy)
    assert_equal(0, copy.i0)
    assert_equal(0, copy.i1)
    assert_equal(0, copy.i2)
    assert_equal(false, copy.b0)
    assert_equal(false, copy.b1)
    assert_equal(0, copy.i3)
    assert_equal("enum1", copy.e0)
    assert_equal("enum5", copy.e1)
    assert_nil(copy.s0)
    assert_nil(copy.l0)
    assert_equal(38, #copy.t0)
    assert_equal("1234567890~!#$%^&*()-=_+[]{};':|,.<>/?", copy.t0)
end
