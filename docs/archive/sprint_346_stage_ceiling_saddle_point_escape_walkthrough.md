# Sprint 346: Stage-Ceiling Saddle Point Escape Walkthrough

## Summary of Changes
Resolved false saddle point boost reporting (`Boosted LR: 0.015 -> 0.015`) in `test/geomind/train.cl`:
1. **Decoupled Reference Ceiling from Resumed Rate (`test/geomind/train.cl`)**:
   - Explicitly defined `stage_ceiling_lr` initialized to `0.05` (Cloze), `0.001` (CE), or `0.0005` (SFT), or explicit CLI `-lr`.
   - Ensured `initial_stage_lr` references `stage_ceiling_lr` rather than the resumed manifest `lr`.
2. **True Upward Boost Calculation**:
   - In saddle point escape: `lr = initial_stage_lr * 0.70;`.
   - For Cloze, calculates $0.05 \times 0.70 = 0.035$, which genuinely elevates the rate well above `lr_floor` (`0.015`), escaping shallow basins.
3. **Manifest Re-calibration**:
   - Reset `test/geomind/trainingdata/cloze_manifest.json` `current_lr` to `0.035`.
4. **Binary Synchronization & Parity**:
   - Recompiled with self-hosting `cartanc.exe`.
   - Verified bit-for-bit identical SHA-256 hash across all 4 paths (`BAA2A70D78771072E1D8B501C093672A616B5A7AD4159D8F285ACED19813C3E4`):
     - `bin/geomind.exe`
     - `./geomind.exe`
     - `build/geomind.exe`
     - `test/geomind/geomind.exe`
