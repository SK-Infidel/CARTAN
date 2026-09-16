# Sprint 364 Plan: Gradient Step Acceleration, Input Embedding Scaling & Adaptive LR Headroom

## 1. Context & Objectives
During Stage 2 pre-training across 14 heterogeneous corpora (140+ MB), loss flattened around $TL \approx 3.96$. Two bottlenecks were identified:
1. **Sluggish Input Embedding Updates**: `geomind_input_grad_update` scaled updates at only `0.02f` (2%), preventing input token embeddings from adapting to technical domain vocabulary (ArXiv, FineWeb).
2. **Artificial Learning Rate Ceiling**: The adaptive controller was clamped with an artificial `0.008` ceiling and a `0.0002` floor, keeping LR trapped around `0.003`. Per user guidance, the lower limit will be set to `0.002`, and the ceiling opened up to `0.050` (allowing natural dynamic braking to regulate top-end momentum).

## 2. Technical Changes
1. **Input Embedding Gradient Boost (`test/geomind/train.cl`)**:
   - In `input_sgd_src`, boost gradient update rate from `0.02f` to `0.10f` (5× increase).
2. **Learning Rate Bounds & Headroom (`test/geomind/train.cl`)**:
   - In Stage 2 setup (`stage_mode == 2.0`), set `lr_floor = 0.002` and `stage_ceiling_lr = 0.05`.
   - In the adaptive TPPL centering controller, remove the restrictive `0.008` clamps and allow probing up to `stage_ceiling_lr` (`0.05`).
   - Default initial pre-training rate when unspecified to `0.006`.
3. **Manifest Update (`test/geomind/trainingdata/corpus.json`)**:
   - Update `"current_lr": 0.006` to launch at optimal momentum.
4. **Binary Synchronization & Validation**:
   - Recompile `test/geomind/geomind.exe` with `cartanc.exe`.
   - Synchronize across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
   - Empirically verify `--train-pre` launch and telemetry.
