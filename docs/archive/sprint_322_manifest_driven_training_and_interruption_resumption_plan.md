# Sprint 322 Implementation Plan: Multi-Dataset Manifest (`corpus.json`) & Byte-Exact Interruption Resumption Engine

## Goal
Implement a dynamic multi-dataset manifest pipeline (`corpus.json`) that allows users to specify an arbitrary list of datasets to train on sequentially. Persist live training state (`current_dataset_index`, `current_offset`, `current_epoch`) so that interruptions (`Ctrl-C`) safely pause and seamlessly resume from the exact byte position and current weights without losing training progress or restarting from scratch.

## Architecture & Implementation
1. **Manifest File Specification (`test/geomind/trainingdata/corpus.json`)**:
   - `current_dataset_index`: Index of active file in `datasets` array.
   - `current_offset`: Byte offset position within the active file.
   - `current_epoch`: Active epoch number.
   - `datasets`: Ordered list of dataset filepaths (`.txt`, `.jsonl`).
2. **Pure Cartan Manifest Parser & Writer (`test/geomind/train.cl`)**:
   - `geomind_manifest_get_field(json_str, key) -> string`: Extracts scalar values without regex.
   - `geomind_manifest_parse_datasets(json_str) -> ptr`: Extracts string array from `"datasets": [ ... ]` into a Cartan tree.
   - `geomind_manifest_save(path, datasets, cur_idx, cur_offset, cur_epoch)`: Serializes current state to JSON.
3. **Sequential Traversal with Live State Resumption (`test/geomind/train.cl`)**:
   - At startup:
     - If `corpus.json` exists, load `cur_idx`, `cur_offset`, `cur_epoch`, and `datasets`.
     - Check if previous run was `IN_PROGRESS` or clean:
       - Retain current trained weights `geomind_steady_state_weights.bin`.
       - Resume training directly from `datasets[cur_idx]` at `cur_offset`.
   - During training:
     - Iterate through `d_idx` from `cur_idx` to `datasets_count - 1`.
     - Ingest file, step through windows starting at `cur_offset`.
     - Every 500 chunks, update `corpus.json` with `cur_offset` and flush checkpoint.
     - Upon completing a file, set `cur_offset = 0.0`, advance `d_idx = d_idx + 1.0`, and update `corpus.json`.
     - When all datasets in `datasets` complete: full epoch complete! Reset `cur_idx = 0.0`, `cur_offset = 256.0`, advance epoch, and checkpoint weights.
4. **CLI Flag Support (`test/geomind/main.car`)**:
   - Add optional `-manifest <path>` (defaults to `test/geomind/trainingdata/corpus.json`).
   - Add `-reset-manifest` to reset manifest position back to start if desired.
5. **Empirical Verification**:
   - Recompile `build/geomind.exe` via `cartanc.exe`.
   - Test sequential dataset traversal and live state updating in `corpus.json`.
   - Test interruption resumption: verify that terminating and restarting resumes at the exact offset.
   - Run 62-target compiler regression suite (`test/compiler_suite/run_tests.car`).
