# Sprint 521 Task List
## INT4 Weight Packing & SIMD Unpacking Engine

- [x] **Gate 1: Compiler Backend & SIMD Kernel**
  - [x] Implement `@cartan_simd_dot_i4_f32` in `src/cartanc/llvm_codegen.car`.
  - [x] Declare `extern fn cartan_simd_dot_i4_f32` in `src/cartanc/core_runtime.car`.
  - [x] Rebuild self-hosted compiler `cartanc.exe`.
  - [x] Author `scratch/test_dot_parity_i4.car` and verify bit-level mathematical parity across 12 vector sizes.

- [x] **Gate 2: Offline W4A32 Quantizer**
  - [x] Author `tools/quantize_manifold_int4.car`.
  - [x] Quantize test layer 0 to `manifold_layer_0_int4.bin` and verify size is ~46.6 MB (50% reduction).
  - [x] Quantize full 42 layers.

- [x] **Gate 3: Transformer Runtime & Multi-Threaded Dispatch**
  - [x] Add INT4 layer buffer offset calculation in `src/std/transformer.cl` (`hdr[11] == 2.0`).
  - [x] Implement Ops 12, 13, 14 (single-token GEMV, Dual GEMV, GeGLU) and Ops 15, 16, 17 (batched prefill row-outer GEMV, Dual GEMV, GeGLU).
  - [x] Implement batched dispatch helpers and `cartan_manifold_layer_forward_batch_int4`.
  - [x] Wire INT4 decode execution into `cartan_manifold_layer_forward_native` and prefill into `cartan_manifold_layer_forward_batch`.
  - [x] Update `test/geomind/chat.cl` to ingest INT4 checkpoint layers.

- [x] **Gate 4: Empirical Testing & Regression Verification**
  - [x] Rebuild `bin/geomind.exe`.
  - [x] Verify live prompt inference with INT4 weights.
  - [x] Execute compiler regression suite via `tools/run_affected_tests.ps1` (10/10 PASS).
  - [x] Update `ISSUES.md`, `docs/ROADMAP.md`, `CHANGELOG.md`, and author `docs/archive/sprint_521_walkthrough.md`.
