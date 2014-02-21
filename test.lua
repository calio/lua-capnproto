--local test_capnp = require "handwritten_capnp"
--package.path = "lua/?.lua;proto/?.lua;" .. package.path

local data_generator = require "data_generator"
local example_capnp = require "example_capnp"
local handwritten_capnp = require "handwritten_capnp"
-- local log_capnp = require "log_capnp"
local capnp = require "capnp"
local cjson = require "cjson"
local util = require "capnp.util"



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
    d0 = "\1\2\3\4\5\6\7",
    e1 = "enum7",
    ui1 = 0x0f0f,
    g0 = {
        ui2 = 0x12345678,
    },

    u0 = {
        ug0 = {
            ugu0 = 32,
        }
    },

    ls0 = {
        {
            f0 = 0.61803398875,
            f1 = 1.61803398875,
        },
        {
            f0 = 2.71828182846,
            f1 = 2.71828182846,
        },
    },

    lt0 = {
        "foo", "bar",
    },
}

local file = arg[1]
local f = io.open(file, "w")
local bin = handwritten_capnp.T1.serialize(data)

local decoded = handwritten_capnp.T1.parse(bin)

util.table_diff(data, decoded)

f:write(bin)
f:close()



function write_file(name, content)
    local f = assert(io.open(name, "a"))
    f:write(content)
    f:close()
end

--[[
function random_test()
    local generated_data = data_generator.gen_log()

    local bin = log_capnp.Log.serialize(generated_data)

    local outfile = "/tmp/Log.txt"
    os.execute("rm " .. outfile)
    local fh = assert(io.popen("capnp decode /home/calio/code/dollar-store-fork/proto/log.capnp Log > "
            .. outfile, "w"))
    fh:write(bin)
    fh:close()

    write_file("Log.capnp.bin", bin)

    local decoded = util.parse_capnp_decode(outfile, "debug.txt")

    print(cjson.encode(generated_data))
    print(cjson.encode(decoded))

    util.table_diff(generated_data, decoded, "")
end

random_test()
]]
print("Done")
