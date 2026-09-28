# Sprint 433 Walkthrough: Autonomous Stage 2 CE to Stage 3 SFT Transition (`-auto-sft`)

## Executive Summary
Sprint 433 resolved **[ISSUE-181]** by implementing the `-auto-sft [target_loss]` CLI option, enabling the GeoMind native training pipeline to automatically transition seamlessly from Stage 2 Cross-Entropy Pre-training to Stage 3 Supervised Fine-Tuning upon reaching the CE target loss.

---

## Key Deliverables & Changes

### 1. Universal `-auto-sft` CLI Option (`test/geomind/main.car`)
- Implemented `has_cli_auto_sft(arg_count)` and `get_cli_auto_sft_target_loss(arg_count, default_val)`.
- Flexible syntax handling:
  - `-auto-sft` (bare flag): Enables auto-transition, default SFT target loss = `2.00`.
  - `-auto-sft <float>` (e.g. `-auto-sft 2.5`): Sets SFT target loss to `2.50`.
  - `--auto-sft <float>`, `-auto-sft=<float>`, `--auto-sft=<float>`.
  - Next flag detection: when `-auto-sft` is followed by another flag (e.g. `-auto-sft -epochs 10`), it cleanly adopts the default `2.00` without misparsing `-epochs`.
- Documented in `print_help_dialogue()` under `Training & Optimization Flags`.

### 2. Convergence Tracking & Recurrent VRAM State Isolation (`test/geomind/train.cl`)
- Declared and exported global status flag `g_last_train_target_loss_reached: float`.
- Set `g_last_train_target_loss_reached = 1.0` when Stage 2 reaches target loss across all domains (`target_loss_reached == 1.0` or full-epoch sustained convergence).
- Added GPU domain recurrent VRAM buffer re-zeroing across all 64 slots at stage entry in `geomind_train_streaming_steady_state()`, eliminating carryover recurrent state between stages.

### 3. Autonomous Stage 2 -> Stage 3 Pipeline Handoff (`test/geomind/main.car`)
- In `is_ce_mode` / `is_pre_mode` block:
  - If `has_cli_auto_sft(arg_count) == 1.0` and `g_last_train_target_loss_reached == 1.0`:
    - Prints an informative transition banner:
      ```
      ================================================================================
        [AUTO-SFT PIPELINE TRANSITION] Stage 2 CE Target Loss Reached!
        Automatically transitioning seamlessly to Stage 3 Supervised Fine-Tuning (SFT)...
        SFT Target Loss: <sft_target_loss> | Manifest: test/geomind/trainingdata/sft_manifest.json
      ================================================================================
      ```
    - Automatically launches `geomind_train_streaming_steady_state(3.0, "", sft_target_loss, ...)` on `sft_manifest.json`.
  - Supports `-reset-manifest` across both Stage 2 `corpus.json` and Stage 3 `sft_manifest.json`.

### 4. Manifest Clean State Reset
- Synchronously reset `test/geomind/trainingdata/sft_manifest.json` offsets, epoch (1.0), LR (0.0012), and zeroed domain loss vectors across all 17 datasets to ensure clean baselines on fresh runs.

---

## Verification Results

### Regression Test Suite (`test/geomind/nses/test_sprint20_auto_sft_transition.car`)
- **Gate TS-20.1 (CLI Argument Parsing)**: PASSED (All 6 scenarios verified: bare, space-value, double-dash, equals syntax, flag-next, and absent).
- **Gate TS-20.2 (Convergence Discrimination)**: PASSED (Target loss convergence accurately gates on 100% domain convergence).
- **Gate TS-20.3 (Recurrent VRAM Isolation)**: PASSED (64 slots partitioned cleanly across 640 KB VRAM).
- **Gate TS-20.4 (Manifest Continuity)**: PASSED (Both manifests verified on disk with correct dataset counts and clean baselines).

### Production Engine Verification (`bin/geomind.exe --verify`)
- Rebuilt native executable via Zig `-O3 LTO Vectorized Pass Pipeline`.
- Synchronized across all 4 locations: `bin/geomind.exe`, `build/geomind.exe`, `./geomind.exe`, `test/geomind/geomind.exe`.
- All neural, symbolic, and Hopfield subsystems verified 100% clean.
