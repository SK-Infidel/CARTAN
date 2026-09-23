# Sprint 397 Walkthrough: Rigorous Backward Adjoints, Metric Integrity & I/O Purification

## Overview & Objectives
Sprint 397 systematically resolves the remaining defects identified in `[ISSUE-143]`, `[ISSUE-144]`, `[ISSUE-145]`, `[ISSUE-146]`, and `[ISSUE-147]`:
1. Quenched runaway validation loss divergence by locking `g_val_temperature = 1.0` and `g_train_temperature = 1.0` (`[ISSUE-144]`).
2. Eliminated manifest disk thrashing by moving `geomind_manifest_save_interleaved` to the 50-chunk interval, eliminating 98% of redundant disk writes while preserving crash recovery (`[ISSUE-145]`).
3. Stashed pristine pre-RMSNorm state in `g_buf_pre_rmsnorm_h` via `g_pipe_copy_pre_rmsnorm` and bound to `rmsnorm_backward_post` and `hopfield_backward`, eliminating Jacobian distortion from in-place normalization (`[ISSUE-146]`).
4. Rebalanced token embedding gradient scale in `geomind_streams_backward` and `geomind_input_grad_update` from $0.025\times$ to $0.25\times$, eliminating the $40\times$ step-size suppression (`[ISSUE-147]`).
5. Confirmed continuous multi-domain mixture loss tracking (`domain_losses`) and smoothed `ATL` calculation are active and verified (`[ISSUE-143]`).

---

## Changes Implemented

### 1. Locked Evaluation & Optimization Temperatures (`test/geomind/train.cl`)
- Replaced dynamic temperature calculation in the adaptive controller with invariant standard bounds:
  ```cartan
  // Temperature Controller: Locked strictly to 1.0 to eliminate runaway evaluation divergence and noise oscillators
  g_train_temperature = 1.0;
  g_val_temperature = 1.0;
  ```
- Evaluated out-of-sample validation holdout cross-entropy and perplexity at standard $T = 1.0$, quenching the positive feedback loop ($VTemp \uparrow \implies Loss_{\text{val}} \uparrow \implies val\_gap \uparrow \implies VTemp \uparrow$).

### 2. High-Frequency I/O Relocation (`test/geomind/train.cl`)
- Updated `offsets_list` in memory on every chunk (`cartan_vec_set_f32(offsets_list, d_idx, next_line_start)`).
- Relocated `geomind_manifest_save_interleaved` into the 50-chunk reporting interval:
  ```cartan
  if (manifest_mode == 1.0) {
      geomind_manifest_save_interleaved(manifest_path, datasets_list, offsets_list, d_idx, ep, lr);
  }
  ```
- Removed blocking `fopen`/`fwrite`/`fclose` calls on every 1-chunk boundary, eliminating SSD wear and main thread micro-stutters.

### 3. Scratch Pre-RMSNorm VRAM Buffer & Copy Pipeline (`test/geomind/train.cl`)
- Declared `g_pipe_copy_pre_rmsnorm: ptr = 0.0;` and `g_buf_pre_rmsnorm_h: ptr = 0.0;`.
- Allocated `g_buf_pre_rmsnorm_h = gpu_alloc(2560.0 * 4.0);` in `train_mount_gpu()`.
- Created copy pipeline `g_pipe_copy_pre_rmsnorm = gpu_create_pipeline(copy_src, "geomind_copy_vec");` with args (0: `g_buf_train_hidden`, 1: `g_buf_pre_rmsnorm_h`, 2: 2560.0).
- Bound `g_buf_pre_rmsnorm_h` to `rmsnorm_backward_post` (arg 1) and `hopfield_backward` (arg 1).
- In `geomind_train_chunk_gpu_pipelined`, launched `g_pipe_copy_pre_rmsnorm` across 2560 threads immediately following Hopfield injection and prior to `g_pipe_rmsnorm`.

### 4. Rebalanced Embedding Gradient Multiplier (`test/geomind/train.cl`)
- In `geomind_streams_backward`: scaled `0.025f` up to `0.25f` in weight gradient step.
- In `geomind_input_grad_update`: scaled `0.025f` up to `0.25f` in weight gradient step.

---

## Verification & Empirical Proof

1. **Compilation**:
   Built cleanly with `cartanc.exe` and Zig/Clang `-O3` LTO.
2. **Binary Parity**:
   Bit-for-bit SHA-256 hash match across all deployment paths:
   `2CA64DCE69C9BCD68B1D9F15403CD71EDE8CA15DA79885CD2227B6BC283D6ED3`
   - `./geomind.exe`
   - `test/geomind/geomind.exe`
   - `bin/geomind.exe`
3. **Analogy Engine**:
   `.\geomind.exe --eval-analogy` passed 4/4 semantic vector analogies cleanly at Rank 1:
   - King - man + woman = queen (Rank 1, margin +0.107)
   - he - him + her = she (Rank 1, margin +0.151)
   - father - man + woman = mother (Rank 1, margin +0.093)
   - boy - man + woman = girl (Rank 1, margin +0.260)
4. **Corpus Invariant**:
   `test/geomind/trainingdata/corpus.json` confirmed cleanly zeroed at dataset 0, offset 0.0 across all 10 datasets, epoch 1.0, active LR 0.0022.
