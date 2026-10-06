# Startup Code Review: Sprint 527 — CPU Thread-Pool Optimization & Cortical Stream Calibration

**Date**: 2026-10-03  
**Reviewer**: Antigravity / CARTAN Core Team  
**Focus**: CPU Decode Latency, Thread-Pool Spin/Sleep Latency, and $W_{\text{in}} / W_{\text{out}}$ Lie Stream SVD Calibration.

---

## 1. Executive Summary & Objective

In Sprint 526, we resolved LM head latency ($52.4\text{ ms} \to 15.6\text{ ms}$) via stream domain vocabulary pruning. However, causal autoregressive decode remains bound at $\sim 1.3\text{ tok/s}$ ($\sim 750\text{ ms/tok}$). The remaining latency is consumed by sequential 42-layer execution in the CPU worker thread pool ($\sim 17\text{ ms}$ per layer $\times 42 = 714\text{ ms}$).

Physics dictates that streaming 51 MB of INT4 layer weights over dual-channel DDR5 ($60\text{ GB/s}$) should take $< 1\text{ ms}$ per layer. The $17\times$ latency inflation is caused by:
1. **Thread-Pool Spin/Sleep Jitter**: `Sleep(2.0)` in `cartan_trans_pool_worker_main` puts worker threads to sleep for $\ge 15.6\text{ ms}$ (Win32 timer quantum) between GEMV dispatches.
2. **Barrier Overhead**: 5 dispatches per layer $\times 42 = 210$ barriers per token, each experiencing spinlock stall.
3. **Uncalibrated Cortical Streams**: `geomind_single_stream_forward` applies raw rotations directly across 2560D channels without linear adapters, yielding 0% candidate acceptance in speculative decoding.

---

## 2. Logical Dependency Tree

```
test/geomind/main.car
 └── test/geomind/chat.cl
      ├── [Thread Pool Dispatch]
      │    └── src/std/transformer.cl (cartan_trans_pool_worker_main, cartan_trans_pool_dispatch)
      │         ├── src/cartanc/llvm_codegen.car (@cartan_simd_dot_i4_f32, @cartan_simd_dot_f32)
      │         └── Win32 SwitchToThread() / Sleep()
      ├── [Stream Execution & Drafting]
      │    ├── test/geomind/streams.cl (geomind_single_stream_forward)
      │    │    └── [NEW] geomind_stream_adapters.bin (W_in, W_out SVD projections)
      │    └── test/geomind/moe.cl (cartan_sasaki_brainstem_route_top1)
      └── [Vocabulary & Telemetry]
           └── test/geomind/trainingdata/checkpoints/geomind_stream_masks.bin
```

---

## 3. Detailed Component Audit

### A. Thread-Pool Worker Spin/Sleep Latency (`src/std/transformer.cl`)
- **Location**: `src/std/transformer.cl:1680-1700`
- **Issue**:
  ```cl
  spin = spin + 1.0;
  if (spin > 500000.0) {
      Sleep(2.0);
  } else {
      spin_yield = spin_yield + 1.0;
      if (spin_yield > 5000.0) {
          SwitchToThread();
          spin_yield = 0.0;
      }
  }
  ```
  On Windows, `Sleep(2.0)` yields the remainder of the 15.6 ms timeslice. When the master thread dispatches the next operation $20\ \mu\text{s}$ later, the worker thread is asleep, stalling the entire pipeline.
- **Remediation**:
  - Remove `Sleep(2.0)` from active decode spin loops. Use high-frequency spin with `SwitchToThread()` only after significant spin thresholds, and only sleep when `g_trans_pool_standby == 1.0` (interactive prompt wait).

### B. Cortical Stream $W_{\text{in}}, W_{\text{out}}$ Linear Projections (`test/geomind/streams.cl`)
- **Location**: `test/geomind/streams.cl:9-120`
- **Issue**:
  Each stream function (e.g. `stream_poincare_process`, `stream_spectral_process`) takes `x: ptr, dim: float` (2560) and applies non-linear rotations directly across the 2560 channels. Because the transformer latent space is trained end-to-end, arbitrary channel transforms warp semantics, yielding 0/75 acceptance.
- **Remediation**:
  - Compute SVD/PCA projection bases for each stream's domain token subspace from authentic Gemma 4 embeddings:
    $$W_{\text{in}}^{(s)} \in \mathbb{R}^{d_s \times 2560}, \quad W_{\text{out}}^{(s)} = (W_{\text{in}}^{(s)})^T \in \mathbb{R}^{2560 \times d_s}$$
  - Where $d_s$ matches the Lie algebra dimension:
    - Stream 0: $\mathfrak{so}(16) \implies d_0 = 120$
    - Stream 1: $\mathfrak{e}_7 \times \mathfrak{su}(2) \implies d_1 = 136$
    - Stream 2: $\mathfrak{e}_6 \times \mathfrak{su}(3) \implies d_2 = 86$
    - Stream 3: $\mathfrak{su}(9) \implies d_3 = 80$
    - Stream 4: $\mathfrak{f}_4 \times \mathfrak{g}_2 \implies d_4 = 66$
    - Stream 5: $\mathfrak{so}(10) \times \mathfrak{su}(4) \implies d_5 = 60$
    - Stream 6: $\mathfrak{su}(5)^2 \implies d_6 = 48$
    - Stream 7: $\mathfrak{su}(3)^3 \implies d_7 = 24$
  - Serialize to `geomind_stream_adapters.bin` ($\sim 13\text{ MB}$).
  - In `geomind_single_stream_forward`: project $2560 \to d_s$, apply Lie transformation in $d_s$, and project back $d_s \to 2560$.

---

## 4. Technical Debt & Issues Identified

- Register **[ISSUE-385]**: `Thread-Pool Sleep(2.0) Quantization Jitter & Uncalibrated Cortical Stream Latent Warping`.
- All changes must adhere strictly to zero-mock: genuine truncated SVD computation on authentic 2560D embedding table and genuine AVX2 matrix-vector multiplication.
