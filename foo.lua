local test_capnp = require "test_capnp"

local msg = test_capnp.init(test_capnp.T1)

local file = arg[1] or "c.data"
msg.i0 = 32
msg.i1 = 16
msg.b0 = true
msg.b1 = true
msg.i2 = 127
msg.i3 = 65536
msg.e0 = "enum3"

local s0 = msg:init_s0()
s0.f0 = 3.14
s0.f1 = 3.14159265358979

local l0 = msg:init_l0(2)
l0[1] = 28
l0[2] = 29

msg.t0 = "hello"

msg.e1 = "enum7"

local f = io.open(file, "w")
f:write(msg:serialize())
f:close()
