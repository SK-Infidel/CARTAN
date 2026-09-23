# Sprint 376 Walkthrough: 3-Tier Cognitive Hybrid Architecture for GeoMind

## Overview
Sprint 376 implements the 3-tier cognitive hybrid architecture to break through the ~4.26 nats pretraining entropy barrier:
1. **Tier 1 (Immediate Working Memory)**: Causal Multi-Head Self-Attention over intra-chunk sequence tokens ($T = 256$, $H = 8$ Lie heads, $d_h = 320$).
2. **Tier 2 (Fluid Narrative Stream)**: Dynamic Information Content (IC) selective gating ($\alpha_t \in [0.40, 0.90]$) and inter-chunk hidden state persistence (`g_buf_prev_chunk_h`).
3. **Tier 3 (Episodic Working Memory)**: Continuous modern Hopfield memory injection via 8 attractor basins ($\beta = 1.0$, $\gamma = 0.10$).

---

## Key Changes

### 1. OpenCL Compute Kernels & Pipelines ([`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl))
- **`geomind_causal_mha_step`**:
  - Dispatches 8 Lie heads ($H = 8$, head dimension $d_h = 320$) with 256 threads per workgroup ($8 \times 256 = 2,048$ total threads).
  - Evaluates causal dot-product attention over historical tokens $s \le t$ in sequence VRAM buffer `g_buf_chunk_seq_h`.
  - Performs local workgroup parallel reduction for numerically stable max subtraction and softmax normalization.
  - Injects attended context into hidden state with residual weight $+0.35$.
- **`geomind_save_seq_h`**:
  - Copies $h_t$ at step index $t$ directly into `g_buf_chunk_seq_h` ($256 \times 2560 \times 4$ bytes) in VRAM.
- **`geomind_hopfield_inject`**:
  - Computes inner products with 8 continuous Hopfield attractor basins in VRAM (`g_buf_hopfield_attractors`).
  - Evaluates log-sum-exp softmax partition function ($\beta = 1.0$) and blends associative resonance with $\gamma = 0.10$.
- **`geomind_autoregressive_step`**:
  - Accepts dynamic `float ic_weight` parameter.
  - Computes selective retention $\alpha = \text{clamp}(0.50 + 0.12 \times \text{IC}, 0.40, 0.90)$ so concept tokens persist while stop words reset fluidly.

### 2. Pipelined GPU Chunk Loop ([`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl))
- **Inter-Chunk Persistence**:
  - At chunk entry: If `g_has_prev_chunk_h == 1.0`, initializes `g_buf_train_hidden` from `g_buf_prev_chunk_h` instead of zeroing.
  - At chunk exit: Stashes final hidden vector into `g_buf_prev_chunk_h` and sets `g_has_prev_chunk_h = 1.0`.
  - On dataset boundaries and epoch transitions: Resets `g_has_prev_chunk_h = 0.0`.
  - In validation evaluation: Temporarily isolates `g_has_prev_chunk_h` so validation chunks evaluate independently without corrupting training continuity.
- **Intra-Chunk Execution Sequence**:
  - Step A: Stash $h_t$ via `g_pipe_save_seq_h`.
  - Step B: If $t > 0$, run Causal MHA via `g_pipe_causal_mha_step`.
  - Step C: Run Continuous Hopfield injection via `g_pipe_hopfield_inject`.
  - Step D: Forward GEMV $\to$ Fused Softmax/Loss $\to$ Reverse Randers Backprop $\to$ Selective Gating Autoreg $\to$ Pre-Norm $\to$ FFN Cascade $\to$ Post-Norm.

### 3. CPU Fallback Selective Gating ([`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl))
- Updated `cartan_tensor_update_autoregressive_state` to calculate $\alpha = \text{clamp}(0.50 + 0.12 \times \text{IC}(\text{tok}), 0.40, 0.90)$ matching the GPU kernel.

---

## Empirical Verification

### 1. Clean Compilation & Binary Synchronization
- Compiled with self-hosting compiler `cartanc.exe`:
  ```powershell
  .\cartanc.exe build test/geomind/main.car -o test/geomind/geomind.exe
  ```
- Bit-for-bit SHA-256 match across all deployment locations:
  - `test/geomind/geomind.exe`: `FBA3AD319908F246E346D5C96CDAA8244BA0F4885C95FFD2DBD37A4510A21625`
  - `bin/geomind.exe`: `FBA3AD319908F246E346D5C96CDAA8244BA0F4885C95FFD2DBD37A4510A21625`
  - `./geomind.exe`: `FBA3AD319908F246E346D5C96CDAA8244BA0F4885C95FFD2DBD37A4510A21625`

### 2. Semantic Analogy Verification
Ran `.\geomind.exe --eval-analogy`:
- **King - man + woman**: Rank 1 ` queen` (Sim: 0.4340, Margin: +0.0988) - **PASS**
- **he - him + her**: Rank 1 ` she` (Sim: 0.4955, Margin: +0.1085) - **PASS**
- **father - man + woman**: Rank 1 ` mother` (Sim: 0.5200, Margin: +0.0862) - **PASS**
- **boy - man + woman**: Rank 1 ` girl` (Sim: 0.5807, Margin: +0.2036) - **PASS**

### 3. Live GPU Training Run
Ran 1 epoch test across 100 chunks (5,710 steps) on NVIDIA RTX 2000 Ada GPU:
- Executed in $< 9$ seconds (> 630 steps/sec).
- Zero driver faults, zero hangs, zero NaNs/Infs.
- All 3 cognitive tiers dispatched cleanly back-to-back in GPU command queue.
