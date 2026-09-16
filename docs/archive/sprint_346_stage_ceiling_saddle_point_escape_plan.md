# Sprint 346: Stage-Ceiling Saddle Point Escape Plan

## Problem Statement
In Sprint 345, the saddle point escape was coded as:
`lr = initial_stage_lr * 0.70;`
When resuming an interrupted run where `current_lr` in the manifest was already at the floor (`0.015`), `initial_stage_lr` was initialized to the resumed rate (`0.015`) rather than the stage ceiling (`0.05`).
Consequently, `0.015 * 0.70 = 0.0105`, which was below `lr_floor` (`0.015`). The floor check immediately clamped `lr` back to `0.015`, emitting:
`[Adaptive LR] Saddle point escape triggered after 15.0 stagnant intervals. Boosted LR: 0.015 -> 0.015`

## Objectives
1. Define `stage_ceiling_lr` based on stage mode (`0.05` Cloze, `0.001` CE, `0.0005` SFT, or explicit CLI `-lr`).
2. Update saddle point escape calculation to use `stage_ceiling_lr * 0.70` (boosting to `0.035` for Cloze).
3. Reset `cloze_manifest.json` `current_lr` to `0.035` so resumption starts with active update power.
4. Compile with `cartanc.exe` and synchronize all 4 binaries with identical SHA-256 hash.
