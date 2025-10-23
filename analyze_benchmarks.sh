#!/bin/bash

# Script to analyze and test benchmark results
# Usage: ./analyze_benchmarks.sh

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

OUTPUT_DIR="benchmark_results"

if [ ! -d "$OUTPUT_DIR" ]; then
    echo -e "${RED}Error: $OUTPUT_DIR not found. Run ./run_benchmarks.sh first.${NC}"
    exit 1
fi

echo -e "${BLUE}=== Benchmark Analysis ===${NC}\n"

# Analyze each benchmark
for original_ir in "$OUTPUT_DIR/ir_original"/*.ll; do
    basename=$(basename "$original_ir" .ll)
    optimized_ir="$OUTPUT_DIR/ir_optimized/${basename}_opt.ll"
    
    echo -e "${GREEN}Benchmark: $basename${NC}"
    
    # Instruction count comparison
    original_instr=$(grep -c "^  %" "$original_ir" 2>/dev/null)
    optimized_instr=$(grep -c "^  %" "$optimized_ir" 2>/dev/null)
    
    if [ -n "$original_instr" ] && [ -n "$optimized_instr" ] && [ "$original_instr" -gt 0 ]; then
        diff_instr=$((original_instr - optimized_instr))
        reduction=$((100 * diff_instr / original_instr))
        echo "  Instructions: $original_instr → $optimized_instr ($reduction% reduction)"
    fi
    
    # File size comparison
    if [ -f "$original_ir" ] && [ -f "$optimized_ir" ]; then
        original_size=$(stat -c%s "$original_ir" 2>/dev/null)
        optimized_size=$(stat -c%s "$optimized_ir" 2>/dev/null)
        
        if [ -n "$original_size" ] && [ -n "$optimized_size" ] && [ "$original_size" -gt 0 ]; then
            size_diff=$((original_size - optimized_size))
            size_reduction=$((100 * size_diff / original_size))
            echo "  IR size: $original_size → $optimized_size bytes ($size_reduction% reduction)"
        fi
    fi
    
    # Binary size comparison (if executables exist)
    original_bin="$OUTPUT_DIR/executables/${basename}_original"
    optimized_bin="$OUTPUT_DIR/executables/${basename}_optimized"
    
    if [ -f "$original_bin" ] && [ -f "$optimized_bin" ]; then
        orig_bin_size=$(stat -c%s "$original_bin" 2>/dev/null)
        opt_bin_size=$(stat -c%s "$optimized_bin" 2>/dev/null)
        
        if [ -n "$orig_bin_size" ] && [ -n "$opt_bin_size" ] && [ "$orig_bin_size" -gt 0 ]; then
            bin_diff=$((orig_bin_size - opt_bin_size))
            bin_reduction=$((100 * bin_diff / orig_bin_size))
            echo "  Binary size: $orig_bin_size → $opt_bin_size bytes ($bin_reduction% reduction)"
        fi
        
        # Run executables and compare output
        echo -n "  Testing correctness: "
        
        "$original_bin" 2>/dev/null
        original_exit=$?
        
        "$optimized_bin" 2>/dev/null
        optimized_exit=$?
        
        if [ "$original_exit" -eq "$optimized_exit" ]; then
            echo -e "${GREEN}✓ PASS${NC} (exit code: $original_exit)"
        else
            echo -e "${RED}✗ FAIL${NC} (original: $original_exit, optimized: $optimized_exit)"
        fi
    fi
    
    # Show key optimizations from diff
    diff_file="$OUTPUT_DIR/diffs/${basename}.diff"
    if [ -f "$diff_file" ]; then
        removed_lines=$(grep -c "^-  %" "$diff_file" 2>/dev/null || echo "0")
        added_lines=$(grep -c "^+  %" "$diff_file" 2>/dev/null || echo "0")
        echo "  Changes: -$removed_lines / +$added_lines instructions"
    fi
    
    echo ""
done

echo -e "${BLUE}=== Detailed Diffs ===${NC}"
echo "To view detailed changes for a specific benchmark:"
echo "  cat $OUTPUT_DIR/diffs/<benchmark_name>.diff"
echo ""
echo "To view optimized IR:"
echo "  cat $OUTPUT_DIR/ir_optimized/<benchmark_name>_opt.ll"

echo -e "\n${GREEN}Analysis complete!${NC}"
