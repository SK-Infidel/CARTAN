# Sprint 404 Plan: Prequential Stream Validation Architecture & Low-Entropy Codebase Cleanup

## 1. Problem Statement & User Directive
- The user instructed:
  > "That's all I'm saying we need to do with validation.. do a read ahead that will validate the upcoming chunk that the training read ahead was pulled for."
  > "Yes.. and clean up this mess we just made."
- The existing validation architecture relied on separate static holdout files (`pretrain_validation_holdout.txt`), separate token caching trees (`g_cached_val_chunks`), domain delimiters, and disconnected recurrent context buffers (`g_buf_val_prev_h`).
- This caused:
  1. A persistent cold-start and perplexity gap between training and validation due to disjoint domain snippets.
  2. Redundant memory overhead and file parsing scaffolding.
  3. High entropy and complexity.

## 2. Prequential Architecture (Test-Then-Train)
1. **Prequential Validation of Upcoming Chunk**:
   - In `geomind_train_streaming_steady_state`, when 2,048 tokens are pulled from the active dataset `d_idx` (`train_tokens`):
   - On evaluation intervals (and baseline startup):
     - Before taking any gradient updates with `lr > 0.0`, run a pure forward pass on `train_tokens` with $T=1.0, lr=0.0$:
       `let val_loss = geomind_train_chunk_gpu_pipelined(train_tokens, 0.0);`
     - Because the model has never trained on `train_tokens`, this produces the mathematically pure out-of-sample prediction loss on the upcoming text.
     - Because it inherits the warm recurrent state of domain `d_idx` (`g_buf_domain_h[d_idx]`), it has the **exact matching context depth** as training with **zero cold-start**.
     - Validation and training perplexity are now measured on the identical context horizon.
2. **Codebase & Scaffolding Cleanup**:
   - Remove `geomind_init_val_cache`, `geomind_free_val_cache`, `g_cached_val_chunks`, `g_cached_val_count`, `g_cached_val_file`.
   - Remove `geomind_compute_validation_loss` and `geomind_get_domain_family`.
   - Remove `g_buf_val_prev_h` and `g_val_has_prev`.
   - Purge `pretrain_validation_holdout.txt` and legacy holdout references.
   - Clean up `scratch/` test files.
3. **Compilation, Verification & Parity**:
   - Recompile `test/geomind/main.car` with `cartanc.exe` and Zig `-O3` LTO.
   - Verify bit-for-bit SHA-256 parity across all 3 targets (`test/geomind/geomind.exe`, `bin/geomind.exe`, `./geomind.exe`).
   - Verify `geomind.exe --eval-analogy` (4/4 PASS at Rank 1).
   - Reset `corpus.json` and checkpoints to clean state for user launch.

## 3. DoD Checklist
- [ ] Code passes static type checking and LLVM IR codegen via `cartanc.exe`.
- [ ] Zero runtime regressions on target benchmarks or test files.
- [ ] All new/modified functions include brief, clear comments explaining intent.
- [ ] Implementation plan, task list, and walkthrough saved to `docs/archive/`.
- [ ] `CHANGELOG.md` updated with concise summary.
- [ ] `ISSUES.md` updated with `[ISSUE-156]`.
