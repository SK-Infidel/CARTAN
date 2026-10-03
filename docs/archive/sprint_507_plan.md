# Sprint 507 Plan: Real-Time Fluid Streaming & AVX2-VNNI Acceleration

## Sprint Goal
Deliver fluid real-time character streaming in `geomind.exe`, vectorize all layer RMSNorm computations via 4-way ILP SIMD, unroll batched thread pool kernels, and lay the compiler and runtime foundation for INT8 weight streaming.

---

## 4 Technical Gates

### Gate 1: Vectorized RMSNorm via `@cartan_simd_dot_f32`
- **Component**: [`src/std/transformer.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/transformer.cl) -> `cartan_manifold_layer_forward_native`
- **Scope**: Replace scalar `sum_sq` accumulation across Pre-Attention RMSNorm, Q-Norm, K-Norm, V-Norm, Post-Attention RMSNorm, Pre-FFN RMSNorm, Post-FFN RMSNorm, and PLE RMSNorm with `@cartan_simd_dot_f32(ptr, ptr, dim)`.
- **Impact**: Eliminates 210 scalar loops (537,600 scalar cycles) per generated token across all 42 layers.

### Gate 2: 4-Way Loop Unrolling in Batched Thread Pool Ops
- **Component**: [`src/std/transformer.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/transformer.cl) -> `cartan_trans_pool_worker_main`, `cartan_trans_pool_dispatch_batch`
- **Scope**: Apply 4-way row unrolling to `op == 3.0` (batched GeGLU), `op == 4.0` (batched Q/PLE projection), and `op == 5.0` (batched dual K/V projection) across workers 1..7 and thread 0.
- **Impact**: Saturates execution units and improves L1 cache prefetching during sequence prefill.

### Gate 3: Smooth Sub-Token Character-Stream Rendering
- **Component**: [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl) -> `geomind_chat_generate_reply_multimodal`
- **Scope**: Implement `geomind_print_token_fluid(token_id)` that emits characters with non-blocking flushes and smooth terminal pacing, eliminating the blocky, staccato word-by-word visual cadence.

### Gate 4: Compiler Core INT8 Dot Product Kernel (`@cartan_simd_dot_i8_f32`)
- **Component**: [`src/cartanc/llvm_codegen.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car)
- **Scope**: Add `@cartan_simd_dot_i8_f32(i8_row_ptr, f32_in_ptr, scale, count)` emitting AVX2 `vpmaddubsw` / `vpmaddwd` / `vpaddd` / `vcvtdq2ps` instructions. Rebuild compiler through 3-stage bootstrap fixpoint.

---

## Verification Criteria
1. Single-token decode step latency in `geomind.exe` drops from 407 ms.
2. Prefill latency for standard prompt drops $< 1.0\text{ second}$.
3. Text generation on terminal streams smoothly character-by-character.
4. Compiler regression suite passes 88/88 targets with zero failures.
5. Strict zero-mock compliance maintained across all operations.
