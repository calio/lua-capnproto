--local test_capnp = require "handwritten_capnp"
package.path = "lua/?.lua;proto/?.lua;" .. package.path

local data_generator = require "data_generator"
local test_capnp = require "example_capnp"
local handwritten_capnp = require "handwritten_capnp"
local log_capnp = require "log_capnp"
local capnp = require "capnp"
local cjson = require "cjson"
local util = require "util"

local format = string.format


function table_diff(t1, t2, namespace)
    local keys = {}

    if not namespace then
        namespace = ""
    end

    for k, v in pairs(t1) do
        k = util.lower_underscore_naming(k)
        keys[k] = true
        t1[k] = v
    end

    for k, v in pairs(t2) do
        k = util.lower_underscore_naming(k)
        keys[k] = true
        t2[k] = v
    end

    for k, v in pairs(keys) do
        local name = namespace .. "." .. k
        local v1 = t1[k]
        local v2 = t2[k]

        local t1 = type(v1)
        local t2 = type(v2)

        if t1 ~= t2 then
            print(format("%s: different type: %s %s", name,
                    t1, t2))
        elseif t1 == "table" then
            table_diff(v1, v2, namespace .. "." .. k)
        elseif v1 ~= v2 then
            print(format("%s: different value: %s %s", name,
                    tostring(v1), tostring(v2)))
        end
    end
end

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
local bin = test_capnp.T1.serialize(data)

local decoded = handwritten_capnp.T1.parse(bin)

table_diff(data, decoded)

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

    table_diff(generated_data, decoded, "")
end

random_test()
]]
print("Done")
