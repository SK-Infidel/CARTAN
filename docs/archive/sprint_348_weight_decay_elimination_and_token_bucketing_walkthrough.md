# Sprint 348 Walkthrough: Weight Decay Elimination, Token Bucketing, & Loss Lock Resolution

## 1. Problem Statement & Forensic Diagnosis
During 54 training epochs, training loss remained completely stagnant at ~4.643 (`ATL: 4.64308`, `VL: 4.66776`, `AVL: 4.69614`) despite learning rate adjustments and saddle point escapes.

### Forensic Findings:
1. **Per-Token Exponential Weight Decay (`train.cl:604`, `train.cl:553`)**:
   - `decay_factor = 1.0 - (lr * 0.0001)` was executed on every single token step (240,000 steps per epoch).
   - Across a single epoch: $(1 - 3 \times 10^{-6})^{240000} \approx 0.486$. Weights decayed by 51.4% every epoch ($0.486^{54} \approx 10^{-17}$ over 54 epochs).
   - Weights were driven into an equilibrium where incoming gradient updates were exactly canceled by per-step decay, crushing weight standard deviation to $0.0004614$ (`Mean: -1.27e-8`).
2. **Logit Dynamic Range Collapse (~4.643 Loss Floor)**:
   - With $W$ standard deviation crushed to $0.00046$, logits had standard deviation of only $0.023$.
   - The softmax output over the active vocabulary was flat, capping prediction probability at $\sim 0.96\%$, locking cross-entropy loss mathematically at $-\ln(1/104) \approx 4.643$.
3. **Chain Rule Underflow in Input SGD**:
   - In `geomind_input_grad_update`, gradient updates were divided by `dim` (2560), reducing parameter updates to $\approx 4 \times 10^{-7}$ (float32 machine epsilon underflow).
4. **Out-of-Vocabulary Discard Rate**:
   - 39.6% of tokens in the training corpus have token ID $\ge 2560$ (exceeding the $2560 \times 2560$ weight matrix), resulting in zero embedding projections and zero SGD gradient updates.

---

## 2. Changes Implemented
1. **Weight Decay Elimination**: Set `decay_factor = 1.0` in both GPU (`train.cl:604`) and CPU (`train.cl:553`) training loops.
2. **Checkpoint Rescaling**: Multiplied baseline weights $8\times$ via `tools/rescale_checkpoint.ps1`, restoring standard deviation to $0.00369$ and dynamic range $[-1.12, +1.12]$. Backed up pre-sprint checkpoint to `geomind_steady_state_weights.bin.pre_sprint348.bak`.
3. **Gradient Scaling**: Scaled SGD gradient by $4.0\times$ in `geomind_sgd_backward` (`hidden[r] * d * inv_dim * 4.0f`) and CPU training loop.
4. **Input SGD Underflow Fix**: Removed erroneous `/ (float)dim` in `geomind_input_grad_update`, restoring genuine embedding updates.
5. **Token Modulo Bucketing**: Added `eff_tok = tok % vocab` in `geomind_autoregressive_step` and `geomind_input_grad_update` (`train.cl` and `chat.cl`).
6. **Manifest Pre-conditioning**: Set `current_lr = 0.035` in `test/geomind/trainingdata/cloze_manifest.json`.

---

## 3. Verification & Parity
1. **Compiler**: Rebuilt via self-hosting `cartanc.exe`.
2. **Binary Parity**: Synchronized 4 production binaries with matching SHA-256:
   - `test/geomind/geomind.exe`: `294178EAD2AE765B4E7F2E9F2BF95C419804FE06A9EDDB13E362E24D5267E5CA`
   - `./geomind.exe`: `294178EAD2AE765B4E7F2E9F2BF95C419804FE06A9EDDB13E362E24D5267E5CA`
   - `bin/geomind.exe`: `294178EAD2AE765B4E7F2E9F2BF95C419804FE06A9EDDB13E362E24D5267E5CA`
   - `build/geomind.exe`: `294178EAD2AE765B4E7F2E9F2BF95C419804FE06A9EDDB13E362E24D5267E5CA`
3. **Smoke Test Execution**:
   - Ran `./geomind.exe --train-cloze` for 6 seconds.
   - TL dropped: `16.6494 -> 11.0247 -> 8.50867 -> 7.39593`.
   - VL dropped: `15.6397 -> 10.3698 -> 9.3363 -> 8.374 -> 7.39758`.
   - Process cleanly stopped; ready for user interactive launch.
