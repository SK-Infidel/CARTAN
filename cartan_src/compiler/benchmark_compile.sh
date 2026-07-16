#!/bin/bash
# cartan_src/compiler/benchmark_compile.sh
# Benchmarks the Rust cartanc compiler vs the self-hosted cartanc compiler

echo "Benchmarking Cartan Compilation Performance..."
echo "----------------------------------------------"

echo "1. Building the Rust Compiler (Baseline)..."
cd ../../compiler
cargo build --release

echo ""
echo "2. Compiling with Rust (cartanc)..."
time ./target/release/cartanc build ../cartan_src/test_phase12.car

echo ""
echo "3. Compiling with Self-Hosted Cartan (cartanc_v2)..."
# Assuming cartanc_v2 is the natively compiled bootstrap binary
if [ -f "./build/cartanc_v2.exe" ]; then
    time ./build/cartanc_v2.exe build ../cartan_src/test_phase12.car
else
    echo "Warning: Self-hosted compiler not yet built (Phase 5 incomplete). Skipping..."
fi

echo "----------------------------------------------"
echo "Benchmark Complete."
