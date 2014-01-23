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

function test_basic_value6()
    local data = {
        i0 = 32,
        i1 = 16,
        i2 = 127,
        b0 = true,
        b1 = true,
        i3 = 65536,
        e0 = "enum3",
        s0 = {
            f0 = 3.14,
            f1 = 3.14159265358979,
        },
        l0 = { 28, 29 },
        t0 = "hello",
        e1 = "enum7",
    }

    local bin   = hw_capnp.T1.serialize(data)
    copy  = hw_capnp.T1.parse(bin, copy)
    assert_equal(32, copy.i0)
    assert_equal(16, copy.i1)
    assert_equal(127, copy.i2)
    assert_equal(true, copy.b0)
    assert_equal(true, copy.b1)
    assert_equal(65536, copy.i3)
    assert_equal("enum3", copy.e0)
    assert_equal("enum7", copy.e1)
    assert_not_nil(copy.s0)
    -- assert_equal(3.14, copy.s0.f0)
    assert_equal(3.14159265358979, copy.s0.f1)
    assert_not_nil(copy.l0)
    assert_equal(2, #copy.l0)
    assert_equal(28, copy.l0[1])
    assert_equal(29, copy.l0[2])
    assert_equal(5, #copy.t0)
    assert_equal("hello", copy.t0)
end

function test_union_value()
    local data = {
        ui1 = 32,
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
    assert_nil(copy.t0)
    assert_equal(data.ui1, copy.ui1)
    assert_nil(copy.ui0)
    assert_nil(copy.uv0)
end

function test_union_value()
    local data = {
        uv0 = "Void",
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
    assert_nil(copy.t0)
    assert_nil(copy.ui1)
    assert_nil(copy.ui0)
    assert_equal(data.uv0, copy.uv0)
end

function test_union_value()
    local data = {
        g0 = {
            ui2 = 48,
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
    assert_nil(copy.s0)
    assert_nil(copy.l0)
    assert_nil(copy.t0)
    assert_equal(0, copy.ui0) -- ui0 is set by default
    assert_nil(copy.ui1)
    assert_nil(copy.uv0)
    assert_equal(data.g0.ui2, copy.g0.ui2)
end

function test_union_group()
    local data = {
        u0 = {
            ui3 = 48,
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
    assert_nil(copy.s0)
    assert_nil(copy.l0)
    assert_nil(copy.t0)
    assert_equal(0, copy.ui0) -- ui0 is set by default
    assert_nil(copy.ui1)
    assert_nil(copy.uv0)
    assert_equal(0, copy.g0.ui2)
    assert_equal(data.u0.ui3, copy.u0.ui3)
    assert_nil(copy.u0.uv1)
    assert_nil(copy.u0.ug0)
    assert_nil(copy.ls0)
end

function test_union_group1()
    local data = {
        u0 = {
            uv1 = "Void",
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
    assert_nil(copy.s0)
    assert_nil(copy.l0)
    assert_nil(copy.t0)
    assert_equal(0, copy.ui0) -- ui0 is set by default
    assert_nil(copy.ui1)
    assert_nil(copy.uv0)
    assert_equal(0, copy.g0.ui2)
    assert_nil(copy.u0.ui3)
    assert_equal("Void", copy.u0.uv1)
    assert_nil(copy.u0.ug0)
    assert_nil(copy.ls0)
end

function test_union_group2()
    local data = {
        u0 = {
            ug0 = {
                ugv0 = "Void",
            },
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
    assert_nil(copy.s0)
    assert_nil(copy.l0)
    assert_nil(copy.t0)
    assert_equal(0, copy.ui0) -- ui0 is set by default
    assert_nil(copy.ui1)
    assert_nil(copy.uv0)
    assert_equal(0, copy.g0.ui2)
    assert_nil(copy.u0.ui3)
    assert_nil(copy.u0.uv1)
    assert_equal("Void", copy.u0.ug0.ugv0)
    assert_equal(0, copy.u0.ug0.ugu0)
    assert_nil(copy.ls0)
end
