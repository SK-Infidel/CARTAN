# Sprint 509 Plan: Full-VRAM Resident INT8 Manifold & WebGPU Decode Acceleration

**Sprint**: 509  
**Goal**: Pin all 42 INT8 transformer layers (3.73 GB) resident in dedicated GDDR6 VRAM (8.0 GB) on NVIDIA RTX 2000 Ada and execute hardware-accelerated INT8 compute shaders over the 224 GB/s bus, reaching **15–25+ tokens/second** live interactive generation.  
**Audience**: Rick (Big Daddy) & Engineering Squad  
**Start Date**: October 1, 2026  

---

## Technical Objectives & Architecture

1. **Hardware INT8 WGSL Compute Shaders (`src/std/transformer.cl`, `src/std/wgpu.cl`)**:
   - Author authentic WGSL compute kernels unpacking 4-byte packed INT8 weights via `unpack4x8snorm(packed: u32) * 127.0 * scale`.
   - Implement `geglu_int8_fwd` (fused Gate/Up GEMVs + fast GELU tanh) and `down_proj_int8_fwd`.
   - Verify numerical parity against CPU `@cartan_simd_dot_i8_f32` with max error $< 10^{-4}$.

2. **Persistent VRAM Residency (`src/std/transformer.cl`)**:
   - Allocate 42 persistent VRAM storage buffers (totaling 3.73 GB) in GPU memory at startup.
   - Upload all 42 `manifold_layer_{i}_int8.bin` checkpoints to VRAM once during model initialization.
   - Zero weight transfer over PCIe during inference.

3. **Persistent Bind Groups & Batch Submission (`[ISSUE-360]`, `src/std/wgpu.cl`, `src/std/transformer.cl`)**:
   - Pre-create persistent `WGPUBindGroup` handles at initialization, eliminating descriptor heap allocation churn.
   - Dispatch layers with zero dynamic host `malloc`/`free` calls per token.

4. **Live Chat & Regression Verification (`test/geomind/chat.cl`, `bin/geomind.exe`)**:
   - Verify end-to-end interactive chat generation with fluid streaming at 15–25+ tok/s.
   - Verify zero regressions across all 88 test targets via `tools/run_affected_tests.ps1 -All`.

---

## 4-Gate Execution Roadmap

| Gate | Title | Deliverables | Success Criteria |
|---|---|---|---|
| **Gate 1** | WGSL INT8 Kernels & Parity | WGSL `geglu_int8_fwd` & `down_proj_int8_fwd`, `scratch/verify_wgsl_int8_gemv.car` | Numerical parity with CPU INT8 AVX2 ($\max|\Delta| < 10^{-4}$) |
| **Gate 2** | Full-VRAM Layer Allocation | `cartan_transformer_mount_gpu_resident_int8()`, persistent VRAM buffers & bind groups | 42 layers (3.73 GB) resident in 8GB VRAM |
| **Gate 3** | Decode Pipeline Integration | Wire GPU INT8 dispatch into `cartan_manifold_layer_forward_native` | Single-layer decode latency $< 0.8$ ms |
| **Gate 4** | Live Model Benchmarks & QA | Live `bin/geomind.exe` chat, full regression suite | 15–25+ tok/s decode, 88/88 test targets pass |
