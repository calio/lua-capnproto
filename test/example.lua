package.path = package.path .. ";test/?.lua;;"
local handwritten = require "handwritten"


for k, v in pairs(handwritten) do
    _G[k] = v
end

_G.hw_capnp = require "example_capnp"

if _VERSION >= 'Lua 5.2' then
    _ENV = lunit.module('simple','seeall')
else
    module( "simple", package.seeall, lunit.testcase )
end

