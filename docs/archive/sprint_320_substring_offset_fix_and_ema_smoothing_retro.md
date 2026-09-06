# Sprint 320 Retrospective: Substring Slice End Offset Fix and EMA Smoothed Loss Convergence

## Executive Summary
Diagnosed and resolved the root cause of instant (< 1s) pre-training termination and frozen loss during Stage 2 Causal Cross-Entropy training (`--train-ce`). Implemented exponential moving average (EMA) loss smoothing to protect against premature early stopping on repetitive chapter dividers. Recompiled `build/geomind.exe` with pure self-hosted `cartanc.exe` and Zig backend.

## Key Accomplishments
1. **Absolute End Index Bug Fix (`test/geomind/train.cl:571`)**:
   - Corrected `cartan_string_substring(file_content, offset, window_size)` to `cartan_string_substring(file_content, offset, offset + window_size)`.
   - Guaranteed every epoch receives a full 1024-character continuous text window across the 7.05 MB narrative dataset.
2. **Exponential Moving Average Loss Smoothing (`test/geomind/train.cl:561-615`)**:
   - Added `smoothed_loss = smoothed_loss * 0.85 + final_loss * 0.15`.
   - Bounded early stopping convergence to `smoothed_loss <= t_loss && ep >= 20.0`, preventing false positive convergence on isolated divider blocks (`====...`).
   - Added live EMA metrics to console logging: `Loss: %s (EMA: %s)`.
3. **Empirical Validation**:
   - Recompiled `build/geomind.exe` with `cartanc.exe`.
   - Verified genuine multi-epoch training: gradient updates execute across 64 tokens/epoch, loss descends smoothly, and safety backups update on clean completion.
