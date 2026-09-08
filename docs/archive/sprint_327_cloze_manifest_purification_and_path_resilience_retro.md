# Sprint 327 Retrospective: Cloze Manifest Purification, CWD Path Resilience & Checkpoint Protection

---

## 1. Executive Summary

- **Sprint**: 327
- **Primary Objective**: Purge non-cloze data from `cloze_manifest.json`, resolve working directory path resolution gaps, install zero-step abort guards, and restore steady-state model weights.
- **Trigger**: User reported that an interrupted Cloze run failed to resume, showing `1.0 datasets configured` with missing dataset warnings, while unexpectedly defaulting to `conversational_storytelling_dataset.jsonl`.
- **Outcome**: **SUCCESS**.
  - Purified `cloze_manifest.json` to 6 genuine mined cloze files (`mined_expanded_corpus_cloze_part01..06.jsonl`, 240,000 cloze pairs, 45.5 MB).
  - Built `geomind_get_base_prefix()` and `geomind_resolve_path()` in `test/geomind/train.cl` and `test/geomind/main.car`, guaranteeing transparent file access across root and subdirectories.
  - Implemented zero-step abort guard preventing empty runs from marking `SUCCESS` or truncating checkpoint weights.
  - Restored 52.4 MB cortical weights from `.bin.prior_run`.
  - Recompiled and synchronized `build/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
  - Validated clean startup with 6 datasets mounted from both repo root and `test/geomind` working directories.

---

## 2. Root Cause Analysis

1. **Manifest Dataset Contamination**:
   - In Sprint 325, `conversational_storytelling_dataset.jsonl` (synthesized in Sprint 311 for conversational SFT) was erroneously added as dataset 0 in `cloze_manifest.json`, and set as the default fallback in `train.cl:L678`.
   - The true cloze curriculum consists of the 6 mined cloze files containing 240,000 cloze pairs (`sentence_cloze` and `target_phrase`).
2. **CWD Path Dependency**:
   - Manifest and dataset paths hardcoded with `"test/geomind/"` failed `cartan_file_exists` when the CLI was invoked from subdirectories (`test/geomind/` or `build/`), dropping to the fallback and skipping missing files.
3. **Unprotected Zero-Step Completion**:
   - When 0 training steps were executed due to missing datasets, the training loop completed its epoch loop, reported `SUCCESS`, and invoked `cartan_safetensors_save_tensor_f32`, truncating the checkpoint.

---

## 3. Implemented Solutions

1. **Manifest Purification (`test/geomind/trainingdata/cloze_manifest.json`)**:
   - Configured sequential traversal across the 6 mined cloze corpora (`part01` to `part06`).
   - Initialized to index `0.0`, offset `0.0`, epoch `1.0`.
2. **Path Resolution Helpers (`test/geomind/train.cl`)**:
   - `geomind_get_base_prefix()`: Detects whether execution occurs at repo root or inside `test/geomind`.
   - `geomind_resolve_path()`: Dynamically maps paths with or without `test/geomind/` prefix to active on-disk files.
3. **Zero-Step Checkpoint Guard (`test/geomind/train.cl`)**:
   - Added guard aborting training immediately if `ep_step_count <= 0.0`, preserving checkpoint files and reporting the failure.
4. **Checkpoint Restoration**:
   - Restored 52.4 MB model weights from `geomind_steady_state_weights.bin.prior_run`.
   - Marked `checkpoint_status.txt` as `SUCCESS` to enable clean backup creation.

---

## 4. Empirical Verification

1. **Clean Compilation**:
   - `cartanc.exe build test/geomind/main.car -o build/geomind.exe` succeeded under `-O3 LTO Vectorized Pass Pipeline`.
   - Binaries synchronized identically to `bin/geomind.exe` and `./geomind.exe`.
2. **Dual-CWD Empirical Testing**:
   - Executed from repo root: Restored 6,553,600 parameters, mounted all 6.0 datasets, began streaming `mined_expanded_corpus_cloze_part01.jsonl` (7,367.01 KB).
   - Executed from `test/geomind/`: Correctly resolved paths without `test/geomind/` prefix, mounted all 6.0 datasets, and began training seamlessly.

---

## 5. Artifacts & Deliverables

- `test/geomind/train.cl`: CWD path resilience and zero-step abort guard.
- `test/geomind/main.car`: CWD-independent manifest reset path resolution.
- `test/geomind/trainingdata/cloze_manifest.json`: Purified 6-dataset cloze manifest.
- `ISSUES.md`: Logged and resolved `[ISSUE-076]`.
- `CHANGELOG.md`: Documented Sprint 327 updates.
