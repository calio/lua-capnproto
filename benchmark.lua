jit.opt.start("loopunroll=1000")
local test_capnp    = require "handwrite_capnp"

local times         = arg[1] or 200000 * 10000


    local msg = test_capnp.init(test_capnp.T1)
    local s0 = msg:init_s0()
    local l0 = msg:init_l0(2)
function run1()

    msg:reset()
    msg:set_i0(32)
    msg:set_i1(16)
    msg:set_b0(true)
    msg:set_b1(true)
    msg:set_i2(127)
    msg:set_i3(65536)
    msg:set_e0("enum3")

    s0:set_f0(3.14)
    s0:set_f1(3.14159265358979)

    msg:set_t0("hello")
    msg:set_e1("enum7")

    return msg:serialize()
end

function run()
    local msg = test_capnp.init(test_capnp.T1)
    local s0 = msg:init_s0()
    local l0 = msg:init_l0(2)

    msg.i0 = 32

    msg.i1 = 16
    msg.b0 = true
    msg.b1 = true
    msg.i2 = 127
    msg.i3 = 65536
    msg.e0 = "enum3"
    s0.f0 = 3.14
    s0.f1 = 3.14159265358979

    l0[1] = 28
    l0[2] = 29

    msg.t0 = "hello"

    msg.e1 = "enum7"
--[[
    ]]
    return msg:serialize()
end

print("Benchmarking ", times .. " times.")

local res
local t1 = os.clock()

for i=1, times do
    res = run1()
    res = run1()
    res = run1()
    res = run1()
    res = run1()
end

print("Elapsed: ", os.clock() - t1)

local f = io.open("out.txt", "w")
f:write(res)
f:close()

