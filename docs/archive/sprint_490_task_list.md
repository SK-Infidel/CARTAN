# Sprint 490 Task List: Pure Neural Inference Fidelity, Attention Scaling & Manifold Echo Damping

## Gate 1: Dynamic Prompt Language Detection & Multilingual Masking ([`[ISSUE-292]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md))
- [ ] Implement UTF-8 script/language detection in `test/geomind/chat.cl` (`geomind_detect_prompt_script`).
- [ ] Apply dynamic language-appropriate vocabulary masking in `cartan_tensor_compute_lm_head_logits` across all modes (primed or unprimed).
- [ ] Ensure Zipfian IC damping is correctly evaluated for natural semantic prioritizing.

## Gate 2: Attention Scale Factor $1/\sqrt{d_k}$ in Transformer Decoder
- [ ] Scale query-key inner products by $1/\sqrt{head\_dim}$ in `src/std/transformer.cl:1094`.
- [ ] Verify that all 4 attention tests in Target 83 pass without regressions.

## Gate 3: Continuous Manifold Prompt Echo Attractor Damping & Frequency Decay
- [ ] Implement prompt residual damping in `geomind_chat_generate_reply_multimodal` in `test/geomind/chat.cl`.
- [ ] Add frequency-based repetition decay penalty in `cartan_apply_repetition_penalty`.

## Gate 4: Benchmark Evaluation Harness Alignment
- [ ] Refine multi-token BPE matching in `tools/eval_pure_neural_benchmark.py` for valid prefix completions.

## Gate 5: 3-Stage Bootstrap Fixpoint Rebuild & Empirical Verification
- [ ] Compile `bin/cartanc_stage1.exe` -> `bin/cartanc_fresh.exe` -> `bin/cartanc_stage3.exe`.
- [ ] Prove bitwise fixpoint parity: `SHA256(fresh.ll) == SHA256(stage3.ll)`.
- [ ] Run full regression suite (`tools/run_affected_tests.ps1 -All`) ensuring 87/87 pass.
- [ ] Rebuild `build/geomind.exe` and evaluate pure neural generation.
- [ ] Update `CHANGELOG.md` to `[8.448.0]`, mark `[ISSUE-292]` as FIXED in `ISSUES.md`, and write walkthrough.
