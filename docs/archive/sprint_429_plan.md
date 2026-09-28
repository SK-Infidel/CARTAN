# Sprint 429 Plan: Stage 3 SFT Target-Loss Annealing, Guarded Learning Rate, and Manifest Initialization

## Goal
Fully adapt the unified streaming engine for Stage 3 Supervised Fine-Tuning (`--train-sft`), enabling smooth Target-Loss Progress Annealing toward target loss (2.00), setting safe learning rate bounds to preserve pretrained weights, and initializing a clean multi-dataset SFT manifest.

## Root Cause & Gaps Identified
1. **Target-Loss Annealing Gated Out**: In `test/geomind/train.cl` line 2629, Target-Loss Progress Annealing was strictly gated with `if (stage_mode == 2.0)`. In Stage 3 SFT (`stage_mode == 3.0`), the learning rate did not anneal dynamically during training as loss approached target.
2. **Unsafe Ceiling Learning Rate**: In `train.cl` line 1930, `stage_ceiling_lr` for `stage_mode == 3.0` was set to a legacy `0.05`. In SFT fine-tuning, large learning rates catastrophic-forget pretrained representations. A calibrated ceiling of `0.0015` and starting LR of `0.0012` is required.
3. **Outdated SFT Manifest**: `test/geomind/trainingdata/sft_manifest.json` on disk was from 9/15/2026, paused midway through dataset 0, lacking the Sprint 428 `offsets`, `bytes_ingested_epoch`, and multi-domain loss schema.

## Architecture & Implementation Strategy
1. **Learning Rate Bounds Calibration**:
   - In `test/geomind/train.cl` lines 1928-1936:
     - Set `lr_floor = 0.0003` and `stage_ceiling_lr = 0.0015` for `stage_mode == 3.0`.
     - Set default starting `lr = 0.0012` when no explicit `-lr` is passed.
2. **Target-Loss Progress Annealing for SFT**:
   - Extend line 2629:
     ```cartan
     if ((stage_mode == 2.0 || stage_mode == 3.0) && t_loss > 0.0) {
         var initial_loss_ref = 6.00;
         if (stage_mode == 3.0) {
             initial_loss_ref = 4.20;
         }
         let loss_span = initial_loss_ref - t_loss;
         ...
     ```
     Enables smooth monotonic descent from 0.0015 down to 0.0003 as loss drops from ~4.20 toward target loss (e.g. 2.00).
3. **Clean SFT Multi-Dataset Manifest**:
   - Write updated `test/geomind/trainingdata/sft_manifest.json` with all 17 SFT datasets at offset 0.0, epoch 1.0, and Sprint 428 state tracking schema.

## Verification Plan
1. Standalone regression test `test_sprint16_sft_annealing.car` verifying SFT annealing calculations and manifest schema compatibility.
2. Build native `bin/geomind.exe` with `cartanc.exe`.
3. Verify `bin/geomind.exe --verify`.
4. Synchronize `geomind.exe` across all 4 locations.
