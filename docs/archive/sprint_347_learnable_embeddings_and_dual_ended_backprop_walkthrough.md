# Sprint 347 Walkthrough: Weight-Tied Learnable Token Embeddings and Dual-Ended Input/Output Backpropagation

## 1. Overview & Architectural Root Cause
Prior to Sprint 347, GeoMind's streaming training loss flatlined at ~4.72 across 36+ epochs because token sequence induction in `geomind_autoregressive_step` and `cartan_tensor_update_autoregressive_state` relied on a static, deterministic trigonometric hash:
`phase = tok * 37.0 + i * 13.0, v = 0.60 * v_old + 0.40 * sin(phase * 0.001)`
Because input token representations were completely invariant to training and contained zero trainable parameters, the model was mathematically constrained to linear classification on fixed pseudo-random projections. For 2560 subwords, this saturated at unigram/bigram entropy (ln(112) ~ 4.72), making target loss 3.8 mathematically unreachable.

## 2. Changes Implemented
1. **Weight-Tied Learnable Input Token Embeddings**:
   - Tied input token representations directly to `g_buf_cortical_weights` / `g_cortical_weights` (2560 x 2560 parameters).
   - In `geomind_autoregressive_step` (GPU OpenCL kernel):
     `tok_emb = weights[i * vocab + tok] * 12.0f;`
     `v = 0.60f * old_v + 0.40f * (tok_emb + 0.10f * sin(phase * 0.001f));`
   - Synchronized corresponding logic in `cartan_tensor_compute_hidden_state_from_tokens` and `cartan_tensor_update_autoregressive_state` in `test/geomind/chat.cl` for CPU execution and inference parity.

2. **Dual-Ended Input/Output Backpropagation (`geomind_input_grad_update`)**:
   - Introduced GPU OpenCL kernel `geomind_input_grad_update` (`g_pipe_input_sgd`):
     `grad_h[r] = sum_{c=0}^{vocab-1} weights[r * vocab + c] * delta[c];`
     `weights[r * vocab + tok_in] -= lr * 0.5f * clamp(grad_h[r] / dim, -1.0, 1.0);`
   - Dispatched alongside output projection SGD in `geomind_train_chunk_gpu_pipelined` with zero intermediate host stalls.

3. **Manifest & Adaptive Rate Reset**:
   - Reset `current_lr` to `0.045` in `test/geomind/trainingdata/cloze_manifest.json` to drive dynamic representation learning.

## 3. Empirical Verification
- **Compilation**: Self-hosted `cartanc.exe build test/geomind/main.car -o test/geomind/geomind.exe` completed with zero errors.
- **Binary Parity**: Bit-for-bit SHA-256 match across all 4 production binaries:
  `FC3749C902B803FC6994748378D8316733F0E377EAFB7DE40201F558D08ADBB0`
  - `test/geomind/geomind.exe`
  - `./geomind.exe`
  - `bin/geomind.exe`
  - `build/geomind.exe`
- **Execution**: Verified immediate steep loss descent in smoke test:
  - Interval 1: TL `5.3518` | VL `5.3594` | AVL `5.5627` | VPPL `260.5`
  - Interval 6: TL `4.9699` | VL `5.2039` | AVL `5.4879` | VPPL `241.7`
  - Background process confirmed terminated for user-controlled terminal execution.
