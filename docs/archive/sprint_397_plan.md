# Sprint 397 Implementation Plan: Rigorous Adjoints, Metric Integrity & I/O Purification

## Core Mission & Objectives
Resolve all defects identified in `[ISSUE-143]`, `[ISSUE-144]`, `[ISSUE-145]`, `[ISSUE-146]`, and `[ISSUE-147]`:
1. **Lock Evaluation Temperature to Standard ($T=1.0$) (`[ISSUE-144]`)**:
   - Quench runaway validation divergence feedback loop by locking `g_val_temperature = 1.0` across all holdout evaluation passes.
2. **Purify Manifest I/O Bottleneck (`[ISSUE-145]`)**:
   - Relocate `geomind_manifest_save_interleaved` from 1-chunk high-frequency thrashing to the 50-chunk reporting interval, cutting redundant disk writes by 98%.
3. **Pristine Pre-RMSNorm State for Backward Adjoints (`[ISSUE-146]`)**:
   - Allocate `g_buf_pre_rmsnorm_h` in VRAM.
   - Build `g_pipe_copy_pre_rmsnorm` pipeline to copy `g_buf_train_hidden` before RMSNorm execution.
   - Bind `g_buf_pre_rmsnorm_h` to `rmsnorm_backward_post` and `hopfield_backward`, feeding authentic unnormalized input states into backward Jacobians.
4. **Rebalance Token Embedding Gradient Multiplier (`[ISSUE-147]`)**:
   - Increase embedding gradient scale in `geomind_streams_backward` and `geomind_input_grad_update` from `0.025f` to `0.25f`, ending the $40\times$ step-size suppression.
5. **Mark Multi-Domain ATL Moving Average Resolved (`[ISSUE-143]`)**:
   - Confirm per-chunk `domain_losses` tracking and continuous mixture EMA are operating cleanly.

---

## Detailed Technical Design

### 1. Locked Evaluation Temperature (`[ISSUE-144]`)
* Remove adaptive inflation from `g_val_temperature`.
* Enforce `g_val_temperature = 1.0` in `test/geomind/train.cl` controller loop and CLI defaults.

### 2. Manifest Persistence Relocation (`[ISSUE-145]`)
* Move `geomind_manifest_save_interleaved` into `if (math_mod_val(total_chunks_trained, 50.0) == 0.0)`.
* Retain checkpoint saves on epoch completion and target loss termination.

### 3. Scratch Pre-RMSNorm Buffer & Copy Pipeline (`[ISSUE-146]`)
* Declare `g_buf_pre_rmsnorm_h` ($2560 \times 4\text{ bytes} = 10.24\text{ KB}$) in VRAM.
* Build pipeline `g_pipe_copy_pre_rmsnorm` (`geomind_copy_vec`).
* In `train_mount_gpu()`:
  - Bind arg 0 to `g_buf_train_hidden`, arg 1 to `g_buf_pre_rmsnorm_h`, arg 2 to 2560.
  - Update `g_pipe_rmsnorm_backward_post` arg 1 to `g_buf_pre_rmsnorm_h`.
  - Update `g_pipe_hopfield_backward` arg 1 to `g_buf_pre_rmsnorm_h`.
* In `geomind_train_chunk_gpu_pipelined`:
  - Launch `g_pipe_copy_pre_rmsnorm` immediately prior to `g_pipe_rmsnorm`.

### 4. Embedding Gradient Scale Rebalancing (`[ISSUE-147]`)
* Update `geomind_streams_backward`:
  `weights[idx] = weights[idx] - lr * 0.25f * curved_grad;`
* Update `geomind_input_grad_update`:
  `weights[idx] = weights[idx] - lr * 0.25f * g;`

---

## Verification & Acceptance Criteria
- [ ] Clean compilation via `cartanc.exe` targeting native Zig/Clang `-O3` LTO.
- [ ] SHA-256 hash parity verified across `geomind.exe`, `test/geomind/geomind.exe`, and `bin/geomind.exe`.
- [ ] 4/4 semantic vector analogies verified passing cleanly at Rank 1.
- [ ] GPU dry-run confirms:
  - `VTemp = 1.0` locked with no runaway divergence.
  - No disk thrashing on 1-chunk boundaries.
  - Pre-RMSNorm state successfully stashed and bound to backward kernels.
  - `corpus.json` remains cleanly zeroed at dataset 0, offset 0.0.
- [ ] Walkthrough archived in `docs/archive/` and artifact created.
- [ ] `CHANGELOG.md` and `ISSUES.md` updated.
