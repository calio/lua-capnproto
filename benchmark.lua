jit.opt.start("loopunroll=1000")

local ffi           = require "ffi"
local test_capnp    = require "handwritten_capnp"
local capnp         = require "capnp"

local times         = arg[1] or 200000

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

local size = test_capnp.T1.calc_size(data)
local buf = ffi.new("char[?]", size)

function run4()
    return test_capnp.T1.serialize(data, buf, size)
end

function run3()
    return test_capnp.T1.serialize(data)
end


print("Benchmarking ", times .. " times.")

local res

function bench(func)
    local t1 = os.clock()

    for i=1, times do
        res = func()
    end

    print("Elapsed: ", os.clock() - t1)
end

--bench(run3)
bench(run4)

local f = io.open("out.txt", "w")
f:write(res)
f:close()
