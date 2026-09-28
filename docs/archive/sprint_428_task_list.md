# Sprint 428 Task List: State Preservation & Metric Continuity on Interleaved Stream Restart

- [ ] **Task 1: Generic Float Array Manifest Parser**
  - Implement `geomind_manifest_parse_float_array(json_str: string, key: string, num_elements: float, default_val: float) -> ptr` in `test/geomind/train.cl`.
  - Wire `geomind_manifest_parse_offsets` to use the unified array parser with backward-compatibility fallback.

- [ ] **Task 2: Extended Manifest State Serialization**
  - Implement `geomind_manifest_save_state(path: string, list: ptr, offsets: ptr, cur_idx: float, cur_ep: float, cur_lr: float, bytes_ingested: float, domain_losses: ptr, val_domain_losses: ptr)` in `test/geomind/train.cl`.
  - Update `geomind_manifest_save_interleaved` to call `geomind_manifest_save_state`.
  - Update per-chunk manifest save in `geomind_train_streaming_steady_state` to pass `bytes_ingested_epoch`, `domain_losses`, and `val_domain_losses`.

- [ ] **Task 3: Seed Domain Losses & EMA on Interrupted Run Restart**
  - In `geomind_train_streaming_steady_state`, load `bytes_ingested_epoch` from manifest if present; use as `initial_bytes`.
  - Load `domain_losses` and `val_domain_losses` from manifest.
  - If valid entries exist, seed `ema_train_loss` and `ema_val_loss` with the domain mixture average to prevent cold-start loss spikes.

- [ ] **Task 4: Checkpoint Weights on Metacognitive Sleep & 50-Chunk Cadence**
  - Sync and save safetensors weights during Metacognitive Sleep consolidation.
  - Tighten interval check from 100 chunks to 50 chunks (`math_mod_val(total_chunks_trained, 50.0) == 0.0`).

- [ ] **Task 5: Empirical Regression Testing & Rebuilding**
  - Write regression suite `test/geomind/nses/test_sprint15_manifest_state_continuity.car`.
  - Verify clean compilation with `cartanc.exe`.
  - Rebuild native `bin/geomind.exe` with Zig `-O3 LTO Vectorized Pass Pipeline`.
  - Verify `bin/geomind.exe --verify`.
  - Copy updated `geomind.exe` across all workspace locations.
  - Update `ISSUES.md`, `CHANGELOG.md`, and write `sprint_428_walkthrough.md`.
