# Sprint 357 Plan: Missing Manifest Auto-Creation & Non-Destructive Initialization Guard

## 1. Objectives & Scope
- **Non-Destructive Manifest Guard**: Ensure that if a manifest file already exists on disk, training startup leaves it untouched and resumes without modifying its contents or resetting offset/epoch.
- **Auto-Creation on Missing Manifest**: When a multi-dataset manifest (`cloze_manifest.json` for Stage 1, `corpus.json` for Stage 2, `hf_alpaca_stories.txt` for Stage 3) does not exist on disk, scan all available part files (`part01` through `part06`), populate `datasets_list`, activate `manifest_mode = 1.0`, and immediately persist a valid initial manifest JSON.
- **Maintain Low Entropy**: Zero mock/simulation, line-by-line surgical edits, zero impact on active root training session.

## 2. Technical Design & File Changes
- Target file: `test/geomind/train.cl`
- Logic:
  1. Check `manifest_already_existed = cartan_file_exists(manifest_path)`.
  2. If existed: read, parse, and load state without writing to disk.
  3. If missing and no custom target provided:
     - For `stage_mode == 1.0`: dynamically discover all existing `mined_expanded_corpus_cloze_part*.jsonl` (parts 01–06).
     - For `stage_mode == 2.0`: discover `storytelling_corpus.txt`.
     - For `stage_mode == 3.0`: discover `hf_alpaca_stories.txt`.
     - Set `manifest_mode = 1.0` and call `geomind_manifest_save` to initialize the missing manifest.
     - Log clean notification to stdout.

## 3. Verification Plan
- Build `test/geomind/geomind.exe` with `cartanc.exe`.
- Run validation test in `scratch/`:
  - Verify missing manifest scenario: pass non-existent manifest path, verify it creates the manifest with all parts.
  - Verify existing manifest scenario: pass existing manifest path, verify it loads without modifying or overwriting.
- Synchronize binary to `bin/geomind.exe`.
