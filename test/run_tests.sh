#!/bin/bash

for file in `ls test/*.lua`
do
    echo
    echo "Running $file..."
    luajit $file || exit 1
done
