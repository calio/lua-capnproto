lua-capnproto
=============

[Cap’n Proto](http://kentonv.github.io/capnproto/index.html) is an insanely fast data interchange format and capability-based RPC system.

Lua-capnproto is a pure lua implementation of Cap'n Proto based on `LuaJIT`.

This project is still under early development and is not production-ready.

Synopsis
========
Suppose you have a Cap'n Proto file called example.capnp. You can compile this file like this:

    $capnp compile -olua example.capnp

The default output file is `example_capnp.lua`

    local example_capnp = require "example_capnp"

Check out example/AddressBook.capnp and example/main.lua for how to use generated lua file.

Installation
============
To install lua-capnproto, you need to install Cap'n Proto <http://kentonv.github.io/capnproto/install.html>, LuaJIT <http://luajit.org/install.html> and luarocks <http://luarocks.org/en/Download> first.

`Currently, lua-capnproto only works with LuaJIT v2.1`. You can install LuaJIT v2.1 using the following commands:

    $git clone http://luajit.org/git/luajit-2.0.git
    $git checkout v2.1
    $make && sudo make install
    $sudo ln -sf luajit-2.1.0-alpha /usr/local/bin/luajit

Then you can install lua-capnproto using the following commands:

    $git clone https://github.com/cloudflare/lua-capnproto.git
    $cd lua-capnproto
    $sudo luarocks make

Let's compile an example file to test whether lua-capnproto was installed successfully:

    $capnp compile -olua proto/example.capnp

Normally, you should see no errors and a file named "proto/example_capnp.lua" is generated.

How to use
==========
Please see my blog post on how to use lua-capnproto [here](http://blog.cloudflare.com/introducing-lua-capnproto-better-serialization-in-lua).

Testing
=======

If you want to run unit tests, you need to install lunitx and lua-cjson:

    $sudo luarocks install lua-cjson
    $sudo luarocks install lunitx

If your Linux distribution have Lua 5.2 installed, using this [instruction](https://github.com/calio/lua-capnproto/issues/1) to install required lua modules.

To run tests:

	$./test.sh

Limitations
===========
Currently, lua-capnproto only works with LuaJIT v2.1. This is because lua-capnproto needs 64 bit integer support and 64bit number bit operations, but only LuaJIT v2.1 provides a decent way to do all these. I'm working on LuaJIT 2.0/ Lua 5.1 / Lua 5.2 support, hopefully you can use lua-capnproto with your favorite lua soon.
