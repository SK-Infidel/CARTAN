# Sprint 522 Plan: Full 42-Layer GPU VRAM Resident INT4 Pipeline & Async Staging

## Mission Statement
Achieve sub-500ms autoregressive decode latency across all 42 transformer layers by mounting the entire 1.87 GB INT4 manifold into physical GPU GDDR6 VRAM (NVIDIA RTX 2000 Ada), executing GeGLU and Down projections via branchless vectorized WGSL compute shaders, and resolving [`[ISSUE-372]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md) via ping-pong double-buffered staging buffers.

---

## Architectural Gates

### Gate 1: Double-Buffered Staging Architecture (`src/std/wgpu.cl`)
- Implement ping-pong double-buffered staging buffers (`g_wgpu_staging_buf_0`, `g_wgpu_staging_buf_1`) and active buffer toggle.
- Overlap command buffer execution and staging copy operations to eliminate synchronous CPU stalling.
- Mark `[ISSUE-372]` resolved upon empirical verification.

### Gate 2: INT4 WGSL Compute Kernels (`src/std/transformer.cl`)
- Implement `geglu_int4_fwd` and `down_proj_int4_fwd` compute shaders in WGSL:
  - Vectorized 4-bit unpacking using `unpack4x8unorm` and branchless `select(v, v - 16.0, v >= 8.0)`.
  - Swizzle unpacked even/odd weights to match activation layout: $(w_0, w_1, w_2, w_3)$ and $(w_4, w_5, w_6, w_7)$.
  - Exact float dot products with FMA.
- Implement corresponding global-attention variants for layers where $l \equiv 5 \pmod 6$.
- Create compute pipelines and pre-create persistent bind groups.

### Gate 3: 42-Layer VRAM Mounting & Runtime Routing (`src/std/transformer.cl`, `test/geomind/chat.cl`)
- Implement `cartan_transformer_init_gpu_resident_int4`.
- Implement `cartan_transformer_upload_gpu_resident_layer_int4` uploading 46.6 MB / layer to GPU storage buffers.
- Implement `cartan_transformer_dispatch_gpu_layer_int4` in `cartan_manifold_layer_forward_native` when `is_int8 == 2.0`.
- Update `geomind_mount_gpu_resident_layers` in `test/geomind/chat.cl` to mount all 42 INT4 layers into VRAM at startup.

### Gate 4: Empirical Verification & Regression Testing
- Benchmark single-layer and full 42-layer decode latency via `scratch/bench_single_decode_step.car`.
- Verify live prompt inference on `bin/geomind.exe`.
- Run compiler regression suite (`tools/run_affected_tests.ps1`).
- Update `CHANGELOG.md`, `ISSUES.md`, and `docs/ROADMAP.md`.
