# Sprint 317 Plan: Checkpoint Continuity, Narrative Pre-training & Banner Offset Protection

## 1. Objective & Scope
- Bridge the training pipeline across stages by implementing warm-start checkpoint restoration.
- Ensure Stage 2 Causal Cross-Entropy (`--train-ce`) seamlessly inherits cortical weights trained during Stage 1 Cloze (`geomind_steady_state_weights.bin`).
- Protect against false early stopping caused by repetitive ASCII banner headers (`===`) at the beginning of narrative corpora.
- Verify end-to-end CE training on `test/geomind/trainingdata/storytelling_corpus.txt` (7.05 MB).

## 2. Architecture & Design
- **Binary Tensor Loader (`src/std/hub.cl`)**:
  - Implement `cartan_safetensors_load_raw_tensor_f32(path: string, num_elements: float) -> ptr`.
  - Read directly via `fread` into float buffer and populate allocated tensor array.
- **Warm-Start Restoration & Banner Protection (`test/geomind/train.cl`)**:
  - Before the epoch loop, inspect `geomind_steady_state_weights.bin` and restore existing weights if present.
  - Advance base sliding window offset past decorative header (`256.0 + (ep - 1.0) * 384.0`).
  - Guard early stopping convergence with `ep >= 10.0`.
- **Target Loss Calibration (`test/geomind/main.car`)**:
  - Calibrate stage defaults: Stage 1 Cloze (4.20), Stage 2 CE (3.50), Stage 3 SFT (2.00).

## 3. Verification Criteria
- `build/geomind.exe --train-ce -epochs 20` loads 6,553,600 parameters from checkpoint, logs genuine loss reduction over narrative text, and saves updated checkpoint.
- Full 62-target regression suite passes cleanly.
