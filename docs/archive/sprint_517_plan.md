# Implementation Plan - Sprint 517: High-Throughput Batched Sequence Prefill & WebGPU Forward Acceleration

## 1. Objective & Problem Statement
During sequence prefill for prompt ingestion (e.g., 38 tokens), `cartan_manifold_layer_forward_batch` in `src/std/transformer.cl:2868-2878` falls back to a scalar token-by-token loop when `is_int8 == 1.0`, invoking `cartan_manifold_layer_forward_native` 1,596 times. This repeatedly streams 93 MB INT8 weights over DDR5 channels (reading 148.4 GB redundant data per prompt) and performs 1,596 synchronous PCIe buffer writes and staging map polls, causing a 49.3-second prefill freeze and fan thrashing.

Our goal in Sprint 517 is to eliminate this bottleneck by:
1. Implementing high-throughput Row-Outer INT8 Tensor Dispatch (Ops 9.0, 10.0, 11.0) in `cartan_trans_pool_worker_main` and `cartan_trans_pool_dispatch_batch_int8`.
2. Refactoring `cartan_manifold_layer_forward_batch` to execute the full neural forward sequence natively in batched INT8 (Pre-Norm $\to$ Batched Q/K/V $\to$ QK-Norm/RoPE $\to$ KV Cache append $\to$ Causal Attention $\to$ Batched W_o $\to$ Pre-FFN Norm $\to$ Batched GeGLU $\to$ Batched Down $\to$ Residual & PLE).
3. Ensuring bit-accurate numeric parity and zero regressions across the compiler test suite and live model inference.

## 2. Proposed Changes & Architecture

### A. Worker Thread Pool Extensions (`src/std/transformer.cl`)
- **Op 9.0 (Single INT8 GEMV across $N$ tokens)**:
  - Used for Q projection, Output projection ($W_o$), Down projection, and PLE Gate/Proj.
  - Outer loop iterates over rows $r \in [\text{start\_row}, \text{end\_row}]$ with 4-way unrolling.
  - Loads row weights and scales into L1 cache once.
  - Inner loop computes dot product `@cartan_simd_dot_i8_f32` against all $N$ prompt tokens.
  - Stores result into `out_mat` with stride `out_stride`.
- **Op 10.0 (Dual INT8 GEMV across $N$ tokens)**:
  - Used for K and V projections simultaneously.
  - Loads $K$ and $V$ rows into L1 cache once.
  - Inner loop evaluates dot products against all $N$ tokens and stores into `out_k` and `out_v`.
- **Op 11.0 (INT8 GeGLU across $N$ tokens)**:
  - Used for Gate and Up projections fused with `cartan_fast_gelu_tanh` activation.
  - Computes $\text{GELU}(d_g) \times d_u$ for all $N$ tokens in inner loop.
- **Dispatch Helper `cartan_trans_pool_dispatch_batch_int8`**:
  - Partitions rows across 8 threads and executes thread 0 locally.
  - Employs low-latency spin-wait (`SwitchToThread`) to synchronize worker tasks.

### B. Batched INT8 Pipeline in `cartan_manifold_layer_forward_batch` (`src/std/transformer.cl`)
- Compute `q_scales`, `w_q_bytes`, `k_scales`, `w_k_bytes`, `v_scales`, `w_v_bytes`, `o_scales`, `w_o_bytes`, `gate_scales`, `w_gate_bytes`, `up_scales`, `w_up_bytes`, `down_scales`, `w_down_bytes`, `ple_gate_scales`, `w_ple_gate_bytes`, `ple_proj_scales`, `w_ple_proj_bytes` using canonical byte offsets.
- Replace fallback loop with unified batched INT8 pipeline:
  1. Batched Pre-Attention RMSNorm across all $N$ tokens.
  2. Batched Q GEMV (Op 9.0).
  3. Batched K & V Dual GEMV (Op 10.0) when `is_kv_shared == 0.0`.
  4. Per-head Q-Norm, RoPE rotation, and KV-cache write across sequence positions.
  5. Causal GQA Attention across $N$ tokens.
  6. Batched $W_o$ GEMV (Op 9.0).
  7. Post-Attention RMSNorm + Residual + Pre-FFN RMSNorm for all $N$ tokens.
  8. Batched GeGLU (Op 11.0) and Batched Down projection (Op 9.0).
  9. Post-FFN RMSNorm + Residual.
  10. Batched PLE Gate GEMV (Op 9.0) + Tanh GELU + PLE Proj GEMV (Op 9.0) + Residual & Layer Scalar.

## 3. Empirical Verification Plan
1. Recompile compiler & runtime tests: `cartanc.exe test/compiler_suite/run_tests.car`.
2. Run affected tests: `tools/run_affected_tests.ps1 -Auto` (Targets 1, 2, 3, 4, 5, 58, 82, 86).
3. Benchmark prefill latency: Compile `geomind.exe` and test prompt inference with timing instrumentation.
4. Verify prefill drops from 49.3s to < 500 ms with bit-accurate token generation.
