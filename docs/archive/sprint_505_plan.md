# Sprint 505 Plan: Real-Time Multithreaded Decode & Interactive Acceleration

**Goal**: Transform single-token decode latency from 740 ms/tok (~1.4 tok/s) into interactive real-time speeds by cache-aligning GQA attention accumulation and enabling multi-threaded GEMV execution across the 24-core Intel i9 host.

---

## User Stories
1. **As a user (Rick)**, I want `geomind.exe` to generate tokens interactively and responsively without a 740ms pause between each token.
2. **As the CARTAN runtime**, I want GQA attention value accumulation to execute with cache-friendly contiguous SIMD access rather than 17M strided lookups.
3. **As the CARTAN compiler and runtime**, I want large GEMV operations to utilize multiple host CPU cores via native worker threads.

---

## Squad Assignments
- **Compiler Core Squad (`cartan-compiler-engineer`)**: Validate LLVM IR codegen for worker dispatch and thread parameters.
- **Runtime & Hardware Squad (`cartan_runtime_engineer`)**: Invert attention accumulation loop in `src/std/transformer.cl`; implement multithreaded GEMV row partitioning.
- **Architecture & Security Squad (`cartan-architect`)**: Ensure mathematical exactness of parallel dot products, KV cache causal consistency, and zero-mock compliance.
- **QA & Benchmark Squad (`cartan-qa-tester`)**: Benchmark decode latency via `scratch/bench_single_decode_step.car`, test interactive `bin/geomind.exe`, and verify 88/88 test suite targets.

---

## Definition of Done (DoD)
- [ ] GQA attention loop inverted to outer-`t`, contiguous-`hd` in `src/std/transformer.cl`.
- [ ] Multithreaded GEMV worker execution implemented and empirically verified.
- [ ] Measured decode latency reduction on `scratch/bench_single_decode_step.car`.
- [ ] Zero regressions across all 88 test suite targets (`tools/run_affected_tests.ps1 -All`).
- [ ] `ISSUES.md`, `CHANGELOG.md`, and walkthrough archived in `docs/archive/`.
