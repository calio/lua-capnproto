--local test_capnp = require "handwritten_capnp"
package.path = "lua/?.lua;proto/?.lua;" .. package.path

local data_generator = require "data_generator"
local test_capnp = require "example_capnp"
local capnp = require "capnp"
local cjson = require "cjson"

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

local file = arg[1]
local f = io.open(file, "w")
f:write(test_capnp.T1.serialize(data))
f:close()


local generated_data = data_generator.gen_t1()
local f = io.open("random.data", "w")
f:write(test_capnp.T1.serialize(generated_data))
f:close()
local f = io.open("random.cjson.data", "w")
f:write(cjson.encode(generated_data))
f:close()

