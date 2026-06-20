#!/usr/bin/bash

# COMMENT

if [ -d ./build/ ]; then
    time odin build src -out:build/Test -debug && ./build/Test
else
    mkdir build
    echo "Created the build directory !"
    time odin build src -out:build/Test -debug && ./build/Test
fi
