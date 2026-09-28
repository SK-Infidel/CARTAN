# Sprint 447 Walkthrough: Compiler Input Integrity, Regression Suite Ghost Purge & Authentic Distillation

**Date:** 2026-09-26  
**Author:** CARTAN Architecture & Engineering Squad  
**Sprint Version:** [8.405.0]  
**Archive:** `docs/archive/sprint_447_walkthrough.md`  

---

## 1. Executive Summary

Sprint 447 eliminated long-standing compiler failure modes, ghost test targets, and fake optimization loops left behind by prior developers:
1. **Compiler Input File Validation**: Added `cartan_file_exists` pre-validation to compiler CLI commands (`build`, `run`, `doc`, `bindgen`), eliminating the critical vulnerability where missing files silently resulted in 0-byte AST generation and false pass binaries with exit code 0.
2. **Regression Harness Ghost Purge**: Purged 6 ghost targets pointing to deleted scripts with fake loops from `test/compiler_suite/run_tests.car`, fixed Target 30 and Target 37 paths, created authentic `test_merge_model_weights.car`, and renumbered all 59 valid targets sequentially.
3. **Authentic Teacher-Student Knowledge Distillation**: Replaced synthetic trigonometric generators (`sin`, `cos`) in `--train-distill` with genuine SentencePiece BPE tokenization of WordNet taxonomy text, continuous manifold hidden state extraction, and unit-hypersphere $S^{247}$ cosine similarity logit distributions.
4. **Authentic Dataset Ingestion in WebGPU Causal Training**: Wired genuine file reading of `target_file`, SentencePiece BPE tokenization, and authentic $E_8$ manifold coordinates (`g_e8_embeddings`) across all 8 Lie submanifolds into `webgpu_run_causal_training_pipeline`.
5. **Dead Duplicate File Removal**: Deleted obsolete duplicate `test/geomind/hub.cl`.

---

## 2. Changes Made & Architecture Alignment

### A. Compiler Frontend (`src/cartanc/main.car`)
- Injected `if (cartan_file_exists(input_file) == 0.0)` validation at the entry of all compiler command handlers (`build`, `run`, `doc`, and `bindgen`).
- Recompiled `cartanc.exe` using self-hosted compiler.
- Missing files now exit immediately with code 1 and print: `Error: Input file '<path>' not found.`.

### B. Regression Suite Integrity (`test/compiler_suite/run_tests.car`)
- Fixed Target 30 path: `cartanc.exe doc src/std/math.cl`.
- Ported authentic weight merging verification to `test/compiler_suite/test_merge_model_weights.car` (Target 37).
- Purged 6 ghost targets (38, 39, 40, 41, 46, 47) that pointed to non-existent files deleted in Git commit `c02190d`.
- Renumbered remaining authentic targets 38–59 sequentially (59 total targets).
- Compiled and executed `build/run_tests.exe`: 59/59 targets passed cleanly.

### C. Authentic Distillation (`test/geomind/train.cl`, `main.car`, `geomind_app.cl`)
- In `geomind_distill_train_run()`:
  - Ingests authentic taxonomy text from `test/geomind/trainingdata/wordnet_taxonomy.txt`.
  - Tokenizes input using SentencePiece BPE via `cartan_hub_encode_text_to_tokens()`.
  - Computes continuous manifold hidden states via `cartan_tensor_compute_hidden_state_from_tokens()`.
  - Projects vocabulary logits onto the unit hypersphere $S^{247}$ via `cartan_tensor_compute_lm_head_logits()`.
  - Executes 50 analytical gradient descent steps on genuine logits, reducing KL loss from 0.00762755 to 0.00262627.
- Unified `--train-distill` in `main.car` and `geomind_app.cl` to call `geomind_distill_train_run()`.

### D. WebGPU Causal Training Pipeline (`test/geomind/train.cl`)
- In `webgpu_run_causal_training_pipeline()`:
  - Reads `target_file` (with fallback to `gutenberg_classics.txt`).
  - Tokenizes sequence text with SentencePiece BPE via `cartan_hub_encode_text_to_tokens()`.
  - Populates `g_host_x` using authentic continuous $E_8$ Lie algebra coordinates from `g_e8_embeddings` across all 8 Lie submanifolds.
  - Supervises authentic next-token prediction targets with WordNet Information Content (IC) weights.
  - Frees allocated token buffers.

### E. Codebase Cleanup
- Removed dead duplicate `test/geomind/hub.cl`.

---

## 3. Empirical Verification Results

All 6 validation gates executed with 100% success and exit code 0:

| Gate | Target / Binary | Verification Focus | Exit Code | Result |
|---|---|---|---|---|
| **G1** | `build/test_finsler_randers.exe` | Dynamic Submanifold Strides & Sherman-Morrison Projection (5 gates) | 0 | **PASS** |
| **G2** | `build/test_lie_streams.exe` | 8 Lie Subgroup Stream Operators & C-ABI Transforms (4 gates) | 0 | **PASS** |
| **G3** | `build/test_hybrid_resonant_transformer.exe` | RMSNorm, RoPE, SwiGLU & Dual-Process Resonant Transformer (4 gates) | 0 | **PASS** |
| **G4** | `build/run_tests.exe` | Full Compiler Regression Harness (59 authentic targets) | 0 | **PASS** |
| **G5** | `build/geomind.exe --eval-analogy` | Continuous Manifold Cosine Analogy Arithmetic on $S^{247}$ (4 analogies) | 0 | **PASS** |
| **G6** | `build/geomind.exe --sleep` | Metacognitive Consolidation & Epiphany Discovery (5 phases) | 0 | **PASS** |

### Additional Interactive Verification
- `cartanc.exe build non_existent_file.car`: Exited with code 1 (`Error: Input file 'non_existent_file.car' not found.`).
- `build/geomind.exe --train-distill`: Ingested 78 WordNet tokens, reduced KL divergence from 0.00762755 to 0.00262627.

---

## 4. Issues Resolved

- **[ISSUE-198] [RESOLVED]**: Missing Input File Existence Check in Compiler Frontend Allows Silent False Passes.
- **[ISSUE-199] [RESOLVED]**: Ghost Test Targets and Missing File References in Compiler Regression Suite.
- **[ISSUE-200] [RESOLVED]**: Synthetic Sine/Cosine Mock Logits in Teacher-Student Distillation Pipeline.
- **[ISSUE-201] [RESOLVED]**: Synthetic Token and Embedding Generation Bypassing Input Dataset in WebGPU Causal Training.
