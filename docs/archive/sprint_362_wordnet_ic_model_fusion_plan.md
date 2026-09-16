# Sprint 362: WordNet IC Model Weight Fusion & SLERP Merging Integration

## 1. Context & Objectives
In Sprint 361, WordNet Information Content (IC) weighting proved highly effective at:
1. Eliminating punctuation attractor loops in chat generation.
2. Accelerating loss descent ($4.70 \to 4.19$) and perplexity reduction ($50.90 \to 48.66$) in Stage 2 Pre-Training.

The objective of Sprint 362 is to wire WordNet IC column modulation directly into the model weight merging and SLERP pipeline (`--merge-slerp`), ensuring that any newly merged model weights automatically incorporate bounded IC modulation ($0.80\times$ on punctuation/stop words, $1.20\times$ on semantic concepts) upon creation, pre-plugging the vocabulary manifold before training begins.

## 2. Sprint Backlog & Implementation Tasks
- **Task 1 (Standard Library Fusion Module Enhancement)**:
  - Add `fusion_apply_wordnet_ic_modulation(tensor_ptr: ptr, vocab_cols: float) -> ptr` to `src/std/fusion.cl`.
  - Add `fusion_apply_wordnet_ic_modulation_arrays(arr: ptr, size: float, vocab_cols: float)` to `src/std/fusion.cl`.
  - Preserve `fusion_slerp_tensors` signature and mathematical invariants to ensure zero compiler test suite regressions (e.g. `test_fusion_distill.car`).
- **Task 2 (GeoMind Merge Engine & CLI Dispatch)**:
  - Update `geomind_merge_models_slerp` in `test/geomind/train.cl` to apply `fusion_apply_wordnet_ic_modulation`.
  - Update `--merge-slerp` CLI handler in `test/geomind/main.car` to apply WordNet IC modulation to merged outputs and save `geomind_slerp_fused_weights.bin`.
- **Task 3 (Empirical Verification & Compilation)**:
  - Recompile `test/geomind/main.car` via `cartanc.exe`.
  - Synchronize bit-for-bit SHA-256 binaries across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
  - Run `.\geomind.exe --merge-slerp` and verify successful creation of the IC-modulated fused checkpoint.
  - Run regression test `test_fusion_distill.car` to verify standard library compatibility.
- **Task 4 (Documentation & Closure)**:
  - Update `CHANGELOG.md` and `ISSUES.md`.
  - Save walkthrough to `docs/archive/`.

## 3. Definition of Done (DoD)
- [ ] `src/std/fusion.cl` implements bounded WordNet IC modulation.
- [ ] `test/compiler_suite/test_fusion_distill.car` passes cleanly.
- [ ] `geomind.exe --merge-slerp` runs and produces verified IC-modulated weights.
- [ ] Bit-for-bit SHA-256 synchronization verified across production binary paths.
- [ ] `CHANGELOG.md` and `ISSUES.md` updated.
- [ ] Walkthrough archived in `docs/archive/`.
