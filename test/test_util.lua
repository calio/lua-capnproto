local util = require "util"
local lunit = require "lunitx"

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
