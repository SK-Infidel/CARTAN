# Sprint 343 Walkthrough: Dimension-Normalized Analytical SGD, Clean Weights Initialization & Production Binary Parity

## 1. Summary of Discoveries & Root Causes
- **Divergence Root Cause (`TL` exploded to 19.35)**:
  - In Sprint 342, the cross-token EMA buffer was removed, leaving raw un-normalized SGD updates: $\Delta W_{r, c} = -\eta \cdot h_r \cdot \delta_c$.
  - With RMSNorm, $\sum_{r=0}^{D-1} h_r^2 = D = 2560$.
  - The logit update after one token step was $\Delta z_c = \sum h_r \Delta W_{r, c} = -2560 \cdot \eta \cdot \delta_c$.
  - The maximum Hessian eigenvalue is $\lambda_{\max} \approx 2560$, giving a critical divergence ceiling $\eta < 2 / 2560 = 0.00078125$.
  - Running at $\eta = 0.002$ was 2.5× above the divergence threshold, shifting logits by $\pm 5.12$ per step and blowing them out to $\pm 20$.
  - This drove target token probabilities to $10^{-9}$ and loss to $-\ln(10^{-9}) \approx 19.35$, with validation perplexity exploding to $4.8 \times 10^6$.
  - Auto-saving contaminated `geomind_steady_state_weights.bin` and `.bin.bak`.
- **Secondary Defects Discovered & Resolved**:
  - `main.car` CLI loop had no `i = i + 1.0;` at the bottom, causing infinite spin-loops if non-mode flags appeared first.
  - Variable `i` shadowed in `--train-distill`, breaking LLVM SSA dominance.
  - Chunk stream called `free(sample_text)` on static string constants `""` produced on empty lines, causing Win32 access violation heap crashes.

## 2. Key Changes Implemented
1. **Dimension Normalization (`test/geomind/train.cl`)**:
   - Normalized SGD gradient by hidden dimension $D$:
     ```c
     float inv_dim = 1.0f / (float)dim;
     float grad = hidden[r] * d * inv_dim;
     if (grad > 1.0f) grad = 1.0f;
     else if (grad < -1.0f) grad = -1.0f;
     weights[idx] = weights[idx] * decay - lr * grad;
     ```
   - Logit shift is bounded directly to $\Delta z = -\eta \cdot \delta \le \eta$, completely immune to divergence for any $\eta < 2.0$.
   - Calibrated base learning rate to $0.05$.
2. **Clean Weights Baseline & Manifest Reset**:
   - Quarantined blown-out checkpoints to `scratch/corrupted_checkpoints/`.
   - Initialized fresh, small bounded weights ($\sim [-0.005, 0.005]$) starting at theoretical maximum entropy $\ln(2560) \approx 7.848$.
   - Reset `cloze_manifest.json` to dataset 0, offset 0.0, epoch 1.0.
3. **CLI Argument Dispatch & Memory Safety Fixes**:
   - Added `i = i + 1.0;` to outer argument loop in `test/geomind/main.car`.
   - Renamed shadowed loop variable in `--train-distill` from `i` to `k`.
   - Wrapped chunk training and `free(sample_text)` strictly within `if (sample_len > 0.0)`.
   - Fixed `geomind_compute_validation_loss` to only free `v_sample` when `v_s_len > 0.0`.
   - Guarded divisor operations in `cur_loss` and `atl` against zero step count.
4. **Binary Synchronization & Hashing**:
   - Compiled with self-hosting `cartanc.exe`.
   - Synchronized all 4 production binary locations with bit-for-bit identical SHA-256 hash:
     - Hash: `0D570FA76803E4C0BFA2B91CB70455353CA39654141992B58F09C51DFE5DDF98`
     - Binaries: `bin/geomind.exe`, `./geomind.exe`, `build/geomind.exe`, `test/geomind/geomind.exe`.

## 3. Empirical Verification Results
- Executed 1-epoch pass on test corpus:
  ```
  [Steady-State Stage: CLOZE] Ingesting Dataset [1.0 / 1.0]: test/geomind/trainingdata/physics_and_cartan_knowledge.txt (2.33008 KB)
  [GeoMind CLOZE Stream] Ep 1.0/1.0 | D[1.0/1.0] | 3.3948% (0.0791016 / 2.33008 KB) | TL: 0.0 | ATL: 0.0 | VL: 7.87937 | AVL: 7.87937 | VPPL: 2642.22 | LR: 0.05
  [GeoMind CLOZE Stream] Ep 1.0/1.0 | D[1.0/1.0] | 100.0% (2.33008 / 2.33008 KB) | TL: 7.76306 | ATL: 7.76306 | VL: 7.82139 | AVL: 7.87648 | VPPL: 2634.57 | LR: 0.05
  [Steady-State Stage: CLOZE] === Epoch 1.0 / 1.0 Complete === | Ingested: 1.0 datasets (22.0 chunks, 221.0 steps) | Mean Loss: 7.76306 (EMA: 2.67914) | LR: 0.05
  [Steady-State Stage: CLOZE] Training complete. Checkpoint saved: test/geomind/trainingdata/checkpoints/geomind_steady_state_weights.bin | Status: SUCCESS | Final Loss: 7.76306
  ```
- Validation loss descended monotonically ($7.879 \to 7.821$).
- Validation perplexity descended monotonically ($2642.22 \to 2634.57$).
- Exit code: 0, execution time: 1 second.
