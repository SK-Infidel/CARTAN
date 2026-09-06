# Sprint 320 Implementation Plan: Substring Slice End Offset Fix and EMA Smoothed Loss Convergence

## Goal
Resolve instantaneous training exit (< 1 sec) and frozen loss during Stage 2 Causal CE pre-training, ensuring full 1024-byte sliding window narrative extraction and sustained EMA loss convergence.

## Root Cause
- In `test/geomind/train.cl`, `cartan_string_substring(file_content, offset, window_size)` passed `window_size` (1024.0) instead of absolute end index (`offset + window_size`).
- For any epoch where `offset >= 1024.0`, `end_idx <= start`, yielding 0 characters (`sample_text = ""`).
- Tokenizer produced 0 tokens, skipping inner training loops and running 490+ empty iterations in ~0.05 seconds with frozen loss.

## Tasks
1. **Fix Substring Windowing**: Update `train.cl` to pass `offset + window_size`.
2. **Exponential Moving Average (EMA) Loss Smoothing**: Implement EMA loss ($0.85 \cdot EMA + 0.15 \cdot Loss$) and guard early stopping with `smoothed_loss <= t_loss && ep >= 20.0`.
3. **Recompile & Verify**: Build `build/geomind.exe` with `cartanc.exe`, verify genuine loss descent, and execute compiler regression suite.
