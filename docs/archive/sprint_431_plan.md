# Sprint 431 Plan: Per-Dataset Target Loss Backward Pass Freezing & Universal CLI Options

## Objective
1. **Per-Dataset Target Loss Backprop Freezing**:
   When any given dataset in the multi-domain corpus reaches `target_loss` (or `t_loss`), freeze/stop weight updates on the backward pass for that dataset across all training modes (`--train-cloze`, `--train-ce`, `--train-sft`).
   - Forward pass and prequential validation continue unperturbed.
   - Telemetry tracks ongoing out-of-sample metrics and signals `[TARGET REACHED: BACKPROP FROZEN]`.
   - If loss drifts back above target, backprop resumes automatically.
   - Overall session completion stops when all domains reach target loss.
2. **Unified Target Loss CLI Flags**:
   Standardize target loss flags across all training stages so `-target-loss`, `-tl`, `-loss`, and `-training-loss` (with single or double dash) are identical everywhere.
   Eliminate legacy bypass handlers in `main.car` that skipped focus parameters for `--train-pre` and `--train-cloze`.

## Architecture & Implementation Details
- **`test/geomind/train.cl`**:
  - Global `var g_is_training_pass: float = 0.0;`
  - In `geomind_train_chunk_gpu_launch_pass`: condition validation temperature strictly when `g_is_training_pass == 0.0`.
  - In `geomind_train_chunk_gpu_finish_pass`: populate `g_last_chunk_*` training metrics whenever `lr > 0.0 || g_is_training_pass == 1.0`.
  - In `geomind_train_streaming_steady_state`:
    - Before launching training chunk, check domain loss vs `t_loss`.
    - If `(d_loss > 0.0 && d_loss <= t_loss) || (d_vloss > 0.0 && d_vloss <= t_loss)`, set `domain_frozen = 1.0` and `step_lr = 0.0`.
    - Pass `step_lr` to `geomind_train_chunk_gpu_launch_pass`. All 9 backward kernels are skipped when `step_lr == 0.0`.
    - Preserve recurrent context `g_buf_domain_h` even when frozen.
    - Check overall target reached across all active domains.
    - Emit clear telemetry: `[TARGET REACHED: BACKPROP FROZEN]`.
- **`test/geomind/main.car`**:
  - Remove duplicate early dispatch block lines 395-424 that bypassed adaptive focus and temperature tuning.
  - Clarify `--help` documentation for universal `-target-loss`, `-tl`, `-loss`, `-training-loss` flags.
- **Verification Harness**:
  - `test/geomind/nses/test_sprint18_per_dataset_target_freeze.car`:
    - Gate TS-18.1: Universal CLI flag parsing.
    - Gate TS-18.2: Per-dataset target loss condition evaluation and `step_lr = 0.0` freezing.
    - Gate TS-18.3: Bidirectional loss drift detection and automatic resumption.
    - Gate TS-18.4: Multi-domain convergence stopping logic.
