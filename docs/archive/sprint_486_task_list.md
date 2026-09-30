# Sprint 486 Task List: Phase 2 Core Runtime Integrity & Stub Eradication

## Gate 1: Authentic Vector Autodiff & Vectorized Mapping (`cartan_rt_transform`)
- [x] **Task 1.1**: Purge toy formula `1.0 + (v * 0.01)` in `src/cartanc/core_runtime.car`.
- [x] **Task 1.2**: Implement authentic analytical quadratic gradient $\nabla L(v) = v$ for `cartan_rt_transform("grad", target)`.
- [x] **Task 1.3**: Implement vectorized batch mapping in `cartan_rt_transform("vmap", target)`.

## Gate 2: Authentic Binary Checkpoint Weight Absorption (`cartan_absorb_weights`)
- [x] **Task 2.1**: Implement binary checkpoint file reading via `fopen`, `fseek`, `ftell`, `fread`, and `fclose` in `cartan_absorb_weights`.
- [x] **Task 2.2**: Stream binary weights directly into flat tensor / vector memory buffers.
- [x] **Task 2.3**: Add error handling for missing or unreadable donor files.

## Gate 3: Fail-Fast ONNX Ingestion & Compute Graph Teardown
- [x] **Task 3.1**: Update `cartan_internal_import_onnx(uri)` to check file existence and log diagnostics when missing.
- [x] **Task 3.2**: Implement authentic active compute graph cleanup in `cartan_free_compute_graph()`.

## Gate 4: Authentic Tensor Magnitude Pruning & Fluid Precision
- [x] **Task 4.1**: Implement `cartan_tensor_prune_magnitude(t: ptr, threshold: float) -> ptr` setting $|w| < \tau \implies 0.0$.
- [x] **Task 4.2**: Wire `cartan_prune_graph(threshold)` to invoke magnitude pruning.
- [x] **Task 4.3**: Implement mantissa truncation for FP16/BF16 dynamic range reduction in `cartan_fluid_truncate_fp16`.

## Gate 5: 3-Stage Bootstrap Fixpoint & Full Regression Clearance
- [x] **Task 5.1**: Execute 3-stage bootstrap (`bin/cartanc_stage1.exe` -> `bin/cartanc_fresh.exe` -> `bin/cartanc_stage3.exe`).
- [x] **Task 5.2**: Prove bit-for-bit fixpoint convergence via SHA256 comparison (`88C7C4DE9CB0DED97DA1B98C002B4550109421DC57146796DB12D3D035C257AD`).
- [x] **Task 5.3**: Synchronize `cartanc.exe` and `bin/cartanc.exe`.
- [x] **Task 5.4**: Run Target 62 (`test_transforms_and_logic.car`) and verify clean pass.
- [x] **Task 5.5**: Run full 87-target regression test suite (`tools/run_affected_tests.ps1 -All` - 87/87 pass).
- [x] **Task 5.6**: Re-verify empirical chat inference on `geomind.exe` ("The capital of Iran is **Tehran**.").
- [x] **Task 5.7**: Update `CHANGELOG.md`, `ISSUES.md`, and write `docs/archive/sprint_486_walkthrough.md`.
