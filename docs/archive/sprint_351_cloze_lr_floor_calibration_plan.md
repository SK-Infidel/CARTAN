# Sprint 351 Implementation Plan: Calibration of Cloze Learning Rate Floor to 0.001

## Objectives
1. Lower Stage 1 Cloze `lr_floor` from $0.015$ to $0.001$ in `test/geomind/train.cl`.
2. Lower manifest resumption floor check from $0.005$ to $0.0005$ (`saved_lr >= 0.0005`).
3. Allow the learning rate to anneal continuously below $0.015$ so the model can make fine adjustments into the global minimum ($< 4.20$).
4. Recompile with self-hosting `cartanc.exe` and synchronize all 4 production binaries.

## Root Cause
- `lr_floor` was hardcoded to $0.015$ for Stage 1.
- All decay clamps (`if (lr < lr_floor) { lr = lr_floor; }`) halted annealing at exactly $0.015$.
- Step size at $0.015$ was too coarse to descend from $4.295$ past the $4.20$ threshold, causing oscillation.

## Execution Checklist
- [x] Lower `lr_floor` to $0.001$ in `test/geomind/train.cl`.
- [x] Lower manifest resumption check to $0.0005$.
- [x] Recompile via `cartanc.exe` to `test/geomind/geomind.exe`.
- [x] Copy and verify SHA-256 parity across all 4 production binaries (`02751160B69FA8F0E1814AF42DDD00CFF6EB38037F67596207468BF23C3A5793`).
- [x] Update `ISSUES.md` (`[ISSUE-102]`) and `CHANGELOG.md` (`[8.308.0]`).
- [x] Save plan and walkthrough to `docs/archive/`.
