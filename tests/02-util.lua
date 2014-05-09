local util = require "capnp.util"
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
    assert_equal("request_uri", util.lower_underscore_naming("requestURI"))
    assert_equal("REQUEST_URI", util.upper_underscore_naming("requestURI"))
    assert_equal("REQUEST", util.upper_underscore_naming("request"))
    assert_equal("TEST_RES", util.upper_underscore_naming("testRes"))
    assert_equal("request_uri", util.lower_underscore_naming("requestURI"))
    assert_equal("VERSION-CONTROL", util.upper_dash_naming("versionControl"))
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

    assert_equal("(b0 = true, db0 = true)", util.to_text(val, T1))
end

function test_to_text1()
    local T1 = hw_capnp.T1
    local val = {
        b0 = false, -- default 0
        db0 = false, -- default 1
    }

    assert_equal("(b0 = false, db0 = false)", util.to_text(val, T1))
end

function test_get_field_type(field)
    local field = {
        name = "lt0",
        codeOrder = 22,
        discriminantValue = 65535,
        slot = {
          offset = 6,
          ["type"] = {
            list = {
              elementType = {text = "void"} }
          },
          defaultValue = {list = 'opaque pointer'},
          hadExplicitDefault = false
        },
        ordinal = {explicit = 25}
    }

    local typ = util.get_field_type(field)
    assert_equal(2, #typ)
    assert_equal("list", typ[1])
    assert_equal("text", typ[2])
end

function test_get_field_type1(field)
    local field = {
        name = "o0",
        codeOrder = 21,
        discriminantValue = 65535,
        slot = {
          offset = 5,
          ["type"] = {anyPointer = "void"},
          defaultValue = {
            anyPointer = 'opaque pointer' },
          hadExplicitDefault = false },
        ordinal = {explicit = 24}
    }

    local typ = util.get_field_type(field)
    assert_equal(1, #typ)
    assert_equal("anyPointer", typ[1])
end

function test_get_field_type2(field)
    local field = { name = "ls0",
        codeOrder = 17,
        discriminantValue = 65535,
        slot = {
          offset = 4,
          ["type"] = {
            list = {
              elementType = {
                struct = {
                  typeId = "17202330444354522981" }
              }
            }
          }
        }
    }
    local typ = util.get_field_type(field)
    assert_equal(3, #typ)
    assert_equal("list", typ[1])
    assert_equal("struct", typ[2])
    assert_equal("17202330444354522981", typ[3])
end
