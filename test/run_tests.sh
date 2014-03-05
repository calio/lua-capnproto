#!/bin/bash

for file in `ls test/11*.lua`
do
    echo
    echo "Running $file..."
    #valgrind --tool=memcheck --vgdb=yes --vgdb-error=0 /opt/luajit-dbg/bin/luajit-2.1.0-alpha $file || exit 1
    luajit $file || exit 1
done
