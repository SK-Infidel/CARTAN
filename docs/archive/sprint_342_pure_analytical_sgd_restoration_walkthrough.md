# Sprint 342 Walkthrough: Pure Analytical SGD Restoration & Cross-Token Momentum Elimination

## 1. Problem & Discovery
- **Observation**: Loss was oscillating and hovering at $ATL \approx 7.71 - 7.72$, briefly dipping on repetitive lines and bouncing back up without progressing.
- **Root Cause**:
  - In Sprint 340, a persistent EMA momentum velocity buffer (`g_buf_cortical_velocity`, 26.2 MB) was added to `geomind_sgd_backward`.
  - In online autoregressive sequence training, target tokens vary at every token step. For a vocabulary of 2,560 tokens:
    - 1 target token receives a negative gradient ($\delta \approx -0.99$).
    - 2,559 non-target tokens receive positive gradients ($\delta \approx +0.0004$).
  - The cross-token EMA filter ($v = 0.90 v + 0.10 g$) attenuated the single target spike by 90% while continuously integrating positive background suppression across hundreds of non-target tokens.
  - This smeared gradients from unrelated words together across time, continuously eroding the weights toward zero.
  - Zero weights correspond to uniform random entropy over 2,560 tokens: $-\ln(1 / 2560) = \ln(2560) \approx 7.848$. The model was being driven directly toward maximum entropy.

## 2. Changes Implemented
1. **Removed Velocity Buffer & Restored Pure Analytical SGD**:
   - Eliminated `g_buf_cortical_velocity` and `geomind_zero_velocity` pipeline (reclaimed 26.2 MB VRAM).
   - Restored exact, unsmeared gradient update with per-token clipping:
     ```c
     __kernel void geomind_sgd_backward(__global const float* hidden, __global const float* delta, __global float* weights, int dim, int vocab, float lr, float decay) {
         int col = get_global_id(0);
         if (col < vocab) {
             float d = delta[col];
             for (int r = 0; r < dim; r++) {
                 int idx = r * vocab + col;
                 float grad = hidden[r] * d;
                 if (grad > 1.0f) grad = 1.0f;
                 else if (grad < -1.0f) grad = -1.0f;
                 weights[idx] = weights[idx] * decay - lr * grad;
             }
         }
     }
     ```
   - Target tokens now receive 100% of their learning gradient immediately on their respective step without attenuation or lag.
2. **Restored Intact Pre-Flattening Weights**:
   - Restored `geomind_steady_state_weights.bin` from `geomind_steady_state_weights.bin.bak`.
3. **Compiled with Self-Hosting Compiler**:
   - `.\cartanc.exe build test/geomind/main.car -o bin/geomind.exe`
4. **Empirical Verification**:
   - Tested 3-epoch sequence on test corpus:
     - Epoch 1 Mean Loss: 10.5182
     - Epoch 2 Mean Loss: 8.73416
     - Epoch 3 Mean Loss: 7.62818
   - Clean, monotonic, uninterrupted descent without bouncing back up.
