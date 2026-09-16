# Sprint 352 Implementation Plan: Stage 1 Cloze Target Loss Alignment to 3.80

## Objectives
1. Align default Cloze `--train-cloze` target loss stopping threshold in `test/geomind/main.car:316` to `3.80` (previously `4.20`).
2. Update CLI help dialogue in `test/geomind/main.car:59` to reflect `Default: 3.80 Cloze`.
3. Recompile via self-hosting `cartanc.exe` and synchronize production binaries.

## Execution Checklist
- [x] Update `main.car:316` default from `4.20` to `3.80`.
- [x] Update `main.car:59` help dialogue text.
- [x] Recompile via `cartanc.exe` to `test/geomind/geomind.exe`.
- [x] Synchronize binaries to `bin/geomind.exe` and `build/geomind.exe`.
- [x] Update `ISSUES.md` (`[ISSUE-103]`) and `CHANGELOG.md` (`[8.309.0]`).
- [x] Save plan and walkthrough to `docs/archive/`.
