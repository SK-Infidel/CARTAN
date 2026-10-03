# Sprint 519 Implementation Plan
## 256-Bit AVX2 Vector Load Optimization & Multi-Stage Bootstrap Fixpoint

**Sprint**: 519  
**Mission**: Upgrade `@cartan_simd_dot_i8_f32` in `src/cartanc/llvm_codegen.car` to full 256-bit `<32 x i8>` vector loads, eliminate 75% of weight load instructions, achieve bit-for-bit self-hosting fixpoint parity, and benchmark inference.

---

### Objectives
1. **LLVM Codegen Kernel Upgrade (`src/cartanc/llvm_codegen.car`)**:
   - In `@cartan_simd_dot_i8_f32`, replace four separate `<8 x i8>` loads with a single 256-bit `load <32 x i8>, ptr %u_ptr1, align 1`.
   - Use `shufflevector` to distribute 8-byte sub-slices to the 4 FMA pipeline lanes.
   - Maintain 4 independent vector accumulators (`%vacc0..3`) to saturate x86 FMA execution ports.
2. **3-Stage Bootstrap & Fixpoint Verification**:
   - Recompile compiler: `cartanc.exe build src/cartanc/main.car -o bin/cartanc.exe`.
   - Run 3-stage bootstrap fixpoint check to ensure zero IR drift.
3. **Model Recompilation & Empirical Verification**:
   - Recompile `bin/geomind.exe`.
   - Benchmark INT8 prefill and single-token decode latency.
   - Run regression test suite (`tools/run_affected_tests.ps1`).
