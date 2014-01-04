#!/bin/bash

export PATH=$(pwd)/bin:$PATH

echo "[Unit test...]"
make test || exit

echo
echo "[Serialization test...]"
CXX=g++-4.7 make all
./main > a.data || exit

capnp compile -olua proto/example.capnp || exit
mv proto/example_capnp.lua .

luajit foo.lua c.data || exit
xxd -g 1 a.data || exit
echo
xxd -g 1 c.data || exit
diff a.data c.data
echo
xxd -g 1 flat.c.data
diff c.data flat.c.data
echo "[Done]"
