local compile = require ("compile")
local util = require ("util")

function usage()
    print("lua compile.lua [schema.txt]")
end

local f = arg[1]
if not f then
    usage()
    return
end

--[[
local t = get_schema_text(f)

local file = io.open("test.schema.lua", "w")
file:write(t)
file:close()

local schema = assert(loadstring(t))()
]]

local schema = util.parse_capnp_decode(f, "test.schema.lua")
local outfile = util.get_output_name(schema) .. ".lua"

local res = compile.compile(schema)

local file = io.open(outfile, "w")
file:write(res)
file:close()


local outfile = "data_generator.lua"
local res = compile.compile_data_generator(schema)

local file = assert(io.open(outfile, "w"))
file:write(res)
file:close()
