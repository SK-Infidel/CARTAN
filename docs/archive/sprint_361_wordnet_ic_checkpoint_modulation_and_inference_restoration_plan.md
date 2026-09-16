# Sprint 361: WordNet IC Checkpoint Modulation, Repetition Penalty Windowing, and Inference Parity Restoration

## 1. Context & Objectives
Inference via `--chat` currently collapses into alternating punctuation loops (` a different some of ? . - the , . , . A , of , of . , . , of , . , . , , . , . , `).
Code review identified four interacting root causes:
1. **Online Hebbian Mutation during Inference**: `test/geomind/chat.cl:501` invokes `cartan_hebbian_step_token(cur_h, sampled_tok, 0.5, 0.0005)`, actively mutating cortical weights during token generation and forming runaway reinforcement loops on frequent tokens.
2. **Alternating 2-Gram Repetition Penalty Blind Spot**: `cartan_apply_repetition_penalty` in `test/geomind/chat.cl` only penalizes `last_tok` and checks `last_tok == prev2` (consecutive 1-gram repetition), completely missing alternating 2-grams (`hist[N-1] != hist[N-2]`).
3. **Double Temperature Division**: `cartan_tensor_compute_lm_head_logits` scales logits by `inv_t = 1.0 / t` before Gemma logit soft-capping (`30.0 * tanh(...)`), and `cartan_tokenizer_sample_topp_topk` divides by `t` again before softmax, squaring temperature attenuation ($T^2$).
4. **Punctuation Attractor Bias in Cloze Checkpoint**: Cloze training focused on short local transition bridges, over-converging column weights for punctuation and stop words (`.`, `,`, `a`, `the`, `of`, `to`, `in`, `and`).

## 2. Sprint Backlog & User Stories
- **Story 1 (Inference Engine Hardening)**: Disable runtime Hebbian weight mutation during inference in `test/geomind/chat.cl`, extend repetition penalty to a 32-token sliding window with distance decay and alternating 2-gram suppression, and remove redundant temperature division before tanh soft-capping.
- **Story 2 (WordNet IC Checkpoint Column Modulation)**: Develop `tools/modulate_checkpoint_wordnet_ic.py` to create a verified backup (`geomind_steady_state_weights.bin.pre_ic_bak`) and modulate columns in `geomind_steady_state_weights.bin` (float64 $2560 \times 2560$) by bounded IC factors ($0.80\times$ for punctuation/stop words, $1.20\times$ for WordNet synsets, $1.00\times$ for general vocab).
- **Story 3 (Training Engine IC Loss Weighting)**: Connect `semantics_load_taxonomy` and `tokenizer_get_ic_weight(target_tok)` in `test/geomind/train.cl` so cross-entropy loss and backprop deltas in both OpenCL kernel (`geomind_softmax_loss_delta`) and CPU fallback are scaled by IC.
- **Story 4 (Compilation & Verification)**: Recompile `test/geomind/main.car` with `cartanc.exe`, synchronize binaries across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`, and empirically verify generation with `.\geomind.exe --chat`.

## 3. Definition of Done (DoD)
- [ ] Safe backup `geomind_steady_state_weights.bin.pre_ic_bak` created before weight modulation.
- [ ] `tools/modulate_checkpoint_wordnet_ic.py` executed successfully with genuine float64 calculations.
- [ ] `test/geomind/chat.cl` edited with precise line-by-line updates (zero Hebbian mutation in inference, 32-token window repetition penalty, clean Gemma soft-capping).
- [ ] `test/geomind/train.cl` wired with IC loss weighting.
- [ ] Binary recompiled with `cartanc.exe` and synchronized across production locations with identical SHA-256.
- [ ] Empirical generation verification confirms no `, . , .` collapse.
- [ ] `CHANGELOG.md` and `ISSUES.md` updated.
- [ ] Walkthrough archived in `docs/archive/`.
