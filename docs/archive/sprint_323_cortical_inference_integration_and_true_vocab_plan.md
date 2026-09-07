# Sprint 323 Implementation Plan: True Vocabulary Alignment, Cortical Weight Inference Integration, and Dense Sequence Supervision

## 1. Goal & Objectives
Unify training and inference so that:
1. `cartan_tensor_compute_lm_head_logits` computes next-token logits directly from trained `g_cortical_weights` instead of hardcoded sinusoidal functions.
2. `geomind_chat_start` loads `geomind_steady_state_weights.bin` into `g_cortical_weights` on startup.
3. `cartan_tensor_train_step` eliminates the 256-class modulo bottleneck, operating on the true token vocabulary ($V = 512$) with $D = 512$ Lie manifold features.
4. `geomind_train_streaming_steady_state` performs dense sequence supervision across 100% of tokens in each chunk rather than skipping 94% of each chunk.

## 2. Structural Changes
1. **`test/geomind/chat.cl`**:
   - In `geomind_chat_start`: Add checkpoint loader for `test/geomind/trainingdata/checkpoints/geomind_steady_state_weights.bin`.
   - In `cartan_tensor_compute_lm_head_logits`: Project $h$ through `g_cortical_weights[r * 2560.0 + c]` for all $c \in [0, 512)$.
2. **`test/geomind/train.cl`**:
   - In `cartan_tensor_train_step`:
     - Size scratch vectors `g_train_logits` and `g_train_probs` to $512.0$.
     - Remove `math_mod_val(target_tok_id, 256.0)`. Validate `target_idx < 512.0`.
     - Evaluate forward dot product, max logit, softmax, cross-entropy loss ($-\ln P_{\text{target}}$), and SGD gradient updates across $D = 512.0$ and $V = 512.0$.
   - In `geomind_train_streaming_steady_state`:
     - Set `window_size = 256.0` and `stride = 256.0`.
     - Supervise all $t < n_{\text{tokens}} - 1.0$ tokens in each chunk, guaranteeing dense, 100% corpus coverage.
3. **Empirical Verification**:
   - Recompile `build/geomind.exe` with `cartanc.exe`.
   - Verify initial loss is mathematically grounded near $\ln(512) \approx 6.24$.
   - Verify training step throughput and loss convergence.
   - Verify that `--chat` loads the trained checkpoint and generates tokens using the cortical weights.
   - Run 62-target compiler regression suite (`build/run_tests.exe`).
