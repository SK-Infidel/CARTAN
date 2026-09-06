# Sprint 316 Plan: Cloze Training Pipeline Scaling, Dataset Sliding Window & Dynamic CLI Parameters

## 1. Objective & Scope
- Scale the GeoMind cloze and steady-state training pipeline beyond the initial 50-epoch hardcoded truncation.
- Support dynamic CLI parameter passing (`-epochs`, `-lr`, `-target-loss`, `-target`).
- Replace single 512-byte initial slice with a rolling sliding window traversing the entire 1.98 MB / 4,279-record dataset across epochs.
- Double inner autoregressive step count per epoch (64 tokens) and add a learning rate decay floor (`0.0001`) to enable steady convergence to target depth ($\le 2.50$).

## 2. Architecture & Design
- **CLI Parsing (`test/geomind/main.car`)**:
  - Expose libc `atof` via `extern fn atof(s: string) -> float;`.
  - Implement `get_cli_param_float(flag_name, arg_count, default_val)`.
  - Wire `-epochs`, `-lr`, and `-target-loss` to `--train-cloze`, `--train-pre`, `--train-ce`, and `--train-sft`.
- **Sliding Window Trainer (`test/geomind/train.cl`)**:
  - Ingest full file content into memory.
  - On each epoch, calculate window offset: `math_mod_val((ep - 1.0) * 384.0, content_len - window_size)` with 1024-byte window.
  - Run 64 autoregressive token steps per epoch.
  - Decay learning rate by 0.995 per epoch with floor 0.0001 until reaching `target_loss` ($\le 2.50$).

## 3. Verification Criteria
- `build/geomind.exe --train-cloze -epochs 5` runs dynamically with custom epochs and slides across dataset.
- Recompiled `build/geomind.exe` passes compiler suite regressions (62/62 targets).
- Full command documented for user execution.
