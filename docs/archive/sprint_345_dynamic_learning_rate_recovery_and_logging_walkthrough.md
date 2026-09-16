# Sprint 345: Dynamic Learning Rate Recovery & Logging Walkthrough

## Summary of Changes
Resolved learning rate stagnation, sub-floor pinning (`0.001`), and missing log file synchronization in streaming cloze curriculum training:
1. **Dynamic Learning Rate Range & Floor Calibration (`test/geomind/train.cl`)**:
   - Set stage-calibrated floor `lr_floor = 0.015` for Cloze (Stage 1), ensuring that parameter updates ($\approx 5.86 \times 10^{-6}$ per step with $D=2560$) always carry sufficient magnitude to adjust cortical weights against cross-entropy curvature.
   - Guarded manifest loading against stale sub-floor entries (`saved_lr < 0.005`), automatically restoring healthy defaults (`0.05`) if a corrupted sub-floor rate was previously saved.
2. **Smoothed AVL Plateau Detection (`test/geomind/train.cl`)**:
   - Replaced noisy instantaneous holdout validation tracking with exponential moving average `AVL` (`ema_val_loss`).
   - Extended plateau detection requirement to 8 consecutive intervals (800 lines) without a $\ge 0.005$ drop in `AVL` before decaying `lr = lr * 0.95`.
3. **Eliminated Unconditional Line-Interval Annealing**:
   - Removed arbitrary 500-line unconditional decay (`lr * 0.99`), stopping the continuous artificial drain that was forcing LR down into the floor.
4. **Saddle Point Escape / Warm Recovery (`test/geomind/train.cl`)**:
   - Added automatic detection for training stalled at or near the floor (`lr <= lr_floor * 1.15`) for 15 intervals (1,500 lines) without AVL improvement.
   - Kicks `lr` back up to `initial_stage_lr * 0.70` (`0.035` for cloze) to break through local minima and saddle points.
5. **Log File Synchronization (`test/geomind/train.cl`)**:
   - Appended ` | LR: <lr>\n` to entries written to `logs/stage1_cloze_training.log`.
6. **Manifest State Reset**:
   - Reset `current_lr` in `test/geomind/trainingdata/cloze_manifest.json` from `0.001` to `0.045`.

## Verification
1. **Self-Hosting Compilation**: Rebuilt `main.car` with native `cartanc.exe`.
2. **Binary Parity**: Bit-for-bit identical SHA-256 hash across all 4 locations (`487C675C760BDF3D5A33A1EDAC7F51C50D6DD14D82E64B6E67059DBF0227BA06`):
   - `bin/geomind.exe`
   - `./geomind.exe`
   - `build/geomind.exe`
   - `test/geomind/geomind.exe`
3. **Empirical Telemetry**:
   - Verified active startup banner: `Active LR: 0.045`.
   - Observed smoothed plateau decay in live telemetry: `0.045 -> 0.04275`.
   - Verified `LR` entries inside `logs/stage1_cloze_training.log`.
   - Verified live state persistence of `"current_lr": 0.04275` in `cloze_manifest.json`.
