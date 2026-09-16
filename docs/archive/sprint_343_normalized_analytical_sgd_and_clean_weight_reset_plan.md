# Sprint 343 Implementation Plan: Dimension-Normalized Analytical SGD, Clean Weights Checkpoint Initialization & Production Binary Parity

## 1. Context & Motivation
- **Problem**: In Sprint 342, after removing the cross-token momentum EMA buffer, raw un-normalized gradient updates $\Delta W = -\eta \cdot h_r \cdot \delta_c$ were applied. Because RMSNorm enforces $\sum h_r^2 = D = 2560$, the output logit shift per step was $\Delta z_c = -\eta \cdot \delta_c \cdot D = 2560 \cdot \eta \cdot (1 - p)$. With $\eta = 0.002$, this was 2.5× higher than the theoretical spectral radius divergence limit $\eta < 2 / \lambda_{\max} = 2 / 2560 = 0.00078125$.
- **Symptom**: Each token step swung logits by $\pm 5.12$, causing exponential logit blowup ($\pm 20$), probability collapse ($p \approx 10^{-9}$), training loss soaring to $19.35$, and validation perplexity exploding to $4.8 \times 10^6$. The contaminated weights were saved into `geomind_steady_state_weights.bin` and `.bin.bak`.
- **Secondary Defects Discovered**:
  1. Missing loop increment `i = i + 1.0;` at the bottom of the CLI argument dispatch loop in `main.car`, causing an infinite CPU spin-loop whenever leading options (like `-target`) were passed.
  2. Scope shadowing of outer `var i = 1.0;` by `var i = 0.0;` in `--train-distill`, breaking LLVM backend SSA dominance (`Instruction does not dominate all uses`).
  3. Calling `free(sample_text)` on static string constants `""` returned from empty/whitespace lines, triggering Win32 access violation heap crashes.

## 2. Proposed Changes
1. **Dimension Normalization**:
   - In `geomind_sgd_backward` OpenCL kernel and CPU SGD loop, normalize the gradient by hidden dimension $D$: $\text{grad} = (h_r \cdot \delta_c) / D$.
   - Binds logit delta directly to $\Delta z = -\eta \cdot \delta \le \eta$, guaranteeing unconditional mathematical stability for any learning rate $\eta < 2.0$.
   - Calibrate base learning rate to $0.05$.
2. **Quarantine Blown-Out Weights & Clean Initialization**:
   - Move corrupted checkpoints to `scratch/corrupted_checkpoints/`.
   - Re-initialize clean cortical weights ($\sim [-0.005, 0.005]$) starting at theoretical maximum entropy $\ln(2560) \approx 7.848$.
   - Reset `cloze_manifest.json` to dataset 0, offset 0.0, epoch 1.0.
3. **Fix CLI Dispatch Loop & Scope Shadowing**:
   - Add `i = i + 1.0;` to outer argument loop in `test/geomind/main.car`.
   - Rename inner loop variable in `--train-distill` from `i` to `k`.
4. **Memory Safety on Blank Lines & Div-by-Zero Guard**:
   - Wrap chunk training and `free(sample_text)` strictly within `if (sample_len > 0.0)` in `test/geomind/train.cl`.
   - Move `free(v_sample)` inside `if (v_s_len > 0.0)` in `geomind_compute_validation_loss`.
   - Guard `atl` and `cur_loss` against division by zero when `ep_step_count == 0.0`.
5. **Compilation & Binary Synchronization**:
   - Compile `bin/geomind.exe` using self-hosting `cartanc.exe`.
   - Synchronize across `bin/`, `./`, `build/`, and `test/geomind/` ensuring identical SHA-256 hashes.
6. **Empirical Verification**:
   - Run short test on sample corpus: verify clean descent from $7.94 \to 7.76$, $VL: 7.87 \to 7.82$, $VPPL: 2642 \to 2634$, clean exit code 0.

## 3. Definition of Done
- [x] Dimension-normalized SGD mathematically proven and implemented.
- [x] Blown-out checkpoint quarantined and clean weights baseline verified.
- [x] `cloze_manifest.json` reset to 0/0/1.0.
- [x] Infinite CLI loop and `free("")` access violation fixed.
- [x] All 4 binaries compiled with `cartanc.exe` and verified with matching SHA-256 hashes.
- [x] Empirical verification confirms smooth, monotonic descent with exit code 0.
- [x] `CHANGELOG.md` and `ISSUES.md` updated.
