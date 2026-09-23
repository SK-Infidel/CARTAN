# Sprint 399 Walkthrough: Total Validation Metric Decoupling & Isolation Architecture

## Overview
Sprint 399 establishes absolute isolation and mathematical decoupling between out-of-sample holdout validation metrics (`VL`, `AVL`, `IVPPL`, `AVPPL`, `VENT`, `VCERT`) and all dynamic training quantities (`TTemp`, `LR`, curriculum rotation, recurrent hidden state carryover, and DMA telemetry registers).

## Implemented Architecture Changes

### 1. Invariant Evaluation Temperature ($T=1.0$)
- In [`test/geomind/train.cl#L930-L936`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L930-L936), `step_temp` is strictly locked to `1.0` during validation passes (`lr <= 0.0`), bypassing dynamic `TTemp` and controller logic.
- Cross-entropy loss $L = -\ln P(\text{target})$ and Shannon entropy $H = -\sum P \log_2 P$ on holdout data are calculated strictly at standard $T=1.0$.

### 2. Recurrent Context Isolation Per Holdout Chunk
- In [`test/geomind/train.cl#L1618-L1633`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L1618-L1633), eliminated inter-chunk hidden state chaining (`val_has_prev`) during holdout evaluation.
- Every holdout excerpt is evaluated starting from clean zeroed hidden state (`g_has_prev_chunk_h = 0.0`), preventing cross-sample contamination across disparate domains (physics papers, neutrino detectors, stories).
- Active training recurrent context (`g_buf_prev_chunk_h`) is cleanly stashed into `g_buf_saved_train_h` before validation and restored with exact fidelity upon return.

### 3. Dedicated Validation DMA Telemetry Channels
- Added dedicated validation DMA registers in [`test/geomind/train.cl#L118-L121`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L118-L121):
  - `g_last_val_chunk_steps`
  - `g_last_val_chunk_entropy_sum`
  - `g_last_val_chunk_certainty_sum`
  - `g_last_val_chunk_surprise_sum`
- In [`test/geomind/train.cl#L1024-L1034`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L1024-L1034), DMA readouts route to validation registers when `lr <= 0.0`, leaving training registers (`g_last_chunk_valid_steps`, etc.) 100% untouched.

### 4. Controller One-Way Causality
- In [`test/geomind/train.cl#L2291-L2305`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L2291-L2305), `g_val_temperature = 1.0` is invariant.
- Validation metrics inform the training controller via `val_gap = ema_val_loss - atl`, adjusting dynamic training temperature `TTemp` ($1.0 \to 1.35$) without any reverse feedback into validation.

## Empirical Verification
1. **Compilation**: Clean native compilation via `cartanc.exe` with Zig `-O3` LTO.
2. **Binary Parity**: SHA-256 hash `5E5F84D8CCDF8E215E9114867D18CA89114ACC610911B8B377426579FD0B9DEC` synchronized across:
   - `./geomind.exe`
   - `test/geomind/geomind.exe`
   - `bin/geomind.exe`
3. **Analogy Verification**: 4/4 semantic analogies passed at Rank 1:
   - King - man + woman = queen (margin +0.109)
   - he - him + her = she (margin +0.110)
   - father - man + woman = mother (margin +0.098)
   - boy - man + woman = girl (margin +0.271)
4. **Baseline Checkpoint Reset**:
   - Restored pristine weights from `geomind_slerp_fused_weights.bin` (SHA-256 `AD9C75F9BACC9FCCC77606BED5F08D5A0FDB6FC3740C3F8EE2A481F4992A0B52`) into `geomind_steady_state_weights.bin` and `geomind_embedding_weights.bin`.
   - Set `checkpoint_status.txt` to `SUCCESS`. Prior run weights backed up to `.pre_reset_bak` and training log archived to `logs/stage2_ce_training_pre_sprint399_reset.log`.
   - Corpus manifest `corpus.json` reset to clean zero offsets across all 10 datasets.
