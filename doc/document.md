# lua-capnproto

Code structure
==============

    ├── bin         Cap'n Proto compiler's plug-ins and Cap'n Proto schema file
    ├── capnp       lua-capnproto library file (including compiler)
    ├── cpp         cpp files used for testing lua-capnproto
    ├── example     examples for how to use lua-capnproto
    ├── lua         other lua files
    ├── proto       all protos
    └── tests       test files

Debugging
=========

Set environment variable `VERBOSE` to 1 enables debug mode. Compiler will generate more debug info and the following files:

* `test.schema.lua` This is the schema passed from Cap'n Proto compiler to lua plug-in. Cap'n Proto text presentation has been translated to lua file.
* `lua.schema.json` Schema that lua-capnproto compiler used

Compiling proto files
=====================

All proto files including imported proto files should be compiled together. Output file will use first input proto file's name plus a "_capnp.lua" suffix. For example:

    capnp compile -olua message.capnp constants.capnp

Output file will be `message_capnp.lua`

When developing, you may need to run the following command. This specifies which capnpc-lua to use.

    VERBOSE=1 capnp compile -o ../bin/capnpc-lua example.capnp enums.capnp lua.capnp struct.capnp

How to add a new naming function
================================

* add a new naming function in capnp/util.lua
* add a test case in tests/02-util.lua
* test new naming function by `make test`
* add your naming function to "naming_funcs" table in "capnp/compile.lua" using this kind of format: `name = function`. 'name' is what you will write in Cap'n Proto file using "$Lua.naming" annotation. 'function' is you actual naming function
* add a new enum in proto/enums.capnp.
* add a test case in tests/11-handwritten.lua (see test_lower_space_naming)
* update lua/handwritten_capnp.lua using `vimdiff lua/handwritten_capnp.lua proto/example_capnp.lua`

Generated code
===============

`calc_size`             - calculate size need for serialization using given input data, header size included
`calc_size_struct`      - calculate size need for serialization using given input data, header size not included
