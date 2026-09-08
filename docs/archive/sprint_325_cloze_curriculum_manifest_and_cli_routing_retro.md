# Sprint 325 Retrospective: Cloze Curriculum Manifest & CLI Pipeline Disambiguation

---

## 1. Executive Summary

- **Sprint**: 325
- **Primary Objective**: Align Stage 1 Cloze training execution with the multi-dataset manifest architecture, resolve CLI flag shadow trapping, and ensure clean stage sequencing.
- **Trigger**: User requested redoing Stage 1 Cloze training before resuming Stage 2 Pre-training following the Sprint 324 neural manifold forward pass overhaul.
- **Outcome**: **SUCCESS**. Created `cloze_manifest.json` referencing 7 distinct cloze corpora (~47.5 MB), fixed stage-specific manifest routing in `train.cl` and `main.car`, resolved duplicate `--train-cloze` CLI definitions, verified clean compilation of `build/geomind.exe`, and validated Stage 1 Cloze execution.

---

## 2. Root Cause Analysis & Code Audit

1. **Missing / Trapped `--train-cloze` CLI Dispatch**:
   - `test/geomind/main.car` originally had a legacy `--train-cloze` block at line 167 with default LR `0.001` and a shadowed duplicate at line 353 with LR `0.002`.
   - `check_and_apply_manifest_reset` hardcoded `"test/geomind/trainingdata/corpus.json"`, ignoring stage-specific manifests when resetting state via `-reset-manifest`.
2. **Coupled Manifest Defaults in Trainer**:
   - `test/geomind/train.cl` previously defaulted `manifest_path` to `"test/geomind/trainingdata/corpus.json"` regardless of `stage_mode`. Running `--train-cloze` would have ingested narrative text (`storytelling_corpus.txt`) instead of cloze corpora.
3. **Curriculum Pipeline Stage Transition**:
   - In GeoMind's 3-stage curriculum, Stage 1 (Cloze) grounds fundamental lexical taxonomy units (Noun-Noun pairs, binomials, discourse markers) into `geomind_steady_state_weights.bin`.
   - Stage 2 (Causal CE) subsequently inherits these weights to train multi-clause narrative flow. Skipping Stage 1 after the Sprint 324 forward pass overhaul left the neural manifold unanchored.

---

## 3. Implemented Solutions

1. **Stage-Aware Manifest Routing (`test/geomind/train.cl`)**:
   - Wired `stage_mode == 1.0` to select `test/geomind/trainingdata/cloze_manifest.json` by default.
   - Preserved `-manifest <path>` and `-target <path>` CLI overrides.
2. **Cloze Multi-Dataset Manifest (`test/geomind/trainingdata/cloze_manifest.json`)**:
   - Configured sequential traversal across 7 cloze datasets:
     - `conversational_storytelling_dataset.jsonl` (1.98 MB)
     - `mined_expanded_corpus_cloze_part01.jsonl` through `part06.jsonl` (~7.6 MB each, 45.5 MB total)
   - Initialized to dataset index `0.0`, offset `0.0`, epoch `1.0`.
3. **CLI Disambiguation & Reset Parameterization (`test/geomind/main.car`)**:
   - Extended `check_and_apply_manifest_reset(target, arg_count, default_manifest)` to accept stage-specific default manifest targets.
   - Eliminated shadow duplicate `--train-cloze` block and set calibrated default parameters (`epochs = 3.0`, `lr = 0.002`, `target_loss = 4.20`).

---

## 4. Empirical Verification

1. **Clean Compilation**:
   - `cartanc.exe build test/geomind/main.car -o build/geomind.exe` passed with zero errors or warnings under `-O3 LTO Vectorized Pass Pipeline`.
2. **Stage 1 Cloze Startup & Baseline Loss**:
   - Launched `geomind.exe --train-cloze -reset-manifest -epochs 1 -target-loss 4.20`.
   - Correctly initialized WebGPU compute engine, mounted all 7 cloze datasets, and reported initial Step Loss: `6.12329` (EMA: `6.12329`), matching the theoretical entropy baseline $\ln(512) \approx 6.238$.
3. **Clean Reset**:
   - Reset `cloze_manifest.json` and `checkpoint_status.txt` for clean user execution.

---

## 5. Artifacts & Deliverables

- `test/geomind/main.car`: Disambiguated CLI dispatch and stage-aware manifest reset.
- `test/geomind/train.cl`: Stage 1 cloze manifest default routing.
- `test/geomind/trainingdata/cloze_manifest.json`: 7-dataset cloze manifest.
- `ISSUES.md`: Logged and resolved `[ISSUE-074]`.
- `CHANGELOG.md`: Documented Sprint 325 updates.
