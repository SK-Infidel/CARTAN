# Startup Code Review: Sprint 507 — Real-Time Fluid Streaming & AVX2-VNNI Acceleration

**Review Date**: October 1, 2026  
**Reviewers**: Antigravity Core & Specialized Engineering Squads  
**Target Codebases**: `src/std/transformer.cl`, `src/cartanc/llvm_codegen.car`, `test/geomind/chat.cl`, `test/geomind/main.car`  

---

## 1. Executive Summary & Context Alignment
In Sprint 506, prompt prefill latency was slashed from 159s down to 1.419s (a 52.2x speedup), and the LM Head projection latency dropped to 38 ms (a 36.9x speedup). All 88 regression suite targets passed cleanly with 0 failures.

However, single-token autoregressive decode remains at 2.22 tokens/second (~407 ms per token: 367 ms 42-layer manifold sweep + 39 ms LM head + 1 ms sampling). The resulting terminal output appears word-by-word with a noticeable 400 ms pause between each word.

This startup code review identifies the exact mathematical and hardware bottlenecks across the execution pipeline, develops the project dependency graph, logs identified technical debt into `ISSUES.md`, and specifies the technical roadmap for Sprint 507.

---

## 2. In-Depth Codebase Audits & Discovered Bottlenecks

### A. Scalar RMSNorm Sum-of-Squares in `src/std/transformer.cl`
- **Location**: `src/std/transformer.cl` lines 1800-1815, 1885-1891, 1938-1943, 2036-2042, 2054-2060, 2074-2080, 2103-2109.
- **Problem**: In every single-token decode step, `sum_sq` for Pre-Attention RMSNorm, Q-Norm, K-Norm, V-Norm, Post-Attention RMSNorm, Pre-FFN RMSNorm, Post-FFN RMSNorm, and PLE RMSNorm is evaluated using scalar `while (d < dim) { sum_sq = sum_sq + v * v; d = d + 1.0; }` loops over 2,560 elements.
- **Impact**: Across 42 layers, this executes $42 \times 5 = 210$ scalar loops per token ($537,600$ scalar operations) that could run in 80 SIMD vector cycles using our 4-way ILP `@cartan_simd_dot_f32`.
- **Logged as**: [ISSUE-353].

### B. Scalar Row Iteration in Batched Thread Pool Ops (`op == 3, 4, 5`)
- **Location**: `src/std/transformer.cl` lines 1270-1332 (`cartan_trans_pool_worker_main`) and lines 1520-1610 (`cartan_trans_pool_dispatch_batch`).
- **Problem**: While `op == 1.0` (GeGLU gate/up) and `op == 2.0` (GEMV down/Wo) have 4-way unrolling in both worker threads and thread 0, `op == 3.0` (batched GeGLU), `op == 4.0` (batched Q/PLE projection), and `op == 5.0` (batched dual K/V projection) execute single-row increment loops (`r = r + 1.0;`), causing instruction stalls and inefficient memory prefetching.
- **Logged as**: [ISSUE-354].

### C. Physical DDR5 Memory Bandwidth Wall (The Root Cause of 2.2 tok/s)
- **Physics**: In single-token decode ($N = 1$), 42 layers in FP32 require reading $16.8\text{ GB}$ of weights per generated token. At dual-channel DDR5 bandwidth (~48 GB/s), the physical minimum time to stream weights is $16.8 / 48 = 350\text{ ms}$. Our current engine completes in 367 ms (95.4% of physical bus capacity).
- **Solution Path**:
  1. INT8 quantization compresses 16.8 GB to 3.9 GB. Over DDR5, streaming 3.9 GB takes $\approx 85\text{ ms}$, unlocking 7–9 tok/s on CPU.
  2. Over the RTX 2000 Ada GDDR6 bus (224 GB/s), streaming 3.9 GB takes $\mathbf{17.4\text{ ms}}$, unlocking 18–25+ tok/s.
- **Logged as**: [ISSUE-355].

### D. Discrete Word-by-Word Output Cadence
- **Location**: `test/geomind/chat.cl` lines 2442-2450.
- **Problem**: Entire BPE tokens are printed as blocks after each 400 ms step, creating a chunky staccato visual cadence instead of a smooth fluid character stream.
- **Logged as**: [ISSUE-356].

---

## 3. Logical Dependency Tree

```
┌─────────────────────────────────────────────────────────────┐
│ Compiler Core: src/cartanc/llvm_codegen.car                │
│ - @cartan_simd_dot_f32 (AVX2 4-Way ILP)                    │
│ - @cartan_simd_dot_i8_f32 (VNNI / INT8 dot product)        │
└──────────────────────────────┬──────────────────────────────┘
                               │ Compiles Runtime & Stdlis
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ Standard Library Engine: src/std/transformer.cl             │
│ - cartan_init_transformer_scratch_buffers (Pinned Arena)    │
│ - cartan_trans_pool_dispatch (Multi-threaded GEMVs)         │
│ - cartan_manifold_layer_forward_native (Single-token decode)│
│ - cartan_manifold_layer_forward_batch (Batched prefill)     │
└──────────────────────────────┬──────────────────────────────┘
                               │ Consumed by Model Driver
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ High-Level Engine: test/geomind/chat.cl & main.car         │
│ - geomind_warm_all_layer_buffers (Eager faulting)           │
│ - geomind_execute_manifold_sequence_prefill                 │
│ - geomind_execute_manifold_decode_step                      │
│ - geomind_chat_generate_reply_multimodal (Paced streaming)  │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Zero-Mock & Rule Compliance Audit
- All buffers, SIMD instructions, dot products, and token outputs are 100% authentic.
- No simulated latency delays or stubbed matrix operations.
