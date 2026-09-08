# Sprint 327 Implementation Plan: Cloze Manifest Purification, Path Resilience, and Zero-Step Checkpoint Guard

## 1. Context & Objectives
- **Target**: Resolve Cloze manifest dataset contamination, working directory path resolution gaps, and zero-step false completion.
- **Root Causes**:
  1. `test/geomind/trainingdata/cloze_manifest.json` mistakenly contained `conversational_storytelling_dataset.jsonl` (SFT literary dialogue) as dataset 0.
  2. `test/geomind/train.cl` hardcoded paths starting with `"test/geomind/"`, causing file not found errors when invoked from subdirectories or alternate working directories.
  3. `train.cl` executed completion logic (marking SUCCESS and saving checkpoints) even when 0 training steps occurred due to missing datasets, truncating model weights.
- **Objectives**:
  1. Purify `cloze_manifest.json` to strictly include the 6 genuine mined cloze files (`part01` to `part06`, 240,000 cloze pairs).
  2. Implement `geomind_get_base_prefix()` and `geomind_resolve_path()` in `test/geomind/train.cl` and `test/geomind/main.car` for seamless execution from any CWD.
  3. Install zero-step abort guard preventing checkpoint corruption on missing datasets.
  4. Restore 52.4 MB steady-state weights from `.bin.prior_run`.
  5. Recompile `geomind.exe` with `cartanc.exe` and synchronize across `build/`, `bin/`, and `./`.

## 2. Dependency Graph
```
test/geomind/train.cl (geomind_get_base_prefix, geomind_resolve_path, zero-step guard)
   │
   ├──> test/geomind/main.car (check_and_apply_manifest_reset)
   │
   ├──> test/geomind/trainingdata/cloze_manifest.json (6 mined cloze corpora)
   │
   └──> build/geomind.exe, bin/geomind.exe, geomind.exe
```

## 3. Detailed Execution Steps
1. Restore weights: `geomind_steady_state_weights.bin.prior_run` -> `geomind_steady_state_weights.bin`.
2. Purify manifest: Update `cloze_manifest.json` to 6 mined cloze parts.
3. Edit `test/geomind/train.cl`:
   - Add `geomind_get_base_prefix()` and `geomind_resolve_path()`.
   - Use `geomind_resolve_path()` for manifest, custom datasets, dataset list items, and checkpoints.
   - Update Stage 1 fallback dataset to `mined_expanded_corpus_cloze_part01.jsonl`.
   - Add zero-step epoch guard aborting with error if `ep_step_count <= 0.0`.
4. Edit `test/geomind/main.car`:
   - Use `geomind_resolve_path()` in `check_and_apply_manifest_reset()`.
5. Recompile with `cartanc.exe` and distribute binary to `build/geomind.exe`, `bin/geomind.exe`, `geomind.exe`.
6. Run compiler regression test suite and empirically test `--train-cloze`.
7. Update `ISSUES.md` (`[ISSUE-076]`), `CHANGELOG.md`, and retrospective.
