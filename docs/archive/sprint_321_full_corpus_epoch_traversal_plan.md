# Sprint 321 Implementation Plan: Full Corpus Dataset Traversal & Zero-Allocation Optimization

## Goal
Redefine training epochs in `test/geomind/train.cl` so each epoch executes a genuine 100% traversal through the entire corpus/dataset, replacing the single-window 64-token shortcut. Optimize `cartan_tensor_train_step` with reusable scratch buffers to eliminate per-step heap allocation overhead.

## Architecture & Implementation
1. **Zero-Allocation Softmax & Gradient Scratch Vectors (`test/geomind/train.cl`)**:
   - Pre-allocate static global vectors `g_train_logits` and `g_train_probs` (256 elements).
   - Reuse them across all training steps using `cartan_vec_set_f32`, eliminating 2 heap allocations per token step (~880,000 allocations avoided per epoch).
2. **Full Dataset Epoch Traversal (`test/geomind/train.cl`)**:
   - Loop `offset` from `256.0` through `content_len - window_size` in increments of `stride = 1024.0` (6,884 chunks for 7.05 MB `storytelling_corpus.txt`).
   - Extract each window, tokenize, compute hidden states, and perform 64 autoregressive next-token gradient updates per window.
   - Accumulate total epoch loss and tokens across all chunks.
   - Stream live progress telemetry every 500 chunks (~7% increments):
     `Epoch %s / %s | Chunk %s / %s (%s%%, %s / %s KB) | Step Loss: %s (EMA: %s) | LR: %s`
   - Print epoch completion banner and save checkpoint at end of each full dataset traversal.
3. **Dynamic CLI Parameter Defaults (`test/geomind/main.car`)**:
   - Update default `-epochs` from 500.0 to 3.0 (full passes) while preserving custom user inputs (e.g. `-epochs 500` or `-epochs 5`).
   - Update `--help` dialogue documenting that 1 epoch equals 1 complete dataset pass.
4. **Empirical Verification**:
   - Recompile `build/geomind.exe` with `cartanc.exe`.
   - Verify full-corpus training traversal and progress reporting.
   - Run 62-target compiler regression test suite (`test/compiler_suite/run_tests.car`).
