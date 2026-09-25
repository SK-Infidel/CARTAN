# Sprint 423 Task List: Dynamic $\gamma$ Scaling

- [x] **Task 1: Dynamic Gamma Controller Module (`src/std/dynamic_gamma.cl`)**
  - [x] Define `DynamicGammaConfig` struct with reference targets and safety clamps.
  - [x] Implement `dynamic_gamma_create` with calibrated defaults ($\gamma \in [0.02, 0.35]$).
  - [x] Implement `dynamic_gamma_compute` incorporating domain baselines, entropy/certainty multiplier, and loss surge amplification.

- [x] **Task 2: Training Engine & GPU Pipeline Integration (`test/geomind/train.cl`)**
  - [x] Include `src/std/dynamic_gamma.cl` in `test/geomind/train.cl`.
  - [x] Declare global `g_gamma_cfg` and `g_active_hopfield_gamma`.
  - [x] In `geomind_train_streaming_steady_state`, compute `active_gamma` prior to chunk launch.
  - [x] Dynamically update `g_pipe_hopfield_inject` (arg 5) and `g_pipe_hopfield_backward` (arg 6) on every chunk.
  - [x] Display `Gamma` in chunk streaming progress telemetry and biological logs.

- [x] **Task 3: Empirical Verification & Regression Testing**
  - [x] Create and run `test/geomind/nses/test_sprint10_dynamic_gamma.car` (4 verification gates).
  - [x] Rebuild `geomind.exe` with Zig `-O3 LTO Vectorized Pass Pipeline`.
  - [x] Verify `geomind.exe --verify`.
  - [x] Verify `geomind.exe --sleep`.
  - [x] Run live streaming training `geomind.exe --train-ce` verifying dynamic $\gamma$ modulation.

- [x] **Task 4: Documentation & Archival**
  - [x] Update `CHANGELOG.md` with version `[8.381.0]`.
  - [x] Update `ISSUES.md` resolving `[ISSUE-165]`.
  - [x] Save implementation plan, task list, and walkthrough to `docs/archive/`.
