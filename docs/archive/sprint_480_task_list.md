# Sprint 480 Task List: Non-Euclidean KV-Cache, Topological Boundary Operators & Pure Neural Inference

## Gate 1: Pinned KV-Cache Arena & Native AVX2 SIMD Kernels
- [ ] **Task 1.1**: In `src/std/cartan_native_io.c`, implement 8-way unrolled AVX2 FMA kernels: `c_cartan_gemv_f32`, `c_cartan_rmsnorm_f32`, and `c_cartan_gqa_causal_attention_f32`.
- [ ] **Task 1.2**: In `src/std/transformer.cl`, allocate static contiguous `KV_CACHE_ARENA` (411 MB) and `LAYER_SCRATCH_ARENA` (<100 KB) to eliminate per-token heap churn.
- [ ] **Task 1.3**: Unit test AVX2 kernels against reference CARTAN implementations ensuring numerical delta $< 10^{-5}$.

## Gate 2: Multi-Token Causal Sequence Prefill Pipeline
- [ ] **Task 2.1**: Rewrite `geomind_execute_gemma_layers` in `test/geomind/chat.cl` to take explicit sequence indices and write directly into `KV_CACHE_ARENA`.
- [ ] **Task 2.2**: Replace `cartan_tensor_compute_hidden_state_from_tokens` with token-by-token sequence prefill across all prompt tokens.
- [ ] **Task 2.3**: Verify strict causal masking ($-\infty$ on upper triangular) ensuring zero future token leakage.

## Gate 3: Topological Boundary Framing & Pure Layer Output Propagation
- [ ] **Task 3.1**: In `src/std/tokenizer.cl`, add explicit decode handling for `<start_of_turn>` (106) and `<end_of_turn>` (107).
- [ ] **Task 3.2**: In `src/std/prompt_scaffold.cl`, implement `gemma_scaffold_format_chat` wrapping incoming user prompts with canonical turn delimiters.
- [ ] **Task 3.3**: In `test/geomind/chat.cl`, set generation termination on token 107 (`<end_of_turn>`) and token 1 (`<eos>`), eliminating premature punctuation halting.
- [ ] **Task 3.4**: Completely remove the destructive 50/50 blending in `chat.cl:1096` and `chat.cl:1240`. Route pure $\text{RMSNorm}(h_{42})$ to the LM head and pass $(h_{42} - h_0)$ as the tangent velocity $\dot{x}$ into the Sasaki tangent bundle.

## Gate 4: Zero-Leak Isolation under `--no-expert-priming`
- [ ] **Task 4.1**: In `test/geomind/chat.cl:1014-1039`, guard NSES saliency rule injection into Hopfield memory behind `g_expert_priming_enabled == 1.0`.
- [ ] **Task 4.2**: In `test/geomind/chat.cl:1261-1282`, ensure the veto gate only logs warnings and does not substitute neural text when `g_expert_priming_enabled == 0.0`.
- [ ] **Task 4.3**: In `test/geomind/chat.cl:1154-1174`, guard Tier 3 Warehouse attractor blending behind `g_expert_priming_enabled == 1.0`.
- [ ] **Task 4.4**: Implement `--ephemeral-memory` flag in `test/geomind/main.car` preventing test queries from mutating `hopfield_basins.bin`.

## Gate 5: 40-Item Benchmark Validation & Compiler Regression Safety
- [ ] **Task 5.1**: Curate `test/geomind/trainingdata/pure_neural_eval_suite.json` containing 40 canonical factual queries across 4 domains.
- [ ] **Task 5.2**: Author and execute `tools/eval_pure_neural_benchmark.py` measuring Top-1 Accuracy, MRR, Perplexity, Top-1 Confidence, and Shannon Entropy under `--no-expert-priming`.
- [ ] **Task 5.3**: Run `test/compiler_suite/run_tests.car` verifying all 87 compiler snapshot targets pass cleanly.
- [ ] **Task 5.4**: Update `CHANGELOG.md` and `ISSUES.md`.
