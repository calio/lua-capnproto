local test_capnp = require "test_capnp"

local msg = test_capnp.T1:new()

msg.i0 = 32
msg.i1 = 16
msg.b0 = true
msg.b1 = true
msg.i2 = 254
msg.i3 = 65536

local f = io.open("c.data", "w")
f:write(serialize(test_capnp.T1))
f:close()
