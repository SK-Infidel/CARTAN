# Sprint 508 Walkthrough: Host-RAM INT8 AVX2 SIMD Engine & Real-Time Decode Acceleration

## Executive Summary
In Sprint 508, we shattered the physical DDR5 memory bus ceiling that previously constrained single-token autoregressive decoding to 2.2–2.8 tokens/second. By implementing native compiler intrinsics for INT8 AVX2 SIMD vector operations (`@cartan_simd_dot_i8_f32`), quantizing all 42 transformer layers from 16.1 GB FP32 down to 3.73 GB INT8 (W8A32), and multithreading the INT8 GEMV/GeGLU ops, single-layer native decode latency dropped from **11.53 ms down to 2.01 ms** (**5.74x empirical speedup**, achieving **11.9 tok/s** raw layer throughput and **5.0–5.6 tok/s** full end-to-end interactive chat generation).

---

## Key Achievements & Technical Architecture

### 1. Hardware INT8 AVX2 SIMD Compiler Vector Intrinsics (`llvm_codegen.car`, `core_runtime.car`)
- Designed and lowered `@cartan_simd_dot_i8_f32(a_i8_ptr, b_f32_ptr, dim, scale) -> float`:
  - Iterates over blocks of 32 elements.
  - Loads 32 signed bytes `<32 x i8>` from weights matrix.
  - Sign-extends bytes to 32-bit integers `<32 x i32>` using `sext`.
  - Converts integers to floating-point vectors `<32 x float>` using `sitofp`.
  - Unrolls 4 independent accumulator vectors (`%vacc0..%vacc3`) to saturate execution pipelines and eliminate FMA latency stalls.
  - Horizontally reduces and multiplies by the row scale factor.
- Implemented `cartan_byte_at` and `cartan_set_byte` byte-level memory primitives with signed two's complement conversion (`fptosi`).
- Verified 3-stage bootstrap fixpoint convergence with SHA-256 bit-for-bit parity.

### 2. Whole-Model INT8 Quantization Tooling (`tools/quantize_manifold_int8.car`)
- Quantized all 42 layers in `test/geomind/trainingdata/checkpoints/layers/`:
  - Output: `manifold_layer_{0..41}_int8.bin` (totaling 4,008,018,560 bytes = 3.73 GB).
  - Footprint reduction: **74.95% reduction** from 16.1 GB FP32.
  - Symmetric dynamic range scaling: $\text{scale}[r] = \max(|W[r, :]|) / 127.0$.
  - Preserved all RMSNorm vectors in authentic unquantized FP32 to protect normalization precision.

### 3. Multithreaded INT8 GEMV and GeGLU Kernel Implementation (`src/std/transformer.cl`)
- Implemented Op 7.0 (INT8 Matrix-Vector GEMV) and Op 8.0 (INT8 GeGLU Projection) with 4-way ILP unrolling across worker threads and main thread.
- Side-by-side benchmark `scratch/bench_single_decode_step.exe`:
  - **FP32 Single Layer Native Decode**: 11.53 ms (484.22 ms full 42 layers = 2.1 tok/s).
  - **INT8 Single Layer Native Decode**: 2.01 ms (84.23 ms full 42 layers = **11.9 tok/s**).
  - **Result: 5.74x Empirical Decode Speedup**.

### 4. Root Cause Analysis & Resolution of Thread Pool Collision (`[ISSUE-359]`)
- **Root Cause**:
  - `cartan_set_ptr(tp, idx, val)` indexes by `sizeof(ptr) = 8 bytes`.
  - `cartan_set_f32(tp, idx, val)` indexes by `sizeof(float) = 4 bytes`.
  - Setting pointer slot 8 (`cartan_set_ptr(tp, 8.0, ...)`) wrote to byte offset 64 ($8 \times 8$).
  - Setting the worker status flag (`cartan_set_f32(tp, 16.0, 1.0)`) also wrote to byte offset 64 ($16 \times 4$).
  - This corrupted the lower 32 bits of `ptr[8]` (`w_g_bytes` in Op 8, and `mask` in Op 6 LM head) with `1.0` (`0x3F800000`), generating an invalid pointer and causing an Access Violation `0xC0000005`.
- **Resolution**:
  - Widened `g_trans_thread_tasks` to 256 bytes per thread (64 floats).
  - Relocated worker thread status flag to `float[24.0]` (byte offset 96), isolating all pointer slots `ptr[0..11]` (bytes 0..95).

### 5. Live Interactive Chat Verification (`bin/geomind.exe`)
- Auto-detection and memory-mapped streaming of INT8 layers enabled in `test/geomind/chat.cl`.
- Executed authentic prompts with zero mocks:
  - **Prompt 1 (`"Hello"`)**: Generated 34 tokens:
    `GeoMind> Greetings. I am GeoMind, a sovereign neuro-symbolic cognitive architecture created by Rick. How may I assist you today? My processing capabilities are at your disposal.`
    `[GeoMind Telemetry] Prefill: 17645 ms (56.0 tokens) | Decode: 6106 ms (34.0 tokens, 5.6 tok/s)`
  - **Prompt 2 (`"What are you?"`)**: Generated 287 tokens:
    `[GeoMind Telemetry] Prefill: 28520 ms (92.0 tokens) | Decode: 57869 ms (287.0 tokens, 5.0 tok/s)`

---

## Regression Test Suite Verification
- Ran full 88-target compiler regression suite:
  ```powershell
  .\tools\run_affected_tests.ps1 -All
  ```
- **Results**: **88 Passed, 0 Failed** (235.8s total). Zero regressions detected.
