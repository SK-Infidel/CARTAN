# Sprint 447 Implementation Plan: Compiler Input Integrity, Regression Suite Ghost Purge & Authentic Distillation

**Author:** CARTAN Architecture & Engineering Squad  
**Date:** 2026-09-26  
**Archive:** `docs/archive/sprint_447_plan.md`

---

## 1. Executive Sprint Goal
Eliminate legacy ghost targets, silent compiler failure modes on non-existent files, synthetic distillation loops, and bypassed training datasets to enforce 100% genuine operations and zero-mock compliance across CARTAN.

---

## 2. User Stories & Scope

### Story 1: Strict Input File Validation in Compiler Frontend
As a language developer, running `cartanc build <file>` or `cartanc doc <file>` on a missing file must immediately terminate with exit code 1 and a descriptive error message, rather than silently emitting an empty binary with exit code 0.

### Story 2: Elimination of Ghost Targets from Regression Suite
As a QA engineer, `run_tests.car` must only execute verified, existing regression test targets in `test/compiler_suite/`, eliminating legacy ghost targets pointing to deleted files with fake loops.

### Story 3: Authentic Tokenization & Representation in Distillation and WebGPU Training
As an AI engineer, `--train-distill` and `webgpu_run_causal_training_pipeline` must process real tokenized text data and genuine model representations rather than generating synthetic sine and cosine values.

---

## 3. Detailed Technical Design

### A. Compiler Frontend (`src/cartanc/main.car`)
In `main.car`, before reading files for `build`, `run`, `doc`, and `bindgen`:
```cartan
if (cartan_file_exists(input_file) == 0.0) {
    printf("Error: Input file '%s' not found.\n", input_file);
    cartan_flush(0.0);
    return 1.0;
}
```
Recompile `cartanc.exe` with itself (self-hosting).

### B. Regression Test Harness (`test/compiler_suite/run_tests.car`)
1. Fix Target 30: point `doc` command to `src/std/math.cl` or `test/compiler_suite/test_math_string_full.car`.
2. Fix Target 37: `test/geomind/merge_model_weights.cl`.
3. Remove dead targets 38, 39, 40, 41, 46, 47.
4. Renumber all remaining targets sequentially.

### C. Authentic Distillation (`test/geomind/train.cl`, `main.car`, `geomind_app.cl`)
Replace synthetic sine/cosine generator with genuine token logits computed via `cartan_tensor_compute_lm_head_logits` on tokenized sentences from `test/geomind/trainingdata/wordnet_taxonomy.txt`.

### D. WebGPU Causal Training Pipeline (`test/geomind/train.cl`)
In `webgpu_run_causal_training_pipeline`, read `target_file`, tokenize sequences with BPE, and load embeddings from `g_e8_embeddings`.

### E. File Deletion
Remove obsolete `test/geomind/hub.cl`.

---

## 4. Empirical Verification Criteria
1. `cartanc.exe build non_existent_test.car` exits with code 1.
2. `cartanc.exe build test/compiler_suite/test_finsler_randers.car` exits with code 0.
3. Full regression suite compiles and executes cleanly.
4. `geomind.exe --eval-analogy` and `geomind.exe --sleep` pass cleanly.
