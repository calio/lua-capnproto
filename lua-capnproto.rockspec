package = "lua-capnproto"
version = "0.1.0-1"
source = {
   url = "git://github.com/cloudflare/lua-capnproto",
   tag = "v0.1.0-1",
}
description = {
   summary = "Lua-capnproto is a pure lua implementation of capnproto based on luajit.",
   detailed = [[
       Lua-capnproto is a pure lua implementation of capnproto based on luajit.
   ]],
   homepage = "https://github.com/calio/lua-capnproto",
   license = "BSD",
}
dependencies = {
   "lua ~> 5.1",     -- in fact, this should be "luajit >= 2.1.0"
}
build = {
   -- We'll start here.
   type = "builtin",
   modules = {
      capnp = "capnp.lua",
      ['capnp.compile'] = "capnp/compile.lua",
      ['capnp.util'] = "capnp/util.lua",
   },
   install = {
      bin = {
         ['capnpc-lua'] = "bin/capnpc-lua",
         ['capnpc-echo'] = "bin/capnpc-echo",
         ['schema.capnp'] = "bin/schema.capnp",
      }
   }
}
