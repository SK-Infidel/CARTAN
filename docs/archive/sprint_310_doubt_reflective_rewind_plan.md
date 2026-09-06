# Sprint 310 Plan: Reflective Skepticism, Doubt Verification (`doubt { }`) & Adaptive CoT Context Rewind

## 1. Context & Objectives
- **Milestone**: Phase 68 (Frontier Model Feature - Kimi / Moonshot AI Skepticism & Self-Correction).
- **Issue**: `[ISSUE-061]` (Dormant Doubt Block Primitives & Missing Adaptive Perplexity Rewind in Conversational Inference).
- **Goal**:
  1. Activate native `doubt { ... }` language block with genuine C runtime hooks (`cartan_rt_doubt_begin`, `cartan_rt_doubt_end`).
  2. Implement authentic Softmax top-1 confidence and Shannon entropy metrics (`cartan_tensor_compute_confidence`) in `src/cartanc/geomind_runtime.c`.
  3. Implement tangent bundle state checkpointing and context rewind (`cartan_doubt_checkpoint`, `cartan_doubt_rewind`).
  4. Implement pure Cartan Level-1 standard library API in `src/std/reasoning.cl`.
  5. Wire reflective doubt verification and adaptive context rewind into conversational decoding in `test/geomind/chat.cl`.
  6. Author Target 62 regression test (`test/compiler_suite/test_doubt_reflective_rewind.car`) and register in `test/compiler_suite/run_tests.car`.

---

## 2. Architectural Dependency Tree
```
Level 0: C Runtime (`src/cartanc/geomind_runtime.c`)
         - cartan_rt_doubt_begin, cartan_rt_doubt_end
         - cartan_tensor_compute_confidence, cartan_tensor_compute_entropy
         - cartan_doubt_checkpoint, cartan_doubt_rewind, cartan_doubt_trigger_rewind
         - cartan_doubt_is_active, cartan_doubt_should_rewind
                 │
                 ▼
Level 1: Language Syntax & Codegen (`src/cartanc/ast.ch`, `parser.car`, `llvm_codegen.car`)
         - doubt { stmts } AST node (already parsed, emits runtime hooks)
                 │
                 ▼
Level 2: Standard Library (`src/std/reasoning.cl`)
         - doubt_begin, doubt_end
         - doubt_checkpoint, doubt_rewind
         - doubt_evaluate_confidence, doubt_evaluate_entropy, doubt_should_rewind
                 │
                 ▼
Level 3: Conversational Inference Engine (`test/geomind/chat.cl`)
         - Live confidence & entropy monitoring during autoregressive decoding
         - Adaptive tangent bundle rewind on uncertainty / contradiction
                 │
                 ▼
Level 4: Verification & Test Harness (`test/compiler_suite/test_doubt_reflective_rewind.car`)
         - Target 62 (5/5 assertions) registered in run_tests.car
```

---

## 3. Work Breakdown
1. **Runtime Implementation (`src/cartanc/geomind_runtime.c`)**:
   - `CartanDoubtState` structure: stores `h_saved[2560]`, `mom_saved[2560]`, `history_saved[256]`, `token_count`, `temp_saved`.
   - `cartan_tensor_compute_confidence`: Softmax max prob and Shannon entropy $H = -\sum p_i \ln p_i$.
   - Checkpoint & rewind primitives.
2. **Standard Library (`src/std/reasoning.cl`)**:
   - Pure Cartan wrappers and doubt control helpers.
3. **Conversational Engine (`test/geomind/chat.cl`)**:
   - Doubt checkpointing before autoregressive generation; step-by-step confidence evaluation.
   - If confidence falls below threshold or entropy exceeds bound, trigger context rewind, cool temperature, and resample.
4. **Regression Test Target 62 (`test/compiler_suite/test_doubt_reflective_rewind.car`)**:
   - Assert `doubt { }` block compilation.
   - Assert Shannon entropy and top-1 confidence differentiation.
   - Assert exact 2560-D manifold checkpoint/rewind fidelity.
   - Assert end-to-end rewind recovery loop.
5. **Update Test Harness & Documentation**:
   - Register in `test/compiler_suite/run_tests.car`.
   - Update `CHANGELOG.md`, `ISSUES.md`, and `docs/ROADMAP.md`.
