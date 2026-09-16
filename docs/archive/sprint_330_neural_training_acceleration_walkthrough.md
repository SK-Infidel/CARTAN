# Sprint 330 Walkthrough: Pure Direct Pointer Vectorization & High-Throughput Manifold Training Engine

## 1. Overview & Objectives
During prolonged Stage 1 Cloze training (`--train-cloze`), execution throughput degraded to ~640 bytes/second (~20 hours/epoch). Sprint 330 implemented direct pointer vectorization, cache-aligned row-major inner loops, direct C math externs, and decoupled checkpoint writes to accelerate training throughput while preserving memory stability.

## 2. Root Cause Analysis
1. **Scalar Call Frame Explosion**: `cartan_tensor_train_step` executed $512 \times 512 = 262,144$ loop iterations per token for forward matrix multiplication and another 262,144 iterations for backward SGD updates, generating >1.31 million function calls (`cartan_vec_get_f32`, `cartan_vec_set_f32`) per token. Across a 256-byte chunk (~200 tokens), this produced >260 million call frames per chunk.
2. **Cache Line Striding**: The forward pass looped over columns outer and rows inner, indexing $W[r \times 2560 + c]$. In the inner loop, $r$ incremented by 1, jumping memory by 20,480 bytes per iteration, thrashing the CPU L1/L2 data cache on every step.
3. **Redundant Math Function Wrappers**: In `e8_attention_engine.cl`, 16 layers $\times$ 2560 dims called `math_tanh` twice (81,920 calls per token) through standard library wrappers.
4. **Excessive Disk Flushing**: The steady-state trainer flushed the entire 52.4 MB binary checkpoint every 100 chunks (~every 40 seconds), generating ~94 GB of disk writes per epoch and stalling training execution.

## 3. Key Changes Made
- **`test/geomind/train.cl`**:
  - Replaced scalar `cartan_vec_get_f32` and `cartan_vec_set_f32` in `cartan_tensor_train_step` with native direct pointer indexing (`ptr[2.0 + idx]`).
  - Inverted forward matrix-vector dot product loop ($r$ outer, $c$ inner), accessing matrix memory with contiguous stride-1 locality.
  - Precomputed error delta vector $\Delta[c]$ in `g_train_logits` and restructured backward gradient updates to row-wise contiguous FMA operations with hoisted weight decay factors ($W \leftarrow W \times (1 - \eta \lambda) - \eta H_r \Delta_c$).
  - Decoupled 52.4 MB checkpoint writes from 100 to 2,500 chunks while retaining manifest logging every 500 chunks.
- **`test/geomind/e8_attention_engine.cl`**:
  - Converted `cartan_tensor_rmsnorm` and `e8_attention_forward_step_with_momentum` to direct pointer reads/writes.
  - Hoisted invariant dimension lookups and replaced wrapper calls with direct externs `sqrt` and `tanh`.
- **`test/geomind/chat.cl`**:
  - Replaced scalar calls in `cartan_tensor_update_autoregressive_state` with direct pointer reads/writes on `h[2.0 + i]`.
- **`test/geomind/streams.cl` & `test/geomind/moe.cl`**:
  - Converted `geomind_streams_manifold_forward_routed` (all 8 Lie submanifolds) and `geomind_sasaki_stream_routing` to direct pointer indexing.

## 4. Empirical Verification
1. **Compilation**: Built `cartanc.exe` and `geomind.exe` with zero errors, compiling down to `-O3 LTO Vectorized Pass Pipeline`.
2. **Regression Test Suite**: Executed all 62 compiler snapshot test targets (`build/run_tests.exe`) with **100% pass rate (62/62 PASS)**.
3. **Live Training Telemetry**:
   - Training resumed cleanly from manifest offset `204800.0` on dataset 4 (`mined_expanded_corpus_cloze_part04.jsonl`).
   - Throughput measured at ~2,500 bytes/second (4x acceleration).
   - Loss converged steadily: `3.15073 -> 3.02174 -> 3.01737`.
   - Process memory remained flat and stable: **111.58 MB WorkingSet / 113.23 MB Private Commit** (0 MB leak).
4. **Issue Tracking**: Recorded and marked `[ISSUE-079]` as FIXED in `ISSUES.md`. Updated `CHANGELOG.md` for version `8.287.0`.
