# Sprint 402 Implementation Plan: Responsive Per-Chunk Telemetry & Clean Starting State Convergence

## 1. Problem Statement & Root Cause
- In Sprint 401, chunk packing was increased from 1 line (~40 tokens) to 2048 tokens ($2\text{K}$).
- Telemetry interval remained hardcoded to every 50 chunks (`math_mod_val(total_chunks_trained, 50.0) == 0.0`).
- At 2048 tokens per chunk (~2.5s GPU compute), 50 chunks requires **102,400 tokens** and **~125 seconds** (>2 minutes) of total silence with zero stdout prints or log writes.
- The user observed the baseline validation evaluation, followed by an apparent freeze/halt.
- Additionally, user requests 1, 2, 6, 7 (corpus reset to offset 0 and clean starting checkpoint) remained pending application.

## 2. Proposed Architectural Changes
1. **Per-Chunk Streaming Heartbeat (`test/geomind/train.cl`)**:
   - Immediately following each completed chunk forward+backward pass, print an immediate 1-line progress heartbeat:
     `[GeoMind Stream] Chunk <N> | Ingested 2048 tokens (<domain>) | Loss: <c_loss> | LR: <lr> | TTemp: <ttemp>`
   - Follow immediately with `cartan_flush(0.0)` to eliminate OS/WDDM terminal buffering stalls.
2. **Scaled Interval Telemetry & Multi-Domain Validation (`test/geomind/train.cl`)**:
   - Scale full telemetry and out-of-sample holdout validation from 50 chunks (102K tokens) to 10 chunks (20.48K tokens / ~25 seconds).
   - Scale checkpoint weight saves from 1000 chunks to 100 chunks (204.8K tokens / ~4 minutes).
3. **Corpus Manifest Reset (`test/geomind/trainingdata/corpus.json`)**:
   - Reset `current_dataset_index` = 0.0, `current_offset` = 0.0, `current_epoch` = 1.0, `current_lr` = 0.0022.
   - Zero out all 10 dataset offsets to 0.0.
4. **Clean Baseline Checkpoint Restoration (`test/geomind/trainingdata/checkpoints/`)**:
   - Backup active weights to `.pre_reset_bak`.
   - Restore clean SLERP baseline weights from `geomind_slerp_fused_weights.bin` to `geomind_steady_state_weights.bin` and `geomind_embedding_weights.bin`.
   - Mark `checkpoint_status.txt` as `SUCCESS`.
   - Archive `logs/stage2_ce_training.log` to `logs/stage2_ce_training_pre_sprint402_reset.log`.
5. **Compilation, Verification & Parity**:
   - Compile with `cartanc.exe` with Zig `-O3` LTO.
   - Synchronize bit-for-bit SHA-256 parity across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
   - Verify `geomind.exe --eval-analogy` (4/4 PASS at Rank 1).

## 3. DoD Checklist
- [ ] Code passes static type checking and LLVM IR codegen via `cartanc.exe`.
- [ ] Zero runtime regressions on target benchmarks or test files.
- [ ] All new/modified functions include brief, clear comments explaining intent.
- [ ] Implementation plan, task list, and walkthrough saved to `docs/archive/`.
- [ ] `CHANGELOG.md` updated with concise summary.
- [ ] `ISSUES.md` updated with `[ISSUE-154]`.
