# Sprint 521 Plan: INT4 Weight Packing & SIMD Unpacking Engine

## Sprint Goal
Halve the neural weight memory footprint from 3.95 GB to ~1.98 GB and eliminate DDR5 bus saturation during autoregressive decode by implementing:
1. Native compiler LLVM IR intrinsic `@cartan_simd_dot_i4_f32` with branchless AVX2 arithmetic sign-extension unpacking.
2. High-precision symmetric W4A32 quantizer `tools/quantize_manifold_int4.car` emitting packed 4-bit checkpoint layer binaries.
3. Thread pool worker and decode pipeline dispatch (Ops 12, 13, 14) in `src/std/transformer.cl` and `test/geomind/chat.cl`.

---

## Architectural Gates

### Gate 1: Compiler Backend & SIMD Kernel
- In `src/cartanc/llvm_codegen.car`:
  - Define `define double @cartan_simd_dot_i4_f32(ptr %p1, ptr %p2, double %scale, double %count) alwaysinline`.
  - Process 32 weights per iteration by loading 16 packed bytes (`load <16 x i8>`).
  - Unpack low/high nibbles branchlessly via `ashr (shl %raw, 4), 4` and `ashr %raw, 4`.
  - Slices into 4 `<8 x float>` vectors accumulated into `%vacc0..3`.
  - Handle remaining scalar elements with individual nibble extraction.
  - Register `cartan_simd_dot_i4_f32` in `func_return_types` as `"double"`.
- In `src/cartanc/core_runtime.car`:
  - Declare `extern fn cartan_simd_dot_i4_f32(w_i4: ptr, x_f32: ptr, scale: float, count: float) -> float;`.
- Rebuild root compiler `cartanc.exe`.
- Verify mathematical parity against scalar FP32 reference in `scratch/test_dot_parity_i4.car` across multiple vector lengths.

### Gate 2: Offline W4A32 Quantizer
- Create `tools/quantize_manifold_int4.car`:
  - Symmetric per-row dynamic range scaling: $S = \max(|W_{r,:}|) / 7.0$.
  - Quantize float weights to $[-7, +7]$.
  - Contiguous pair packing: `byte[k] = (w0 & 0x0F) | ((w1 & 0x0F) << 4)`.
  - Format flag `hdr[11] = 2.0` (INT4 identifier).
  - Quantize test layers and verify file sizes are exactly 50% of INT8.

### Gate 3: Transformer Runtime & Multi-Threaded Dispatch
- In `src/std/transformer.cl`:
  - Support `hdr[11] == 2.0` (INT4 format).
  - Unpack layer buffer offsets for INT4 (half the byte size for all weight matrices).
  - Add thread pool ops:
    - Op 12.0: INT4 Single GEMV (Q, O, Ple_Proj)
    - Op 13.0: INT4 Dual GEMV (K/V parallel projection)
    - Op 14.0: INT4 GeGLU (Gate/Up parallel projection)
  - In `cartan_manifold_layer_forward_native`: dispatch to INT4 thread pool ops or call `cartan_simd_dot_i4_f32`.
- In `test/geomind/chat.cl`:
  - Support loading `manifold_layer_*_int4.bin` when available or requested.

### Gate 4: Empirical Testing, Regressions & Closeout
- Validate live prompt inference on `bin/geomind.exe`.
- Run compiler regression test suite (`tools/run_affected_tests.ps1`).
- Update `ISSUES.md`, `docs/ROADMAP.md`, `CHANGELOG.md`, and author `docs/archive/sprint_521_walkthrough.md`.
