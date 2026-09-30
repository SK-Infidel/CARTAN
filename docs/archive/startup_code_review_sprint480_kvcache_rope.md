# Startup Code Review: Sprint 480 - Non-Euclidean KV-Cache, Split-Half RoPE Alignment & Pure Neural Inference

## 1. Executive Summary
- **Primary Goal**: Complete the transition from flat Euclidean weights to pure neural inference on GeoMind's Lie manifold architecture under `--no-expert-priming` with authentic multi-token sequence prefill and full 42-layer Gemma KV-caching.
- **Key Discovered Bugs & Stubs**:
  1. **RoPE Dimension Split Misalignment**: `cartan_rope_apply` in `src/std/transformer.cl` rotated adjacent interleaved pairs $(2k, 2k+1)$ (GPT-NeoX style) rather than split-half $(k, k + \text{half})$ (Google Gemma / HuggingFace `rotate_half`), scrambling query-key attention geometry for all tokens at $pos > 0$.
  2. **Silent KV-Cache Truncation**: CARTAN vectors (`cartan_vec_create`) allocate a fixed 65,536-byte buffer (capacity 8,190 doubles). Global Gemma layers ($kv\_dim=1024$) exceeded this limit after just 8 prompt tokens ($8 \times 1024 = 8,192$), silently dropping upper keys/values.
  3. **Pointer Unpacking Mismatch in C Externs**: In CARTAN, `cartan_tensor_alloc` produces arrays of `double` (elements at offset 2). Passing these pointers directly to `const float*` C arguments reads double bit patterns as floats, corrupting calculation.
- **Logical Dependency Tree**:
  - `src/cartanc/`: Compiler Core (`core_runtime.car`, `llvm_codegen.car`, `cartanc.exe`).
  - `src/std/cartan_native_io.c`: Native AVX2 SIMD kernels (`c_cartan_kv_cache_*`, `c_cartan_gqa_causal_attention_f32`, `c_cartan_compute_lm_head_softcap`).
  - `src/std/transformer.cl`: Transformer layer primitives (`cartan_rope_apply`, `cartan_gemma_layer_forward_raw`).
  - `test/geomind/chat.cl`: Multi-token sequence prefill, autoregressive decoding, tied-embedding LM head projection.
  - `test/geomind/main.car`: CLI entrypoint and `--ephemeral-memory` / `--no-expert-priming` dispatch.

## 2. Issues Logged
- **[ISSUE-288]**: Rotary Position Embedding (RoPE) Incompatible Split Format in `src/std/transformer.cl`.
- **[ISSUE-289]**: Silent Truncation in Causal Attention KV Caching Due to Fixed Vector Allocation.
- **[ISSUE-290]**: Missing Native Multi-Token Sequence Prefill and Pinned KV-Cache Arena for 42 Layers.

## 3. Implementation Directives
1. Update `cartan_rope_apply` in `src/std/transformer.cl` to implement exact split-half rotation:
   $x'_k = x_k \cos(\theta_k) - x_{k+\text{half}} \sin(\theta_k)$,
   $x'_{k+\text{half}} = x_{k+\text{half}} \cos(\theta_k) + x_k \sin(\theta_k)$.
2. Wire `c_cartan_kv_cache_append` and `c_cartan_gqa_causal_attention_f32` in `cartan_native_io.c` to accept CARTAN `double*` vector pointers, unpack data at offset 2, and execute 8-way unrolled AVX2 FMA causal attention.
3. Wire `cartan_gemma_layer_forward_raw` to use the native contiguous arena.
4. Verify end-to-end execution of `geomind.exe --chat` under `--no-expert-priming --ephemeral-memory`.
