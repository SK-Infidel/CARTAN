# Sprint 508 Task List: Host-RAM INT8 AVX2 SIMD Engine & Manifold Quantization

- [x] **Phase 1: Pre-Sprint Alignment & Squad Sign-Off**
  - [x] Convene Pre-Sprint Scrum with Squad Leads (`cartan_runtime_engineer`, `cartan_compiler_engineer`, `cartan_architect`, `cartan_qa_tester`).
  - [x] Gather architectural, compiler, and hardware evaluations for Gates 1–4.

- [ ] **Phase 2: Gate 1 — Compiler Core INT8 AVX2 SIMD Primitive**
  - [ ] In `src/cartanc/llvm_codegen.car`, define `@cartan_simd_dot_i8_f32(ptr %w_i8, ptr %x_f32, double %scale, double %count) -> double`.
  - [ ] Register in `func_return_types` and `declared_externs`.
  - [ ] Run 3-stage bootstrap compilation to verify SHA-256 fixpoint convergence.
  - [ ] Validate unit test in `test/compiler_suite/test_compiler_simd_tensor_math.car` (target 82).

- [ ] **Phase 3: Gate 2 — Manifold Layer INT8 Quantization Utility**
  - [ ] Create `tools/quantize_manifold_int8.car` to quantize 42 layers into compact `manifold_layer_{i}_int8.bin`.
  - [ ] Preserve FP32 for all norm vectors; compute per-row scale `scale = max(|W_row|) / 127.0`.
  - [ ] Quantize test layer 0 and measure compressed file size (target < 98 MB).

- [ ] **Phase 4: Gate 3 — INT8 Layer Forward & Thread Pool GEMV**
  - [ ] In `src/std/transformer.cl`, implement INT8 GEMV in `cartan_trans_pool_worker_main` and `cartan_trans_pool_dispatch`.
  - [ ] Implement `cartan_manifold_layer_forward_int8`.

- [ ] **Phase 5: Gate 4 — Empirical Verification & Benchmarking**
  - [ ] Benchmark `bench_single_decode_step.exe` with INT8 layer 0 (verify per-layer latency ~2.0 ms, full 42 layers ~85 ms).
  - [ ] Quantize remaining 41 layers.
  - [ ] Verify live `geomind.exe` interactive chat streaming at 7–9+ tok/s.
  - [ ] Run full 88-target compiler regression suite (`tools/run_affected_tests.ps1 -All`).

- [ ] **Phase 6: Sprint Review, CHANGELOG & Retrospective**
  - [ ] Save walkthrough to `docs/archive/sprint_508_walkthrough.md`.
  - [ ] Update `CHANGELOG.md` and `ISSUES.md`.
