#!/bin/bash
set -e
cd build
cmake ..
make 
cd ..
echo "Creating the LLVM IR..."
clang -emit-llvm -S test.c -o test.ll
echo "Creating the optimized IR..."
opt -load-pass-plugin=build/skeleton/SkeletonPass.so \
    -passes="default<O0>" \
    test.ll -S -o test_optimized.ll
echo "Optimization complete! Difference between original and optimized IR:"
diff -u test.ll test_optimized.ll || true
echo "Finished comparing the IR files."
