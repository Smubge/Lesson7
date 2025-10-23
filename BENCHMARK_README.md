# Benchmark Testing Suite

This directory contains scripts to test and analyze the LLVM optimization pass on multiple benchmarks.

## Quick Start

1. **Build the optimization pass:**
   ```bash
   cd build
   make
   cd ..
   ```

2. **Run all benchmarks:**
   ```bash
   ./run_benchmarks.sh
   ```

3. **Analyze results:**
   ```bash
   ./analyze_benchmarks.sh
   ```

## Scripts

### `run_benchmarks.sh`
Processes all `.c` files in the `benchmarks/` directory and generates:
- Original LLVM IR
- Optimized LLVM IR (after running your pass)
- Diff files showing changes
- Compiled executables (both original and optimized)

**Output structure:**
```
benchmark_results/
├── ir_original/       # Original LLVM IR files
├── ir_optimized/      # Optimized LLVM IR files
├── diffs/             # IR differences
└── executables/       # Compiled binaries
```

### `analyze_benchmarks.sh`
Analyzes the optimization results and shows:
- Instruction count reduction
- IR file size reduction
- Binary size comparison
- Correctness testing (compares exit codes)
- Number of changed instructions

## Existing Benchmarks

### `benchmarks/arithmetic.c`
Tests constant folding for arithmetic operations (add, sub, mul, div).

### `benchmarks/dce.c`
Tests dead code elimination.

### `benchmarks/div_zero.c`
Tests division by zero handling (should not fold divisions by zero).

### `benchmarks/mixed.c`
Tests mixed scenarios with constants and variables.

## Adding New Benchmarks

1. Create a new `.c` file in `benchmarks/`:
   ```c
   // benchmarks/my_test.c
   int my_test() {
       int x = 5 + 3;
       return x * 2;
   }
   ```

2. Run the benchmark suite:
   ```bash
   ./run_benchmarks.sh
   ```

The new benchmark will automatically be processed!

## Viewing Results

### View a specific diff:
```bash
cat benchmark_results/diffs/arithmetic.diff
```

### View optimized IR:
```bash
cat benchmark_results/ir_optimized/arithmetic_opt.ll
```

### Run a specific optimized binary:
```bash
./benchmark_results/executables/arithmetic_optimized
echo $?  # Check exit code
```

### Compare original vs optimized:
```bash
./benchmark_results/executables/arithmetic_original
echo "Original exit: $?"

./benchmark_results/executables/arithmetic_optimized
echo "Optimized exit: $?"
```

## Understanding the Output

The analysis script shows:
- **Instructions**: Number of LLVM IR instructions (fewer = better optimization)
- **IR size**: Size of the IR file in bytes
- **Binary size**: Size of compiled executable
- **Correctness**: ✓ if optimized version produces same result as original
- **Changes**: Number of instructions removed (-) and added (+)

## Troubleshooting

### "Pass library not found"
Make sure you've built the project:
```bash
cd build && make && cd ..
```

### "No benchmark files found"
Ensure you have `.c` files in the `benchmarks/` directory.

### Correctness test fails
Check the diff to see what changed. The optimization might be incorrect or the benchmark might have undefined behavior.
