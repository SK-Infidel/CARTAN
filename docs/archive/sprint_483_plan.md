# Sprint 483 Plan: Native CARTAN Self-Hosting — Inline F32 Vectorization, Compiler Intrinsic SIMD & Pure CARTAN Transformer Kernels

## 1. Context & Motivation
Rick directed the team to dissolve the re-emerging two-language problem:
> *"Every time it happens it's an opportunity to advance cartan. So yes. Let's go ahead and add the features we need in cartan to port these files to native cartan code, integrate those externs into the files that called them as native cartan code, and get the language self-hosting again."*

Currently, `c_cartan_gemma_layer_forward_fast` and `c_cartan_compute_lm_head_softcap` in `src/std/cartan_native_io.c` bypass CARTAN's compiler. In Sprint 483, we equip `cartanc.exe` with the exact optimization features needed for lightning-fast linear algebra in pure CARTAN, and port the decoder and LM head into pure `.cl` / `.car` files.

---

## 2. Architecture & Design Specifications

### A. Compiler Core Optimizations (`src/cartanc/llvm_codegen.car`)
1. **Alwaysinline Attributes on Float32 Primitives**:
   Add `alwaysinline` to `@cartan_f32_at` and `@cartan_set_f32` in LLVM IR definitions. This allows LLVM's optimizer and loop vectorizer to see the memory operations in-place without function call overhead.
2. **Native Vectorized SIMD Dot Product Intrinsic**:
   Define `cartan_simd_dot_f32(ptr %p1, ptr %p2, double %count) -> double` directly in `llvm_codegen.car`. Emits an 8-way unrolled `<8 x float>` vector loop compiling to native AVX2 `vfmadd231ps` instructions via Zig `-O3`.
3. **Native Zero-Copy Memory Map Function**:
   Provide `cartan_mmap_file(path: string) -> ptr` in standard runtime, allowing pure CARTAN to memory-map layer files and embedding tables directly.

### B. Pure CARTAN LM Head Soft-Cap Kernel (`test/geomind/chat.cl`)
- Reimplement `cartan_tensor_compute_lm_head_logits` in pure CARTAN utilizing `cartan_simd_dot_f32`:
  ```cl
  let dot = cartan_simd_dot_f32(h_raw, row_ptr, 2560.0);
  let capped = 30.0 * tanh(dot / 30.0);
  ```
- Eliminate `c_cartan_compute_lm_head_softcap` extern completely.

### C. Pure CARTAN 42-Layer Decoder Pipeline (`src/std/transformer.cl`)
- Implement `cartan_gemma_layer_forward_native` in pure CARTAN:
  - Pre-attention RMSNorm via pure CARTAN.
  - $Q, K, V$ GEMV projections via `cartan_simd_dot_f32`.
  - Split-half RoPE via pure CARTAN.
  - GQA causal attention using contiguous slice pointers.
  - GeGLU MLP with `cartan_simd_dot_f32`.
  - Authentic PLE context projection and gating in pure CARTAN.
- Eliminate `c_cartan_gemma_layer_forward_fast` extern completely.

### D. Empirical Verification & Self-Hosting Proof
1. Recompile `cartanc.exe` with the updated compiler.
2. Recompile `geomind.exe` with the new pure CARTAN pipeline.
3. Verify chat generation: `"The capital of Iran is **Tehran**."`.
4. Run compiler regression test suite.
