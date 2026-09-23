# Sprint 403 Plan: Domain-Matched Prequential Holdout Validation & Retired Dataset Purge

## 1. Problem Statement & User Direction
- The user instructed:
  > "You don't need to load 2048 tokens for EVERY dataset that it's got in hold out for every pass. Just the dataset that the next training chunk is going to train on."
- Previously, `geomind_compute_validation_loss` evaluated all cached holdout chunks (10,240 tokens across all domains) on every single evaluation interval, introducing unnecessary latency (~2.5s) and computing metrics across irrelevant domains instead of the active training domain.
- In addition, lines 1–50 of `pretrain_validation_holdout.txt` contained obsolete residual tails from retired datasets (ArXiv and TinyStories) no longer present in `corpus.json`.

## 2. Architectural Design
1. **Purge Obsolete Holdouts (`test/geomind/trainingdata/pretrain_validation_holdout.txt`)**:
   - Delete obsolete ArXiv (lines 1–25) and TinyStories (lines 26–50) paragraphs.
   - Retain only the 5 active dataset families configured in `corpus.json`:
     - Domain 0: FineWeb-Edu (`sft/fineweb_edu_curated.txt`)
     - Domain 1: OpenWebText (`sft/openwebtext_curated.txt`)
     - Domain 2: WikiText-103 (`sft/wikitext103_structural.txt`)
     - Domain 3: Storytelling (`storytelling_corpus_clean.txt`)
     - Domain 4: Mined Discourse (`mined_expanded_corpus_cloze_part01.txt` ... `part06.txt`)
   - Ensure each active family packs cleanly into a dedicated 2048-token holdout chunk.
2. **Domain-Family Resolver (`test/geomind/train.cl`)**:
   - Implement `geomind_get_domain_family(dataset_path: string) -> float`:
     - Returns index `0.0` for FineWeb-Edu, `1.0` for OpenWebText, `2.0` for WikiText-103, `3.0` for Storytelling, and `4.0` for Mined Discourse.
3. **Domain-Targeted Prequential Validation (`test/geomind/train.cl`)**:
   - Update `geomind_compute_validation_loss(val_file: string, cur_h_val: ptr, target_domain: float) -> float`:
     - If `target_domain >= 0.0`: evaluates **only** the 2048-token holdout chunk corresponding to `target_domain`.
     - Reduces validation forward compute time from ~2.5s down to **~0.4s**.
     - Provides authentic domain-aligned generalization metrics for the dataset that is actively training.
     - If `target_domain < 0.0`: evaluates all holdout chunks (for baseline initialization).
4. **Integration into Training Stream**:
   - On each interval, query the domain family of the upcoming dataset `d_idx` (`let target_fam = geomind_get_domain_family(raw_dataset)`).
   - Evaluate validation exclusively on `target_fam`.
5. **Compilation, Verification & Parity**:
   - Recompile `test/geomind/main.car` with `cartanc.exe` and Zig `-O3` LTO.
   - Synchronize bit-for-bit SHA-256 parity across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
   - Verify `geomind.exe --eval-analogy` (4/4 PASS at Rank 1).

## 3. DoD Checklist
- [ ] Code passes static type checking and LLVM IR codegen via `cartanc.exe`.
- [ ] Zero runtime regressions on target benchmarks or test files.
- [ ] All new/modified functions include brief, clear comments explaining intent.
- [ ] Implementation plan, task list, and walkthrough saved to `docs/archive/`.
- [ ] `CHANGELOG.md` updated with concise summary.
- [ ] `ISSUES.md` updated with `[ISSUE-155]`.
