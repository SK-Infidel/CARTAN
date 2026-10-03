# Startup Code Review & Logical Dependency Tree — Sprint 508
**Sprint Goal**: Implement Host-RAM INT8 AVX2 SIMD Engine (`@cartan_simd_dot_i8_f32`), Quantize 42 Manifold Layers (16.8 GB -> 4.0 GB), and Accelerate Single-Token Decode to 7–9+ tok/s.

---

## 1. Logical Dependency Tree

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Compiler Core Primitive (`src/cartanc/llvm_codegen.car`) │
│    - @cartan_simd_dot_i8_f32                                │
│    - 4-way ILP unrolling (32 bytes/iter)                     │
│    - sext <8 x i8> -> sitofp -> fmul/fadd FMA -> scale mul  │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Compiler Regression Target 82 Validation                 │
│    (`test/compiler_suite/test_compiler_simd_tensor_math.car`)│
│    - Verification against pure scalar dot product           │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Offline INT8 Quantizer (`tools/quantize_manifold_int8.car`)│
│    - Read 42 FP32 layers (16.1 GB)                          │
│    - Per-row symmetric dynamic range scaling:               │
│      scale[r] = max(|W[r, :]|) / 127.0                      │
│    - Output manifold_layer_{i}_int8.bin (4.0 GB total)       │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Runtime & Transformer Engine (`src/std/transformer.cl`)  │
│    - Add INT8 GEMV support to worker pool & dispatch        │
│    - Implement cartan_manifold_layer_forward_int8           │
│    - Read 1 byte/weight instead of 4 bytes/weight over DDR5 │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Full Inference & Live Chat (`test/geomind/chat.cl`)      │
│    - Auto-detect and warm INT8 layer checkpoints            │
│    - Live prompt benchmark: prefill + 7-9 tok/s decode      │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Component Audits & Potential Pitfalls

### A. Compiler Core (`src/cartanc/llvm_codegen.car`)
- **Review Findings**:
  - `@cartan_simd_dot_f32` currently unrolls 4 vectors (32 floats = 128 bytes) using 4 independent accumulators (`%vacc0..%vacc3`).
  - `@cartan_simd_dot_i8_f32` can process 32 elements per iteration from only **32 bytes** of weight data!
  - AVX2 instructions:
    - `vpmovsxbd` loads 8 signed bytes and sign-extends to 8 32-bit integers (`<8 x i32>`).
    - `vcvtdq2ps` converts `<8 x i32>` to `<8 x float>`.
    - `vfmadd231ps` performs FMA with the loaded `<8 x float>` activation vector.
  - Scaling:
    - Since `scale` is per-row, the entire vector dot-product sum is accumulated in integer or unscaled float, and multiplied by `scale` once at the end!
    - This saves thousands of float multiplications and eliminates quantization rounding drift.
  - Bootstrap Safety:
    - Adding `@cartan_simd_dot_i8_f32` as an inline emitted builtin requires registering the name in `self_ptr.declared_externs` and `func_return_types`.
    - Convergence must be verified via Stage 3 / Stage 4 SHA-256 fixpoint comparison.

### B. Manifold Layer Quantization (`tools/quantize_manifold_int8.car`)
- **Review Findings**:
  - Layer checkpoint structure contains 16 header floats and 9 large weight matrices (W_q, W_k, W_v, W_o, W_gate, W_up, W_down, W_ple_gate, W_ple_proj).
  - All normalization vectors (w_in_norm, w_q_norm, w_k_norm, w_post_attn, w_pre_ffn, w_post_ffn, w_ple_norm) total only ~60 KB per layer and must remain in full FP32 precision to prevent loss of signal in layer norms.
  - Each quantized matrix row stores:
    1. `float scale` (4 bytes per row)
    2. `int8 weights` (in_dim bytes per row)
  - Memory compression:
    - Layer 0: 372 MB (FP32) -> **94 MB (INT8)**!
    - 42 layers: 15.6 GB -> **3.95 GB**!
  - Fits comfortably within the 8 GB dedicated VRAM for Sprint 509 full-VRAM residency.

### C. Standard Library Runtime (`src/std/transformer.cl`)
- **Review Findings**:
  - `cartan_trans_pool_dispatch` and `cartan_trans_pool_worker_main` currently handle ops 1.0..6.0.
  - We can define `op == 7.0` (INT8 GEMV) and `op == 8.0` (INT8 GeGLU):
    - Reads row INT8 pointer and row scale pointer.
    - Executes `@cartan_simd_dot_i8_f32`.
  - Zero heap allocation per step. Zero mock policy strictly enforced.

---

## 3. Issues Identified for Sprint 508
- **[ISSUE-355]**: Physical DDR5 Bandwidth Ceiling in Autoregressive Single-Token Decode (16.8 GB FP32 limit at 2.8 tok/s). Resolving via INT8 quantization.
- **[ISSUE-359]**: Layer Checkpoint Quantization Format & Header Alignment.
