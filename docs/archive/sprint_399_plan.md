# Sprint 399 Implementation Plan: Total Validation Metric Decoupling & Isolation Architecture

## Objectives
1. **Isolate Validation Softmax Temperature**:
   - Enforce strictly invariant $T=1.0$ for all validation holdout evaluations (`lr <= 0.0`).
   - Eliminate any pathway where dynamic training temperature (`TTemp`) or controller adjustments can alter validation probabilities, cross-entropy loss, or perplexity.
2. **Isolate Validation Recurrence Context**:
   - Eliminate inter-chunk recurrent state chaining (`val_has_prev`) during validation passes over multi-domain holdout text (`cloze_validation_holdout.txt` and `pretrain_validation_holdout.txt`).
   - Evaluate each holdout sequence from a pristine zeroed hidden state (`g_has_prev_chunk_h = 0.0`), ensuring holdout metrics are mathematically deterministic, sequence-order invariant, and independent of preceding excerpts.
   - Maintain exact preservation and restoration of active training recurrent context (`g_buf_saved_train_h`).
3. **Isolate Telemetry DMA Scratch Registers**:
   - Introduce dedicated validation DMA scratch registers (`g_last_val_chunk_steps`, `g_last_val_chunk_entropy_sum`, `g_last_val_chunk_certainty_sum`, `g_last_val_chunk_surprise_sum`).
   - Ensure validation passes never overwrite or contaminate training chunk telemetry globals (`g_last_chunk_valid_steps`, `g_last_chunk_entropy_sum`, etc.).
4. **Guarantee Zero-Metric Bleed**:
   - Ensure all 6 validation telemetry metrics (`VL`, `AVL`, `IVPPL`, `AVPPL`, `VENT`, `VCERT`) are derived exclusively from unscaled mathematical holdout evaluations at $T=1.0$, completely decoupled from training metrics (`TL`, `ATL`, `ITPPL`, `ATPPL`, `ENT`, `CERT`, `LR`).

## Logical Dependency Tree
```
[Holdout Evaluation Pass: geomind_compute_validation_loss]
       │
       ├─ Stashes training recurrent state (g_buf_prev_chunk_h -> g_buf_saved_train_h)
       ├─ Initializes g_has_prev_chunk_h = 0.0 (pristine zeroed hidden state per chunk)
       │
       ▼
[Pipelined Forward Pass: geomind_train_chunk_gpu_pipelined(lr = 0.0)]
       │
       ├─ Hardcodes step_temp = 1.0 (strict invariant cross-entropy temperature)
       ├─ Disables backward passes, SGD weight updates, and Lie manifold momentum
       ├─ Reads GPU metrics into dedicated validation registers (g_last_val_chunk_*)
       │   └─ Leaves training registers (g_last_chunk_*) 100% untouched
       │
       ▼
[Validation Metric Aggregator]
       │
       ├─ VL: Fresh holdout cross-entropy at T=1.0
       ├─ AVL: EMA holdout cross-entropy across intervals
       ├─ IVPPL: exp(VL)
       ├─ AVPPL: exp(AVL)
       ├─ VENT: Shannon entropy in bits
       ├─ VCERT: Top-1 certainty %
       │
       ▼
[Restoration & One-Way Generalization Gap Controller]
       ├─ Restores training recurrent state (g_buf_saved_train_h -> g_buf_prev_chunk_h)
       ├─ Controller reads val_gap = AVL - ATL to dynamically adjust TTemp (1.0 -> 1.35)
       └─ One-way causality: Validation informs controller; training never alters validation
```

## Step-by-Step Action Plan
1. Edit `test/geomind/train.cl`:
   - Declare dedicated validation DMA globals (`g_last_val_chunk_steps`, `g_last_val_chunk_entropy_sum`, `g_last_val_chunk_certainty_sum`, `g_last_val_chunk_surprise_sum`).
   - In `geomind_train_chunk_gpu_pipelined`: route metric outputs to validation globals when `lr <= 0.0`, leaving training globals intact.
   - Enforce invariant `step_temp = 1.0` when `lr <= 0.0`.
   - In `geomind_compute_validation_loss`: reset `g_has_prev_chunk_h = 0.0` for each holdout chunk (zero hidden state), accumulate from `g_last_val_chunk_*`, and restore training state.
2. Compile and link with `cartanc.exe` (`zig cc -O3 -flto`).
3. Synchronize binaries to `./geomind.exe`, `test/geomind/geomind.exe`, and `bin/geomind.exe`.
4. Verify bit-for-bit SHA-256 parity and run `--eval-analogy` test.
5. Update `ISSUES.md`, `CHANGELOG.md`, and archive plan and walkthrough.
