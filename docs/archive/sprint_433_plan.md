# Sprint 433 Plan: Autonomous Stage 2 CE to Stage 3 SFT Transition (`-auto-sft`)

## Sprint Goal
Implement `-auto-sft [target_loss]` CLI option enabling the training pipeline to automatically transition seamlessly from Stage 2 Cross-Entropy Pre-training to Stage 3 Supervised Fine-Tuning when the Stage 2 target loss is reached.

---

## User Stories & Architecture

### User Story 1: Universal `-auto-sft` CLI Parsing
- **As a developer/trainer**, I want to specify `-auto-sft` or `-auto-sft <float>` on the command line when starting CE pre-training (`--train-ce` / `--train-pre`).
- **Details**:
  - Support flags: `-auto-sft`, `--auto-sft`, `-auto-sft=<float>`, `--auto-sft=<float>`, and `-auto-sft <float>`.
  - When a float argument is provided (e.g. `-auto-sft 2.5`), use it as the Stage 3 SFT target loss.
  - When no float argument is provided (e.g. `--train-ce -tl 3.0 -auto-sft`), default SFT target loss to `2.00`.
  - Update `--help` output with usage documentation.

### User Story 2: Stage Target Convergence Tracking & Recurrent State Reset
- **In `test/geomind/train.cl`**:
  - Expose `g_last_train_target_loss_reached` flag.
  - Set `g_last_train_target_loss_reached = 1.0` when Stage 2 reaches target loss across all domains (`target_loss_reached == 1.0` or full-epoch sustained convergence).
  - Clear `g_buf_domain_h` (all 64 domain slots) at the start of any training stage to prevent cross-stage recurrent context pollution.

### User Story 3: Autonomous Stage 2 -> Stage 3 Orchestration
- **In `test/geomind/main.car`**:
  - In `is_ce_mode` / `is_pre_mode` dispatch block:
  - If `has_cli_auto_sft(arg_count) == 1.0` and `g_last_train_target_loss_reached == 1.0`:
    - Print an informative pipeline transition banner.
    - Synchronize weights to GPU and launch `geomind_train_streaming_steady_state(3.0, "", sft_target_loss, 0.0, epochs, "logs/stage3_sft_training.log")`.
  - If `-reset-manifest` was specified, reset `test/geomind/trainingdata/sft_manifest.json` along with `corpus.json`.

### User Story 4: Empirical Regression Verification & Binary Rebuild
- **Harness**: `test/geomind/nses/test_sprint20_auto_sft_transition.car`.
- Gates:
  - Gate TS-20.1: CLI Argument Parsing for `-auto-sft` (bare flag, numeric argument, `=` syntax, default fallback).
  - Gate TS-20.2: Convergence Flag Setting & Stage Exit Discrimination.
  - Gate TS-20.3: Domain Recurrent VRAM State Isolation.
  - Gate TS-20.4: Manifest Continuity Across Stage Transition.
- Rebuild and verify `bin/geomind.exe`.
