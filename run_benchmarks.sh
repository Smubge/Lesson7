#!/bin/bash

# Script to run optimization pass on all benchmarks
# Usage: ./run_benchmarks.sh

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directories
BENCHMARK_DIR="benchmarks"
OUTPUT_DIR="benchmark_results"
PASS_LIB="build/skeleton/SkeletonPass.so"

# Create output directory structure
mkdir -p "$OUTPUT_DIR/ir_original"
mkdir -p "$OUTPUT_DIR/ir_optimized"
mkdir -p "$OUTPUT_DIR/executables"
mkdir -p "$OUTPUT_DIR/diffs"

# Check if pass library exists
if [ ! -f "$PASS_LIB" ]; then
    echo -e "${RED}Error: Pass library not found at $PASS_LIB${NC}"
    echo "Please build the project first with: cd build && make"
    exit 1
fi

echo -e "${BLUE}=== Processing Benchmarks ===${NC}\n"

# Process each .c file in benchmarks directory
for benchmark in "$BENCHMARK_DIR"/*.c; do
    if [ ! -f "$benchmark" ]; then
        echo "No benchmark files found in $BENCHMARK_DIR"
        exit 1
    fi
    
    # Extract filename without path and extension
    basename=$(basename "$benchmark" .c)
    
    echo -e "${GREEN}Processing: $basename${NC}"
    
    # 1. Generate original LLVM IR
    echo "  - Generating original IR..."
    clang -emit-llvm -S -O0 "$benchmark" -o "$OUTPUT_DIR/ir_original/${basename}.ll"
    
    # 2. Run optimization pass
    echo "  - Running optimization pass..."
    opt -load-pass-plugin="$PASS_LIB" \
        -passes="default<O0>" \
        "$OUTPUT_DIR/ir_original/${basename}.ll" \
        -S -o "$OUTPUT_DIR/ir_optimized/${basename}_opt.ll"
    
    # 3. Generate diff
    echo "  - Generating diff..."
    diff -u "$OUTPUT_DIR/ir_original/${basename}.ll" \
            "$OUTPUT_DIR/ir_optimized/${basename}_opt.ll" \
            > "$OUTPUT_DIR/diffs/${basename}.diff" || true
    
    # 4. Try to compile if it has a main function (optional)
    if grep -q "int main" "$benchmark"; then
        echo "  - Compiling optimized executable..."
        clang "$OUTPUT_DIR/ir_optimized/${basename}_opt.ll" \
              -o "$OUTPUT_DIR/executables/${basename}_optimized" 2>/dev/null || \
              echo "    (Skipping executable - compilation failed)"
        
        echo "  - Compiling original executable..."
        clang "$benchmark" -O0 -o "$OUTPUT_DIR/executables/${basename}_original" 2>/dev/null || \
              echo "    (Skipping executable - compilation failed)"
    else
        echo "  - Skipping executable generation (no main function)"
    fi
    
    echo -e "${GREEN}  ✓ Completed${NC}\n"
done

echo -e "${BLUE}=== Summary ===${NC}"
echo "Results saved in: $OUTPUT_DIR/"
echo ""
echo "Directory structure:"
echo "  - ir_original/     : Original LLVM IR files"
echo "  - ir_optimized/    : Optimized LLVM IR files"
echo "  - diffs/           : Differences between original and optimized IR"
echo "  - executables/     : Compiled binaries (both original and optimized)"
echo ""
echo -e "${GREEN}Done!${NC}"
