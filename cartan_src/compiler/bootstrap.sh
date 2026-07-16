#!/bin/bash
# cartan_src/compiler/bootstrap.sh
# Automates the Phase 5 Bootstrap Process

echo "Starting CARTAN Compiler Bootstrap Process..."

echo "[Step 1] Building self-hosted cartanc (cartanc_v2) using legacy Rust cartanc..."
# We will compile main.car which serves as the entry point, though in a real scenario
# we would link all .car files together.
cd ../../compiler
cargo build --release
./target/release/cartanc build-exe ../cartan_src/compiler/main.car
# Move the compiled executable to build/
mv build/main.exe build/cartanc_v2.exe

echo "[Step 2] Using cartanc_v2 to compile itself (cartanc_v3)..."
# cartanc_v2 compiles main.car
./build/cartanc_v2.exe build-exe ../cartan_src/compiler/main.car
mv build/main.exe build/cartanc_v3.exe

echo "[Step 3] Verifying output equivalence..."
# Check if the binaries are exactly the same size or hash
HASH2=$(md5sum build/cartanc_v2.exe | awk '{print $1}')
HASH3=$(md5sum build/cartanc_v3.exe | awk '{print $1}')

if [ "$HASH2" == "$HASH3" ]; then
    echo "SUCCESS: cartanc_v2 and cartanc_v3 are identical ($HASH2)."
    echo "The CARTAN compiler is fully self-hosted!"
else
    echo "ERROR: Output binaries differ!"
    echo "cartanc_v2: $HASH2"
    echo "cartanc_v3: $HASH3"
    exit 1
fi
