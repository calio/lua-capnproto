lua-capnproto
=============

[Cap’n Proto](http://kentonv.github.io/capnproto/index.html) is an insanely fast data interchange format and capability-based RPC system.

Lua-capnproto is a pure lua implementation of capnproto based on luajit.

This project is still under early development and is not production-ready.

Installation
============
To install lua-capnproto, you need to install Cap'n Proto <http://kentonv.github.io/capnproto/install.html> and luarocks <http://luarocks.org/en/Download> first.

Then you can install lua-capnproto using the fallowing commands:

    git clone https://github.com/cloudflare/lua-capnproto.git
    cd lua-capnproto
    sudo luarocks make

Let's compile an example file to test whether lua-capnproto was installed sucessfully:

    capnp compile -olua proto/example.capnp

Normally, you should see no errors and a file named "proto/example_capnp.lua" is generated.
