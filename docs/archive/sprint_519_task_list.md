# Sprint 519 Task List
## 256-Bit AVX2 Vector Load Optimization & Multi-Stage Bootstrap Fixpoint

- [x] **Gate 1: LLVM Codegen Kernel Optimization**
  - [x] Update `@cartan_simd_dot_i8_f32` in `src/cartanc/llvm_codegen.car` with single 256-bit `load <32 x i8>, ptr %u_ptr1, align 1`.
  - [x] Implement `shufflevector` slicing into four `<8 x i8>` chunks and sign-extend to `<8 x i32>` / `<8 x float>`.
  - [x] Maintain 4-way unrolled accumulator registers for optimal FMA pipelining.

- [x] **Gate 2: Compiler Rebuild & Bootstrap Verification**
  - [x] Build updated compiler: `cartanc.exe build src/cartanc/main.car -o bin/cartanc.exe`.
  - [x] Update root `cartanc.exe` with new build.
  - [x] Verify fixpoint parity across stages and parity test suite (`scratch/test_dot_parity.car`).

- [x] **Gate 3: GeoMind Recompilation & Empirical Testing**
  - [x] Rebuild `bin/geomind.exe` with updated compiler.
  - [x] Benchmark prompt inference and verify accuracy, latency, and tok/s.
  - [x] Run regression suite via `tools/run_affected_tests.ps1` (7/7 passed).

- [x] **Gate 4: Issue Tracking & Documentation**
  - [x] Update `ISSUES.md` (record and resolve ISSUE-376).
  - [x] Update `docs/ROADMAP.md`.
  - [x] Update `CHANGELOG.md`.
  - [x] Author `docs/archive/sprint_519_walkthrough.md`.

