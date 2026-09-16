# Sprint 345: Dynamic Learning Rate Recovery & Logging Plan

## Problem Statement
In Sprint 344, learning rate adaptation was added, but:
1. **Unconditional Drain & Rapid Floor Collision**: Unconditional line-interval annealing (`lr * 0.99` every 500 lines) combined with instantaneous noisy validation plateau triggers (`lr * 0.95` every 300 lines) drained `lr` down to `0.001` within ~15 minutes.
2. **Gradient Paralysis**: With dimension normalization ($/ 2560$), an LR floor of `0.001` yields updates of $\sim 4 \times 10^{-7}$, effectively freezing cortical weights and causing loss to flatline at ~4.76.
3. **No Upward Recovery**: The adaptation was a one-way downward ratchet with no mechanism to escape saddle points.
4. **Log File Omission**: `LR` was omitted from the string appended to `stage1_cloze_training.log`.

## Objectives
1. **Calibrate Effective LR Floor**: Set floor to `0.015` for Cloze stage ($0.015 / 2560 \approx 5.86 \times 10^{-6}$ per step), ensuring viable gradient signal at all times.
2. **Smoothed Plateau Tracking**: Trigger plateau decay only on smoothed `AVL` (exponential moving average `ema_val_loss`) after 800 lines (8 intervals) of confirmed stagnation.
3. **Remove Unconditional Drain**: Eliminate arbitrary 500-line unconditional decay.
4. **Saddle Point Escape / Warm Recovery**: If training remains stalled at the floor for 1,500 lines, kick `lr` back up to `base_lr * 0.70` (`0.035`) to break out of local minima.
5. **Log File Sync**: Append `LR` to `stage1_cloze_training.log`.
6. **Manifest Re-calibration**: Reset `current_lr` in `cloze_manifest.json` to `0.045`.
7. **Empirical Verification**: Recompile with `cartanc.exe`, synchronize all 4 binaries, and verify dynamic adaptation and logging.
