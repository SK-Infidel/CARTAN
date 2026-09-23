# Sprint 390 Implementation Plan: Prequential Validation Normalization & Interleaved Stream Cadence

## Root Cause Diagnostics
1. **Validation Perplexity Explosion ($1.46 \times 10^{22}$)**:
   - `geomind_train_chunk_gpu_pipelined(tokens, 0.0)` returns `chunk_loss_sum` (unnormalized sum of cross-entropy loss over all tokens in the chunk).
   - Validation assigned `vl = probe_loss` directly without dividing by `g_last_chunk_valid_steps`, whereas training computed mean per-token loss `tl = interval_loss_sum / interval_step_count`.
   - Furthermore, `g_val_temperature` was not guarded against near-zero values, risking uncalibrated softmax division.
2. **Apparent Stoppage / Long Silent Intervals**:
   - Telemetry cadence was hardcoded to `math_mod_val(total_chunks_trained, 100.0) == 0.0`.
   - Domain slices rotate every 50 chunks. Slices alternated without telemetry feedback, resulting in 15-20 second silent gaps that appeared stalled to the user.
   - Adjusting cadence to every 50 chunks aligns telemetry with each domain slice completion.
3. **Memory Leaks**:
   - `tokens` (`cartan_vec`) and `sample_text` strings inside the steady-state loop were not freed at the end of each line iteration.

## Proposed Modifications
1. [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl):
   - In `geomind_train_chunk_gpu_pipelined`: Clamp `step_temp` to 1.0 if `<= 0.05`.
   - In `geomind_train_token_step_gpu` and `geomind_train_step_cpu`: Clamp `step_temp`/`eff_temp` to 1.0 if `<= 0.05`.
   - In `geomind_train_streaming_steady_state`: Guard `g_val_temperature` at function entry (`if (g_val_temperature <= 0.05) { g_val_temperature = 1.0; }`).
   - In `geomind_train_streaming_steady_state`: Normalize prequential validation loss: `vl = probe_loss / g_last_chunk_valid_steps`.
   - In `geomind_train_streaming_steady_state`: Set telemetry reporting interval to 50 chunks (`math_mod_val(total_chunks_trained, 50.0) == 0.0`).
   - In `geomind_train_streaming_steady_state`: Free `tokens` (`cartan_vec_free(tokens)`) and `sample_text` (`free(sample_text)`) per line.
2. [`test/geomind/trainingdata/corpus.json`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/corpus.json):
   - Reset `current_dataset_index` to 0.0, `current_offset` to 0.0, `current_epoch` to 1.0, `current_lr` to 0.0022, and all `offsets` to 0.0.
3. [`test/geomind/trainingdata/checkpoints/checkpoint_status.txt`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/checkpoints/checkpoint_status.txt):
   - Mark as `SUCCESS` for fresh start.
4. Compilation & Verification:
   - Build `geomind.exe` via `cartanc.exe` with Zig `-O3` LTO.
   - Verify SHA-256 hash synchronization across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
   - Run `--eval-analogy` to ensure vector arithmetic retains 4/4 passing accuracy.
