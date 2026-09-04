# Sprint 273 Implementation Plan: Scientific Floating-Point LLVM IR Formatting & Verification

## Goal
Fix scientific notation formatting for floating-point literals in `src/cartanc/c_runtime.c` and `src/cartanc/llvm_codegen.car` so that literals like `0.000001` format as valid LLVM IR (`1.0e-06`) instead of invalid tokens (`1e-06.0`), and verify compilation of `test/geomind/main.car`.

## Proposed Changes

### 1. `src/cartanc/c_runtime.c` (`c_cartan_float_to_string`)
Ensure any scientific notation output has a decimal point in the mantissa before `e`/`E`.
If `strpbrk(buf, "eE")` exists and no `.` exists prior to the exponent, insert `.0` into the mantissa.

### 2. `src/cartanc/llvm_codegen.car` (`as_float`)
Add guards for `e` and `E` in `as_float` to prevent appending `.0` if the string already has an exponent.

### 3. Rebuild Toolchain & Empirical Verification
1. Recompile `cartanc.exe`.
2. Compile `test/geomind/main.car -o bin/geomind_native.exe`.
3. Verify zero LLVM IR syntax errors.
4. Update `CHANGELOG.md` and archive sprint retro.
