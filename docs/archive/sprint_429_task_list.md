# Sprint 429 Task List: Stage 3 SFT Target-Loss Annealing, Guarded Learning Rate, and Manifest Initialization

- [ ] **Task 1: Calibrate SFT Learning Rate Bounds**
  - In `test/geomind/train.cl` lines 1928-1936:
    - Set `lr_floor = 0.0003` and `stage_ceiling_lr = 0.0015` for `stage_mode == 3.0`.
    - Set default unconfigured starting `lr = 0.0012` for SFT.

- [ ] **Task 2: Enable Target-Loss Progress Annealing in SFT**
  - In `test/geomind/train.cl` line 2629:
    - Extend condition to `(stage_mode == 2.0 || stage_mode == 3.0) && t_loss > 0.0`.
    - Set `initial_loss_ref = 4.20` for `stage_mode == 3.0` (smooth descent from 4.20 down to `t_loss`).

- [ ] **Task 3: Initialize Clean SFT Manifest**
  - Update `test/geomind/trainingdata/sft_manifest.json` with 17 instruction and dialogue datasets, initial offsets at `0.0`, epoch `1.0`, and full Sprint 428 schema.

- [ ] **Task 4: Empirical Regression Testing & Rebuilding**
  - Write regression suite `test/geomind/nses/test_sprint16_sft_annealing.car`.
  - Compile and verify all gates with `cartanc.exe`.
  - Rebuild native `bin/geomind.exe` with Zig `-O3 LTO Vectorized Pass Pipeline`.
  - Verify `bin/geomind.exe --verify`.
  - Synchronize updated `geomind.exe` across all 4 locations.
  - Update `ISSUES.md`, `CHANGELOG.md`, and write `sprint_429_walkthrough.md`.
