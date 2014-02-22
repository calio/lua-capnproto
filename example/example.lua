local example_capnp = require "example_capnp"
local capnp = require "capnp"
local cjson = require "cjson"
local util = require "capnp.util"

local data = {
    people = {
        {
            id = "123",
            name = "Alice",
            email = "alice@example.com",
            phones = {
                {
                    number = "555-1212",
                    ["type"] = "MOBILE",
                },
            },
            employment = {
                school = "MIT",
            },
        },
        --[[
        {
            id = "456",
            name = "Bob",
            email = "bob@example.com",
            phones = {
                {
                    number = "555-4567",
                    ["type"] = "HOME",
                },
                {
                    number = "555-7654",
                    ["type"] = "WORK",
                },
            },
            employment = {
                unemployed = "void",
            },
        },
        ]]
    }
}

local bin = example_capnp.AddressBook.serialize(data)
util.write_file("dump", bin)
local decoded = example_capnp.AddressBook.parse(bin)

print(cjson.encode(decoded))
print("Done")
