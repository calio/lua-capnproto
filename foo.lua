local test_capnp = require "handwritten_capnp"
local capnp = require "capnp"

local msg = test_capnp.init(test_capnp.T1)

local data = {
    i0 = 32,
    i1 = 16,
    bo = true,
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

local file = arg[1] or "c.data"
msg:set_i0(32)
msg:set_i1(16)
msg:set_b0(true)
msg:set_b1(true)
msg:set_i2(127)
msg:set_i3(65536)
msg:set_e0("enum3")

local s0 = msg:init_s0()
s0:set_f0(3.14)
s0:set_f1(3.14159265358979)

local l0 = msg:init_l0(2)
l0:set(1, 28)
l0:set(2, 29)

msg:set_t0("hello")

msg:set_e1("enum7")

local f = io.open(file, "w")
f:write(msg:serialize())
f:close()

local f = io.open("flat." .. file, "w")
f:write(capnp.flat_serialize(test_capnp.T1, data))
f:close()
