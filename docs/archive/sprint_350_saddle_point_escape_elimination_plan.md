# Sprint 350 Implementation Plan: Elimination of Disruptive Mid-Stream Saddle Point Escape Boosts

## Objectives
1. Eliminate the legacy mid-stream saddle point escape mechanism that artificially boosted LR from $0.0162$ to $0.035$.
2. Remove `floor_stagnation_count` tracking from `test/geomind/train.cl`.
3. Allow the model to maintain uninterrupted steady gradient descent in its optimal convergence zone ($0.015 - 0.020$).
4. Recompile with self-hosting `cartanc.exe` and synchronize production binaries.

## Root Cause
- The condition `lr <= (lr_floor * 1.15)` evaluated to true whenever `lr` reached $0.01725$.
- Because it did not check if loss was actively dropping, ordinary productive training triggered the counter on every interval.
- After 15 intervals (1,500 lines), it triggered a $+115\%$ LR jump, repeatedly shocking the network.

## Execution Checklist
- [x] Remove saddle point escape block from `test/geomind/train.cl`.
- [x] Clean up `floor_stagnation_count` variable and references.
- [x] Recompile via `cartanc.exe` to `test/geomind/geomind.exe`.
- [x] Copy to `bin/geomind.exe` and `build/geomind.exe`.
- [x] Update `ISSUES.md` (`[ISSUE-101]`) and `CHANGELOG.md` (`[8.307.0]`).
- [x] Save plan and walkthrough to `docs/archive/`.
