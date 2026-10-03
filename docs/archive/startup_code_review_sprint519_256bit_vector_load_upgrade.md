# Startup Code Review: Sprint 519
## 256-Bit AVX2 Vector Load Optimization for INT8 GEMV Kernel

**Date**: 2026-10-03  
**Reviewer**: Supervisor Agent & Compiler Core Squad  
**Target**: `src/cartanc/llvm_codegen.car` (`@cartan_simd_dot_i8_f32`)

---

### 1. Root Cause Analysis: Vector Width Load Gap
- **Finding**: In `@cartan_simd_dot_i8_f32`, the 4-way unrolled AVX2 loop was loading weights via four 64-bit loads (`load <8 x i8>`).
- **Hardware Architecture**: AVX2 `ymm` registers are 256 bits (32 bytes). Issuing four 8-byte loads incurs 4x memory address calculations, 4x L1 cache load ports, and unnecessary register unpacking overhead.
- **Optimization**:
  1. Replace four `<8 x i8>` loads with a single contiguous 256-bit load (`load <32 x i8>, ptr %u_ptr1, align 1`).
  2. Slice into 8-element lanes via `shufflevector` and sign-extend to `<8 x i32>` / `<8 x float>`.
  3. Clang/LLD lowers this to direct `vpmovsxbd` / `vpbroadcastq` / `vfmadd231ps` instructions, quadrupling load throughput and keeping 4 independent FMA accumulator ports fully saturated.

---

### 2. Logical Dependency Tree
```
src/cartanc/llvm_codegen.car (@cartan_simd_dot_i8_f32 emitter)
    ├── compiled into compiler (bin/cartanc.exe)
    └── emits machine code for:
            ├── src/std/transformer.cl (cartan_trans_pool_dispatch, INT8 GEMV, Dual GEMV, GeGLU)
            ├── test/geomind/chat.cl (single-token decode, sequence prefill)
            └── test/compiler_suite/ (compiler regression test suite)
```

---

### 3. Issues Identified
- **[ISSUE-376]**: Vector Width Gap: Sub-optimal 64-bit Loads in 256-bit AVX2 INT8 GEMV Kernel
