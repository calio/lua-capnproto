#!/bin/bash

export PATH=$(pwd)/bin:$PATH
export LUA_PATH="lua/?.lua;proto/?.lua;$LUA_PATH;;"

echo "[Unit test...]"
make test || exit

echo
echo "[Serialization test...]"
if [ $(uname) != "Linux" ]; then
    make all
else
    CXX=g++-4.7 make all
fi
cpp/main > a.data || exit
capnp compile -olua proto/example.capnp || exit
luajit test.lua c.data || exit
echo
echo "capnp c++ result:"
xxd -g 1 a.data || exit
echo "capnp lua result:"
xxd -g 1 c.data || exit
diff a.data c.data

echo "[Done]"
