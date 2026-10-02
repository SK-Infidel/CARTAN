# Sprint 509 Task List: Full-VRAM Resident INT8 Manifold

**Status**: Complete  
**Goal**: 100% VRAM-Resident INT8 Manifold on RTX 2000 Ada with 15–25+ tok/s decode throughput  

---

### Gate 1: WGSL INT8 Kernels & Mathematical Parity
- [x] Task 1.1: Author authentic WGSL compute shader `geglu_int8_fwd` utilizing `unpack4x8snorm` for fused Gate and Up GEMVs.
- [x] Task 1.2: Author authentic WGSL compute shader `down_proj_int8_fwd` for Down GEMV.
- [x] Task 1.3: Build `scratch/verify_wgsl_int8_gemv.car` and verify numerical parity against CPU `@cartan_simd_dot_i8_f32`.

### Gate 2: Full-VRAM Layer Allocation & Persistent Bind Groups
- [x] Task 2.1: Implement `cartan_transformer_mount_gpu_resident_int8()` to allocate 42 layer storage buffers in VRAM.
- [x] Task 2.2: Stream all 42 `manifold_layer_{i}_int8.bin` checkpoints into GPU VRAM once during initialization.
- [x] Task 2.3: Pre-create persistent `WGPUBindGroup` handles for all 42 layers, resolving `[ISSUE-360]`.

### Gate 3: Decode Pipeline Integration & Single Layer Benchmark
- [x] Task 3.1: Wire GPU INT8 GeGLU dispatch into `cartan_manifold_layer_forward_native` in `src/std/transformer.cl`.
- [x] Task 3.2: Run `scratch/bench_single_decode_step.car` and measure per-layer GPU latency.

### Gate 4: Live Model Verification & QA Regression Clearance
- [x] Task 4.1: Recompile `bin/geomind.exe` with resident VRAM INT8 acceleration enabled.
- [x] Task 4.2: Execute authentic live chat queries (`-prompt "Hello"`, `-prompt "What are you?"`), recording tok/s telemetry and text coherence.
- [x] Task 4.3: Execute full regression test suite (`tools/run_affected_tests.ps1 -All`), verifying 88/88 targets pass.
- [x] Task 4.4: Update `CHANGELOG.md`, `ISSUES.md`, and write `docs/archive/sprint_509_walkthrough.md`.
