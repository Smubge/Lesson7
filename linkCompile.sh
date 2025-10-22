#!/bin/bash
set -e
cc -c rtlib.c 
clang -fpass-plugin=build/skeleton/SkeletonPass.so -c a.c
cc a.o rtlib.o 
./a.out
