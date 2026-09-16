# Sprint 340: Line-by-Line Cloze Ingestion, Zero-JSON Training & GPU Momentum Optimizer Walkthrough

## Overview & Executive Summary
Sprint 340 addressed the slow loss descent (~0.4 over 77 epochs) and corpus skipping during Cloze steady-state training. We replaced the arbitrary 256-byte window slicing and 2,048-byte stride with 100% sequential line-by-line sentence ingestion, eliminated JSON syntax training via real-time field extraction, and implemented GPU EMA momentum in VRAM with gradient clipping.

## Root Causes Identified
1. **87.5% Corpus Skipping**: The previous steady-state loop advanced `offset = offset + 2048.0` with `window_size = 256.0`, skipping 1,792 bytes out of every 2,048 bytes. Over 77 epochs, 87.5% of the corpus was never seen, and the exact same 12.5% slices were repeatedly trained.
2. **Mid-Sentence Splitting**: Fixed 256-byte windows cut across words and transitional phrases, breaking sequence modeling.
3. **JSON Syntax Pollution**: Training directly on `.jsonl` lines forced the neural network to spend model capacity fitting JSON markup (`{"sentence_cloze": "`, braces, quotes) rather than English linguistic transitions.
4. **Learning Rate Freezing & Gradient Stagnation**: A decay rate of 0.90 per epoch reduced the base learning rate from 0.002 to the 0.0001 floor by epoch 28. Single-sample vanilla SGD without momentum oscillated in the 2,560-dimensional manifold without directional persistence.

## Key Changes Implemented
1. **Line-by-Line Natural Text Extraction (`test/geomind/train.cl`)**:
   - Declared `extern fn cartan_byte_at(p: ptr, offset: float) -> float;` for O(1) constant-time byte scanning without `strlen` overhead.
   - Implemented `geomind_clean_training_line(raw_line)`:
     - Detects JSON objects (`{`), extracts `sentence_cloze` and `target_phrase` via `geomind_manifest_get_field`, and concatenates them into clean natural text with zero JSON syntax.
     - Trims whitespace and `\r` from plain text lines.
   - Updated `geomind_train_streaming_steady_state`:
     - Replaced `offset + window_size` with `line_start < content_len`.
     - Advances `line_start = next_line_start` (100% corpus traversal, zero bytes skipped).
     - Each line is ingested as an unbroken, complete sentence learning item.
   - Updated `geomind_compute_validation_loss` to evaluate line-by-line coherent sentences.
2. **GPU EMA Momentum & Gradient Clipping in VRAM**:
   - Allocated `g_buf_cortical_velocity` (26.2 MB) and zeroed at startup via `geomind_zero_velocity`.
   - Updated OpenCL kernel `geomind_sgd_backward`:
     - Computes exponential moving average (EMA) momentum: `v = beta * v + (1 - beta) * grad`.
     - Applies gradient clipping: `v = clamp(v, -1.0, 1.0)`.
     - Updates cortical weights: `W = W * decay - lr * v`.
   - Configured pipeline arguments across all 9 slots in `g_pipe_sgd`.
3. **Adjusted Learning Rate Schedule**:
   - Epoch decay reduced from 0.90 to 0.95.
   - Minimum LR floor raised from 0.0001 to 0.0005.

## Verification & Empirical Results
- Built with pure native self-hosting `cartanc.exe`.
- Synchronized all 4 production binaries with identical SHA-256 hash:
  `30FC3567EF32A46D827425574160312B1B6095BCD4B03C68985B1C2B04932648`:
  - `bin/geomind.exe`
  - `./geomind.exe`
  - `build/geomind.exe`
  - `test/geomind/geomind.exe`
- Scratch dataset empirical tests:
  - 20 lines plain text: TL 2.57, ATL 4.43, VL 4.79, VPPL 121.09, 100% corpus ingested (406 steps).
  - 20 lines JSONL: Cleanly stripped JSON syntax; final loss reached 3.9682 across 411 steps.
