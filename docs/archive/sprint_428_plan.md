# Sprint 428 Plan: State Preservation & Metric Continuity on Interleaved Stream Restart

## Goal
Eliminate progress percentage drops, domain EMA spikes, and weight divergence when stopping and restarting multi-domain interleaved steady-state training (`geomind_train_streaming_steady_state`).

## Root Cause Analysis
1. **Progress Drop (45.8% -> 39.3%)**: Shorter datasets like `wikitext103_structural.txt` (8.22 MB) loop back to offset `0.0` after reaching EOF. While in-memory `bytes_ingested_epoch` accumulates continuously, `corpus.json` only recorded instantaneous offsets, causing restart initialization (`initial_bytes = sum(offsets_list)`) to lose the 8.22 MB from completed passes.
2. **Loss Jump (ATL 4.09 -> 5.07)**: `domain_losses` and `val_domain_losses` reset to zeros on launch. The first chunk ingested after restart (`storytelling`, an inherently high-entropy ~7.0b domain) initialized ATL directly to its raw loss (~5.07) because no EMA mixture history existed.
3. **Weight Latency (up to 99 chunks)**: Safetensors binary weights only flushed every 100 chunks. Halting at Chunk 2125 caused a 25-chunk gap where weights in GPU VRAM were lost relative to the stream offset saved in `corpus.json`.

## Architecture & Implementation Strategy
1. **Generic Manifest Array Parser**:
   - Implement `geomind_manifest_parse_float_array(json_str: string, key: string, num_elements: float, default_val: float) -> ptr` in `test/geomind/train.cl`.
2. **Extended Manifest State Serialization**:
   - Implement `geomind_manifest_save_state(path: string, list: ptr, offsets: ptr, cur_idx: float, cur_ep: float, cur_lr: float, bytes_ingested: float, domain_losses: ptr, val_domain_losses: ptr)` in `test/geomind/train.cl`.
   - Persist `"bytes_ingested_epoch"`, `"domain_losses"`, and `"val_domain_losses"`.
   - Keep `geomind_manifest_save_interleaved` backward-compatible.
3. **Seamless State Ingestion on Launch**:
   - Read `"bytes_ingested_epoch"`. If `> 0.0`, initialize `bytes_ingested_epoch = saved_bytes`.
   - Parse `"domain_losses"` and `"val_domain_losses"`.
   - If populated, seed `ema_train_loss` and `ema_val_loss` with the domain mixture average to eliminate the single-domain initial spike.
4. **Synchronized Weight Checkpointing**:
   - Save safetensors binary weights on **every Metacognitive Sleep consolidation**.
   - Tighten regular checkpoint interval from 100 chunks to **50 chunks**.

## Verification Plan
1. Standalone regression suite testing manifest round-trip serialization and deserialization with wrap-around bytes and domain mixture losses.
2. Verify full CARTAN compilation with `cartanc.exe`.
3. Rebuild native `bin/geomind.exe` with Zig `-O3 LTO Vectorized Pass Pipeline`.
4. Verify `bin/geomind.exe --verify`.
