local util = require "util"
local lunit = require "lunitx"
local hw_capnp = require "handwritten_capnp"

if _VERSION >= 'Lua 5.2' then
    _ENV = lunit.module('simple','seeall')
else
    module( "simple", package.seeall, lunit.testcase )
end

function test_underscore_naming()
    assert_equal("request_uri", util.lower_underscore_naming("requestURI"))
    assert_equal("REQUEST_URI", util.upper_underscore_naming("requestURI"))
    assert_equal("REQUEST", util.upper_underscore_naming("request"))
    assert_equal("TEST_RES", util.upper_underscore_naming("testRes"))
end

function test_hex_utils()
    local buf = util.new_buf({ 01, 02, 03, 04, 10, 11, 12, 13 })
    assert_equal("01 02 03 04 0a 0b 0c 0d", util.hex_buf_str(buf, 8))
end


function test_to_text()
    local T1 = hw_capnp.T1
    local val = {
        b0 = true, -- default 0
        db0 = true, -- default 1
    }

    assert_equal("(b0 = 1)", util.to_text(val, T1))
end

function test_to_text1()
    local T1 = hw_capnp.T1
    local val = {
        b0 = false, -- default 0
        db0 = false, -- default 1
    }

    assert_equal("(db0 = 0)", util.to_text(val, T1))
end
