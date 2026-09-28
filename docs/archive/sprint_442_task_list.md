# Sprint 442 Task List: Geometric Realignment & Zero-Mock Stabilization

## Phase 1: Memory & Lifecycle Fixes
- [x] **Task 1.1**: Fix use-after-free in `test/geomind/chat.cl` by moving `prompt_scaffold_free(gen_buffer)` after `veto_gate_scan()` and `geomind_chat_log_turn()`.
- [x] **Task 1.2**: Audit all pointer lifetimes and dynamic frees in `test/geomind/chat.cl` (`cur_h`, `prev_h`, `history`, `mom`, `hidden_state`). Resolved double free of `hidden_state` when `cur_h == hidden_state`, freed `weights` in `e8_attention_engine.cl`.

## Phase 2: Manifold Cosine Projection & Vocabulary Restoration
- [x] **Task 2.1**: Remove `eff_tok >= 2560.0 -> eff_tok = 3.0` clamp and sinusoidal noise in `cartan_tensor_compute_hidden_state_from_tokens`. Replaced with `math_mod_val(tok, 2560.0)`.
- [x] **Task 2.2**: Remove `eff_tok >= 2560.0 -> eff_tok = 3.0` clamp and synthetic cosine harmonics in `cartan_tensor_update_autoregressive_state`.
- [x] **Task 2.3**: Implement continuous manifold cosine similarity projection in `cartan_tensor_compute_lm_head_logits` over active vocabulary with Gemma 30.0 softcapping.
- [x] **Task 2.4**: Implement Zipfian Information Content (IC) prior subtraction and valid vocabulary masking to eliminate distractor noise.

## Phase 3: Zero-Mock Transformer & Target 64 Realignment
- [x] **Task 3.1**: Remove `0.01` placeholder fallbacks in `src/std/transformer.cl` (`cartan_swiglu_mlp_forward`, `cartan_transformer_layer_forward`). Enforce fail-fast non-null assertions.
- [x] **Task 3.2**: Update `test/compiler_suite/test_hybrid_resonant_transformer.car` with real non-null weight matrices and verify distinct output logits (spread `1.12746 > 0.50`).

## Phase 4: Compilation, Empirical Verification & Documentation
- [x] **Task 4.1**: Recompile compiler `cartanc.exe` and test suite (`test_runner.exe` / `run_tests.car`).
- [x] **Task 4.2**: Verify Target 64 runs and passes 100%.
- [x] **Task 4.3**: Compile `geomind.exe` and verify `geomind.exe --chat -prompt "..."` runs cleanly with exit code 0.
- [x] **Task 4.4**: Update `CHANGELOG.md`, `ISSUES.md`, and write `docs/archive/sprint_442_walkthrough.md`.
