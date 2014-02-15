#!/bin/bash

for file in `ls test/0*.lua`
do
    echo
    echo "Running $file..."
    luajit $file || exit 1
done
luajit test/11-handwritten.lua || exit 1
