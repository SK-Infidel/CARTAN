# Sprint 401 Plan: Dedicated Validation Context Memory & 2048-Token Sequence Packing

## Objective
Decouple validation recurrent memory into dedicated VRAM storage (`g_buf_val_prev_h`), eliminating interval cold-starts, and implement 2048-token sequence packing for both validation holdouts and training streams so both pipelines operate over full matching 2K causal attention context horizons.

## Proposed Changes
1. **Dedicated Validation Recurrent State (`test/geomind/train.cl`)**:
   - Track `g_val_has_prev: float = 0.0` globally.
   - Initialize `g_buf_val_prev_h` with zero hidden state in `train_mount_gpu()`.
   - In `geomind_compute_validation_loss`:
     - Stash training's `g_buf_prev_chunk_h` into `g_buf_saved_train_h`.
     - Load `g_buf_val_prev_h` into `g_buf_prev_chunk_h` and set `g_has_prev_chunk_h = g_val_has_prev` (cold only on initial step 0).
     - Execute validation chunks sequentially with continuous recurrence.
     - Persist terminal validation state into `g_buf_val_prev_h` and set `g_val_has_prev = 1.0`.
     - Cleanly restore training state from `g_buf_saved_train_h`.
2. **2048-Token Validation Holdout Packing (`test/geomind/train.cl`)**:
   - In `geomind_init_val_cache`: Pack consecutive holdout lines into full 2048-token chunks in `g_cached_val_chunks`.
   - Free packed chunks cleanly in `geomind_free_val_cache`.
3. **2048-Token Training Stream Packing (`test/geomind/train.cl`)**:
   - In `geomind_train_streaming_steady_state`: Pack consecutive lines from the active domain into 2048-token chunks before calling `geomind_train_chunk_gpu_pipelined`.
   - Advance domain offsets and byte counters by the full span of packed lines.
4. **Verification & Parity**:
   - Compile via `cartanc.exe build test\geomind\main.car -o geomind.exe`.
   - Synchronize across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
   - Run `.\geomind.exe --eval-analogy` to ensure 4/4 semantic analogies pass at Rank 1.
   - Update `ISSUES.md` (`[ISSUE-153]`), `CHANGELOG.md` (`[8.359.0]`), and archive walkthrough.
