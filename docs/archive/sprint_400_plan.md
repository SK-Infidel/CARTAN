# Sprint 400 Plan: 2048-Token Context Scaling, Validation Recurrent Continuity & Holdout Tail Purge

## 1. Objectives & User Stories
- **Story 1 (2K Context Scaling)**: Scale the maximum token context from 256 to standard 2048 tokens. Upgrade causal attention forward and backward kernels with strided local memory loops and tree reductions. Expand VRAM/host buffers to 2048 steps ($20.97\text{ MB}$ sequence buffer, $32.768\text{ KB}$ loss buffer).
- **Story 2 (Validation Recurrent Continuity)**: Eliminate the validation cold-start penalty by chaining `g_buf_prev_chunk_h` across holdout chunks so validation starts cold only once at chunk 0 and retains narrative context across chunks.
- **Story 3 (Holdout Tail Purge & Realignment)**: Purge obsolete Alpaca Q&A prompts and synthetic nursery templates from `pretrain_validation_holdout.txt`. Reconstruct a clean multi-domain holdout suite aligned with active `corpus.json` datasets (FineWeb-Edu, OpenWebText, WikiText-103, Storytelling, and Mined Discourse).

## 2. Dependency Graph & Impact Analysis
- `train_mount_gpu()` -> compiles `causal_mha_src` and `causal_mha_bwd_src`, allocates `g_buf_chunk_seq_h` ($2048 \times 2560 \times 4$), `g_buf_chunk_loss` ($2048 \times 16$), and `g_host_chunk_loss` ($8192$ floats).
- `geomind_train_chunk_gpu_pipelined()` -> updates token limit clamp to 2048.0. Persists `g_buf_prev_chunk_h` on both training and validation passes (`lr >= 0.0`).
- `geomind_compute_validation_loss()` -> stashes `g_buf_prev_chunk_h` to `g_buf_saved_train_h`, initializes `g_has_prev_chunk_h = 0.0` once at start of holdout, evaluates chunks with continuous recurrence, and restores `g_buf_saved_train_h` and `saved_has_prev` post-validation.
- `pretrain_validation_holdout.txt` -> purged of dead datasets, populated with held-out text from the 5 active corpus families.

## 3. Verification Protocol
- Compile with `cartanc.exe build test\geomind\main.car -o geomind.exe`.
- Verify SHA-256 bit-for-bit parity across `./geomind.exe`, `test/geomind/geomind.exe`, and `bin/geomind.exe`.
- Run `.\geomind.exe --eval-analogy` to verify 4/4 semantic analogies pass cleanly at Rank 1.
- Verify validation cold-start elimination and holdout tokenization in dry run.
