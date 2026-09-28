# Comprehensive Startup Code Review & Dependency Graph: Sprint 447

**Reviewer:** CARTAN Architecture & Engineering Squad  
**Date:** 2026-09-26  
**Archive:** `docs/archive/startup_code_review_sprint447.md`

---

## 1. Executive Codebase Audit Findings

Following the empirical completion of the Finsler-Randers Sherman-Morrison dual cotangent projection (Sprint 446 / Target 65), a comprehensive systemic audit was executed across the compiler, standard library, and model stack to uncover legacy Euclidean assumptions, fake/mock code, and technical debt left behind by prior teams.

### Finding 1: Silent Compiler Pass on Non-Existent Input Files (`src/cartanc/main.car`)
- **Location**: `src/cartanc/main.car` lines 329, 395, 432.
- **Defect**: When executing `cartanc build <file.car>`, `cartanc doc <file.car>`, or `cartanc bindgen <file.car>`, the compiler never checks `cartan_file_exists(input_file)`. If the target file does not exist, `cartan_read_file` returns an empty string (length 0), the lexer emits a single EOF token, an empty AST is generated, and Zig links an empty binary exiting with code 0!
- **Consequence**: This silent pass enabled prior teams to claim test targets were passing when the source files did not even exist on disk.
- **Fix**: Inject `if (cartan_file_exists(input_file) == 0.0)` checks at the start of all command handlers; emit clear diagnostic error and terminate with exit code 1.0.

### Finding 2: Ghost Targets in Compiler Regression Suite (`test/compiler_suite/run_tests.car`)
- **Location**: `test/compiler_suite/run_tests.car` targets 30, 37, 38, 39, 40, 41, 46, 47.
- **Defect**: Seven targets point to files that either do not exist or have wrong extensions:
  - Target 30: `cartanc.exe doc src/std/math.car` (`src/std/math.cl` exists, not `.car`).
  - Target 37: `test/geomind/merge_model_weights.car` (file is actually `.cl`).
  - Target 38: `test/geomind/train_teacher_student.car` (deleted in Git commit `c02190d` on Sep 1, 2026).
  - Target 39: `test/geomind/run_full_zero_day_training.car` (deleted in Git commit `c02190d`).
  - Target 40: `test/geomind/test_real_hf_fetch.car` (deleted in Git commit `063386c`).
  - Target 41: `test/geomind/run_chat_generation_benchmarks.car` (deleted in Git commit `c02190d`).
  - Target 46: `test/geomind/run_geomind_hybrid_training.car` (deleted in Git commit `c02190d`).
  - Target 47: `test/geomind/run_heavy_production_training.car` (deleted in Git commit `c02190d`).
- **Discovery**: In the deleted files, training was completely faked (e.g. `student_val = student_val + 0.04` and `+ 0.028` hardcoded increments over 50–100 steps to satisfy `static_assert(final_loss < initial_loss)` without computing gradients).
- **Fix**: Remove obsolete ghost model targets from the compiler regression suite; ensure all regression targets are genuine compiler unit tests in `test/compiler_suite/`.

### Finding 3: Synthetic Sine/Cosine Logits in Distillation Pipelines (`test/geomind/`)
- **Location**: `test/geomind/train.cl` lines 3271–3277, `test/geomind/main.car` lines 934–939, and `test/geomind/geomind_app.cl` lines 153–158.
- **Defect**: When invoking `--train-distill`, teacher and student logits are synthesized via toy sinusoidal formulas:
  `let t_val = 2.0 + sin((k + 1.0) * 0.1) * 0.5;`
  `let s_val = 0.5 + cos((k + 1.0) * 0.1) * 0.3;`
- **Fix**: Connect `--train-distill` to genuine teacher checkpoint forward passes or genuine token vocabulary logit distributions.

### Finding 4: Synthetic Embedding Pipeline in WebGPU Causal Engine (`test/geomind/train.cl`)
- **Location**: `test/geomind/train.cl` lines 1266–1280.
- **Defect**: `webgpu_run_causal_training_pipeline` accepts `dataset_path` but never reads the file. Instead, it generates synthetic token indices `tok_id = (step * 7.0 + t_idx * 13.0)` and synthetic embeddings `sin((tok_id + 1.0) * (d + 1.0) * 0.001)`.
- **Fix**: Wire real text tokenization from `dataset_path` through `bpe_tokenize_sequence` into the WebGPU buffer pipeline.

### Finding 5: Fake Fallback Weights in Unused Duplicate `test/geomind/hub.cl`
- **Location**: `test/geomind/hub.cl` lines 70–78.
- **Defect**: On safetensors header failure, `test/geomind/hub.cl` generated `sin(i * 0.1)` fake weights.
- **Fix**: Remove unmaintained duplicate `test/geomind/hub.cl` (the codebase uses `src/std/hub.cl`).

---

## 2. Logical Dependency Tree

```
┌────────────────────────────────────────────────────────┐
│                   Cartan Compiler Core                 │
│  src/cartanc/lexer.car -> parser.car -> codegen.car    │
│  src/cartanc/main.car (CLI Entry & File Existence Guard│
│  src/cartanc/core_runtime.car (C ABI / Memory Safety)   │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│                  Cartan Standard Library               │
│  src/std/math.cl (Transcendentals, modulo, abs)        │
│  src/std/collections.cl (Lists, Stacks, Trees)         │
│  src/std/fs.cl & gpu.cl (Binary buffers, WebGPU/OpenCL)│
│  src/std/geom.cl (Sherman-Morrison dual Randers, FRS)  │
│  src/std/tokenizer.cl (Genuine SentencePiece BPE)      │
│  src/std/resonator.cl (Continuous Hopfield memory)     │
│  src/std/transformer.cl (RMSNorm, RoPE, SwiGLU, GQA)   │
│  src/std/fusion.cl (Riemannian SLERP, TIES, DARE)      │
│  src/std/distill.cl (KL divergence logit matching)     │
│  src/std/sleep.cl (NSES Metacognitive Consolidation)   │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│               Compiler Regression Test Suite           │
│  test/compiler_suite/run_tests.car (Targets 1..65)     │
│  test/compiler_suite/test_finsler_randers.car (T65)    │
│  test/compiler_suite/test_hybrid_resonant_transformer  │
│  test/compiler_suite/test_lie_streams.car (T52)        │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│                   GeoMind Model Stack                  │
│  test/geomind/geometry.cl (240 E8 Roots, Weyl group)   │
│  test/geomind/streams.cl (8 Lie Subgroup Decompositions│
│  test/geomind/moe.cl (Sasaki Tangent Router & MoE)     │
│  test/geomind/chat.cl (262k Cosine Projection on S^247)│
│  test/geomind/train.cl (Steady-State Training Engine)  │
│  test/geomind/main.car (Production CLI: chat, train...)│
└────────────────────────────────────────────────────────┘
```

---

## 3. Risk Assessment & Mitigations

1. **Risk: Strict File Existence Breaks Ghost Tests**:
   - *Mitigation*: Purge ghost targets from `test/compiler_suite/run_tests.car` so the compiler test suite only measures verified, existing tests.
2. **Risk: Breaking Compiler Self-Hosting**:
   - *Mitigation*: Verified that `cartanc.exe build src/cartanc/main.car -o build/cartanc_new.exe` succeeds cleanly before modifying compiler code.
3. **Risk: Distillation Divergence with Real Logits**:
   - *Mitigation*: Ensure temperature scaling ($T \ge 2.0$) and analytical gradient bounds prevent logit explosion when real token distributions are processed.
