local compile = require ("compile")
local util = require ("util")
local cjson = require ("cjson")

local format = string.format
local insert = table.insert
local concat = table.concat


local schema_lua_file   = "test.schema.lua"
local schema_json_file  = "lua.schema.json"

function usage()
    print("lua compile.lua [schema.txt]")
end


local f = arg[1]
if not f then
    usage()
    return
end

local naming
local config = {
}
local namings = {}
for k, v in pairs(compile.naming_funcs) do
    insert(namings, k)
end

-- TODO fix this
 arg[2] = "--naming=camel"

for i=2, #arg do
    if string.sub(arg[i], 1, 9) == "--naming=" then
        naming = string.sub(arg[i], 10)
        local naming_func = compile.naming_funcs[naming]
        if not naming_func then
            error(format("unknown naming: %s. Available values are %s", naming,
                    concat(namings, " ")))
        end
        config.default_naming_func = naming_func
        config.default_enum_naming_func = naming_func
    end
end

local lua_schema = util.parse_capnp_decode_txt(f)
util.write_file(schema_lua_file, lua_schema)

local schema = assert(loadstring(lua_schema)())

schema.__compiler = "lua-capnp(decoded by capnp tool)"
util.write_file(schema_json_file, cjson.encode(schema))

local outfile = util.get_output_name(schema) .. ".lua"

print("set config:")
compile.init(config)
local res = compile.compile(schema)

local file = io.open(outfile, "w")
file:write(res)
file:close()


local outfile = "data_generator.lua"
local res = compile.compile_data_generator(schema)

local file = assert(io.open(outfile, "w"))
file:write(res)
file:close()
