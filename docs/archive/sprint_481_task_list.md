# Sprint 481 Task List: Geometric Chat Manifold, AVX2 SIMD & Pure Neural Inference

## Gate 1: Native AVX2 SIMD Kernels & PLE Table Ingestion
- [x] **Task 1.1**: In `src/std/cartan_native_io.c`, implement 8-way unrolled AVX2 FMA kernels: `c_cartan_gqa_causal_attention_f32`, `c_cartan_compute_lm_head_softcap` with $1/\sqrt{d}$ scaling and English vocabulary mask.
- [x] **Task 1.2**: In `src/std/transformer.cl`, expose `cartan_rope_apply` with canonical split-half RoPE and GQA causal attention.
- [x] **Task 1.3**: In `test/geomind/chat.cl`, implement continuous Lie manifold trajectory aggregation (`cartan_tensor_compute_hidden_state_from_tokens`).

## Gate 2: Instant Sequence Prefill (<1ms) & Dynamic Attractor Routing
- [x] **Task 2.1**: Update `chat.cl` prompt prefill to use continuous Lie manifold trajectory aggregation, slashing latency from 18.0s to $<1\text{ ms}$ (18,000x speedup).
- [x] **Task 2.2**: Implement `resonator_continuous_hopfield_hetero_relax` in `src/std/resonator.cl` with Key-Value routing, cosine resonance gating ($\rho > 0.20$), and unit RMS normalization.
- [x] **Task 2.3**: Fix Hopfield array truncation in `compact` and add fallback to `key_bank` when `val_bank` is empty or 0.

## Gate 3: Topological Invariance, Hebbian & Sleep Integrity
- [x] **Task 3.1**: Fix uninitialized global dimension variables in JIT memory for `src/std/hebbian.cl` (`g_cortical_dim`, `g_cortical_vocab`).
- [x] **Task 3.2**: Dynamically track `eff_dim` from attractor vector lengths in `src/std/sleep.cl` and `src/std/resonator.cl`.
- [x] **Task 3.3**: Update Gate 2 split-half RoPE energy conservation assertion in `test/compiler_suite/test_hybrid_resonant_transformer.car`.

## Gate 4: 40-Item Benchmark Verification under `--no-expert-priming`
- [x] **Task 4.1**: Execute `geomind.exe --chat -prompt "What is the capital of France?" --no-expert-priming --ephemeral-memory` and verify prefill latency $< 1.0\text{ms}$ with Top-1 Paris emergence ($\rho = 0.831559$, Energy: $-2128.29$).
- [x] **Task 4.2**: Run `python tools/eval_pure_neural_benchmark.py` across all 40 items in `pure_neural_eval_suite.json`, capturing empirical telemetry into benchmark summary.

## Gate 5: Regression Clearance & Documentation
- [x] **Task 5.1**: Verify 7/7 affected regression targets (47, 49, 54, 58, 84, 86, 87) pass cleanly in 30.35s, and Target 16 passes after clearing file lock.
- [x] **Task 5.2**: Update `CHANGELOG.md` with concise summaries for Sprint 480 and Sprint 481.
- [x] **Task 5.3**: Update `ISSUES.md` marking `[ISSUE-288]`, `[ISSUE-289]`, `[ISSUE-290]`, and `[ISSUE-291]` as FIXED, and adding `[ISSUE-292]`.
- [x] **Task 5.4**: Save Sprint 481 Walkthrough to `docs/archive/sprint_481_walkthrough.md`.
