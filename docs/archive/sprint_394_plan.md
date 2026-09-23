# Sprint 394 Implementation Plan: Training Pipeline & Architectural Decoupling

## Core Mission & Objectives
Resolve the structural failures identified in `[ISSUE-142]`:
1. **Eliminate Cross-Domain Recurrent Context Bleed**: Implement a 10-domain persistent hidden state array (`domain_hidden_states` in VRAM and host) so each dataset resumes its own deep recurrent context across cycles without poisoning unrelated domains.
2. **True 1-Chunk Interleaved Mixture Streaming**: Set `slice_limit = 1.0` to cycle $D_0 \to D_1 \to \dots \to D_9$ on every single chunk, turning coarse 50-chunk clumping into a true balanced training mixture.
3. **Quench Temperature Resonant Oscillator**: Lock training temperature $T = 1.0$ during gradient updates; decouple validation temperature from single-slice variance, restoring mathematical gradient stability.
4. **Decouple Input Embedding Table from Output LM Head (Weight Decoupling Phase 1)**: Separate $W_{\text{in}} \in \mathbb{R}^{2560 \times 2560}$ (token input projections) from $W_{\text{head}} \in \mathbb{R}^{2560 \times 2560}$ (output unembedding projection), ending destructive gradient interference.

---

## Detailed Technical Design

### 1. Multi-Stream Persistent Context Memory (`domain_hidden_states`)
* **Current Bug**: `g_has_prev_chunk_h` persists the terminal state of Domain $k$ directly into Domain $k+1$.
* **Fix**:
  - Allocate a multi-domain hidden state buffer in VRAM: `g_buf_domain_h` of size $10 \times 2560 \times 4\text{ bytes} = 102.4\text{ KB}$.
  - Maintain a tracking vector `g_domain_has_prev[10]`.
  - On starting chunk for domain $d$:
    - If `g_domain_has_prev[d] == 1.0`, copy `g_buf_domain_h[d * 2560]` into `g_buf_train_hidden`.
    - Else, zero out `g_buf_train_hidden` (clean cold start).
  - On completing chunk for domain $d$:
    - Copy terminal state from `g_buf_prev_chunk_h` into `g_buf_domain_h[d * 2560]`.
    - Set `g_domain_has_prev[d] = 1.0`.
  - When domain $d$ reaches EOF or wraps around, clear `g_domain_has_prev[d] = 0.0`.

### 2. True 1-Chunk Interleaving
* **Current Bug**: `slice_limit = 50.0` trains 12,800 contiguous tokens per domain before rotating, causing catastrophic domain forgetting and single-domain telemetry variance.
* **Fix**:
  - Set `slice_limit = 1.0`.
  - Every chunk trained rotates round-robin across all available datasets.
  - Telemetry logs every 50 chunks reflect a balanced multi-domain composite (exactly 5 chunks from each of the 10 domains).

### 3. Temperature Oscillator Quenching
* **Current Bug**: Single-slice $val\_gap$ swings drive `TTemp` up to $1.09$, scaling loss and backprop gradients by $1/T$ in an active noise feedback loop.
* **Fix**:
  - Enforce `g_train_temperature = 1.0` during training steps.
  - `g_val_temperature` calibrated strictly by the multi-sample holdout validation pass (`geomind_compute_validation_loss`) evaluated on cycle boundaries, not on volatile single-chunk probes.

### 4. Input Embedding & Output Head Decoupling
* **Current Bug**: `g_cortical_weights` ($2560 \times 2560$) is tied across input embeddings, recurrent dynamics, and the output LM head.
* **Fix**:
  - Allocate `g_buf_embedding_weights` ($2560 \times 2560 \times 4\text{ bytes} = 26.21\text{ MB}$) and `g_buf_head_weights` ($2560 \times 2560 \times 4\text{ bytes} = 26.21\text{ MB}$).
  - Initialize both from the current checkpoint so weights smoothly specialize without losing pretrained knowledge.
  - In `geomind_autoregressive_step`, read embeddings from `g_buf_embedding_weights`.
  - In `geomind_gemv_forward` and `geomind_sgd_backward`, operate on `g_buf_head_weights`.
  - In `geomind_streams_backward`, update `g_buf_embedding_weights`.
  - Save both tensors in the safetensors checkpoint (`model.w_in` and `model.w_head`, with fallback loading).

---

## Verification & Acceptance Criteria
- [ ] Clean compilation via `cartanc.exe` targeting native Zig/Clang `-O3` LTO.
- [ ] Bit-for-bit binary synchronization across `geomind.exe`, `test/geomind/geomind.exe`, and `bin/geomind.exe`.
- [ ] Verification that 4/4 semantic vector analogies pass cleanly at Rank 1.
- [ ] Telemetry confirms smooth 1-chunk interleaving across all 10 datasets with zero cross-domain context contamination.
- [ ] Temperature is locked at $1.0$, completely eliminating gradient oscillation.
- [ ] Implementation plan, task list, and walkthrough saved to repo archive `docs/archive/`.
- [ ] `CHANGELOG.md` and `ISSUES.md` updated.
