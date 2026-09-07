# Sprint 324 Implementation Plan: Neural Forward Pass Alignment & Causal Integrity

## 1. Goal
Unify the neural manifold forward pass between training and inference, eliminate causal lookahead leakage in the steady-state trainer, fix character-level repetition penalties, and correct CLI prompt parsing to prevent premature generation truncation.

## 2. Root Cause Analysis
1. **Model Forward Pass Bypass in Training**: `train.cl` called `cartan_tensor_train_step` on raw sine-wave phase vectors `h_state` without running `e8_attention_forward_step` (Sasaki MoE, 8 Lie streams, RMSNorm, 16 FFN cascade). In contrast, `chat.cl` evaluated cortical weights against RMS-normalized manifold vectors (~0.02 scale). Cortical weights were trained on a shortcut representation detached from the model layers.
2. **Causal Lookahead Leakage**: `cartan_tensor_compute_hidden_state_from_tokens(tokens)` pre-computed phase sums across the entire chunk before training, letting future tokens leak into early predictions and artificially collapsing loss.
3. **Premature EOS Truncation**: `chat.cl` only suppressed EOS for `step < 3.0`. At step 3, unpenalized EOS was greedily chosen over characters whose vowels were heavily suppressed by global repetition penalty.
4. **CLI Argument Misdirection**: `--chat -prompt "..."` mistakenly assigned `"-prompt"` as the literal prompt string.

## 3. Tasks
- [ ] Task 1: Refactor `test/geomind/train.cl` training loop to initialize `h_state` causally from token 0 and pass through `e8_attention_forward_step` on every prediction step.
- [ ] Task 2: Refactor `test/geomind/chat.cl` repetition penalty to local bigram/trigram loop suppression and extend EOS protection.
- [ ] Task 3: Fix CLI `-prompt`, `-tokens`, and `-temp` parsing in `test/geomind/main.car`.
- [ ] Task 4: Recompile `build/geomind.exe` with `cartanc.exe`.
- [ ] Task 5: Empirically verify training loss dynamics and chat generation output.
- [ ] Task 6: Run compiler regression suite (62/62 targets).
- [ ] Task 7: Update `CHANGELOG.md`, `ISSUES.md`, and save retrospective archive.
