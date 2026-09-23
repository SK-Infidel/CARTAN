# Sprint 395 Implementation Plan: Causal Attention Backward, Hopfield Adjoint & Recurrent BPTT

## Core Mission & Objectives
Resolve the remaining critical flaws identified in `[ISSUE-142]`:
1. **Implement Causal MHA Backward Kernel (`geomind_causal_mha_backward`)**:
   - Differentiate causal multi-head self-attention over sequence history $[0..t]$.
   - Compute exact softmax Jacobian and query gradient $dq$, accumulating directly into hidden adjoint $dh$.
2. **Implement Continuous Hopfield Backward Kernel (`geomind_hopfield_backward`)**:
   - Differentiate the 8-attractor continuous Hopfield memory injection.
   - Project hidden adjoint through attractor space, computing exact softmax Jacobian and adjoint back into $dh$.
3. **Wire Real-Time BPTT Recurrent Credit (`geomind_accumulate_recurrent_dh`)**:
   - Accumulate `g_buf_step_dh_prev` from `geomind_streams_backward` into `dh` on step $t > 0$, eliminating dead gradient buffers.
4. **Complete Closed-Loop Gradient Path**:
   - Sequence the backward chain:
     $$\text{Head GEMV} \to \text{Post-RMSNorm} \to \text{Hopfield} \to \text{Causal MHA} \to \text{Post-FFN RMSNorm} \to \text{FFN Cascade} \to \text{Pre-FFN RMSNorm} \to \text{Streams Bwd} \to \text{BPTT}$$

---

## Detailed Technical Design

### 1. Continuous Hopfield Backward Pipeline (`g_pipe_hopfield_backward`)
* Kernel: `geomind_hopfield_backward`
* Local memory: `s_sim[8]`, `s_g[8]`, `s_p[8]`, `s_lambda[8]`.
* Computes:
  - $s_a = c (h \cdot A_a)$, $g_a = \gamma (dh \cdot A_a)$
  - Softmax probabilities $p_a = \text{softmax}(s)_a$, mean $\bar{g} = \sum p_a g_a$
  - $\lambda_a = c \cdot p_a (g_a - \bar{g})$
  - $dh_{\text{in}} = (1 - \gamma) dh + \sum_{a=0}^7 \lambda_a A_a$
* Bounded safely in $[-2.0, 2.0]$.

### 2. Causal MHA Backward Pipeline (`g_pipe_causal_mha_backward`)
* Kernel: `geomind_causal_mha_backward`
* Workgroups: 8 (one per head $h \in [0..7]$), 256 threads per group.
* Computes:
  - Exact attention weights $p_s = \text{softmax}\left(\frac{q \cdot K_s}{\sqrt{d}}\right)$ for $s \in [0..t]$
  - Adjoint inner product $u_s = 0.35 (dh \cdot K_s)$, $\bar{u} = \sum p_s u_s$
  - Softmax gradient $\frac{\partial L}{\partial a_s} = p_s (u_s - \bar{u})$
  - Query gradient $dq = \frac{1}{\sqrt{d}} \sum_{s=0}^t \frac{\partial L}{\partial a_s} K_s$
  - Accumulates $dh \leftarrow dh + dq$, bounded in $[-2.0, 2.0]$.

### 3. Recurrent BPTT Credit Kernel (`g_pipe_accumulate_recurrent_dh`)
* Kernel: `geomind_accumulate_recurrent_dh`
* Threads: 2560.
* On $t > 0$: $dh[i] \leftarrow dh[i] + 0.35 \times dh\_prev[i]$.
* On $t = 0$: clear `dh_prev` via `cartan_gpu_write_buffer(g_buf_step_dh_prev, ...)`.

---

## Verification & Acceptance Criteria
- [ ] Clean compilation with `cartanc.exe` targeting native Zig/Clang `-O3` LTO.
- [ ] Bit-for-bit binary hash parity across all three deployment targets (`geomind.exe`, `test/geomind/geomind.exe`, `bin/geomind.exe`).
- [ ] Verification that 4/4 semantic vector analogies continue to pass at Rank 1.
- [ ] Empirical confirmation that backward pass computes non-zero, stable gradients across Causal MHA and Hopfield steps.
- [ ] Walkthrough archived in `docs/archive/` and artifact generated.
- [ ] `CHANGELOG.md` and `ISSUES.md` updated.
