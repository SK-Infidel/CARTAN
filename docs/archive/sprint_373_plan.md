# Sprint 373 Implementation Plan: Gradient Stability Restoration, Checkpoint Recovery & Generalization Threshold Calibration

## Problem Statement & Root Cause
In Sprint 372, removing the $1/\sqrt{\text{dim}} = 0.0197642$ scaling factor from outer-product SGD updates violated the Lipschitz stability bound for the 2560-wide linear projection layer:
1. **Forward Dot-Product Scaling**: Each logit is the sum across 2560 dimensions: $\text{logit}_c = \sum_{r=0}^{2559} h_r W_{r,c}$.
2. **Step Shift per Token**: Updating all 2560 weights by $-\eta \cdot h_r \cdot \delta_c$ shifts the logit by $\Delta \text{logit} = \eta \cdot \|h\|_2^2 \cdot \delta_c \approx 2560 \cdot \eta \cdot \delta_c$.
3. **Explosion**: At $\eta = 0.002$, a single token shifted logits by $\approx 5.12$, causing weights to explode to $-136.54$ and loss to hit the numerical clamp ceiling ($TL \approx 20.0$).
4. **Adaptive Tripwire Sensitivity**: Multiplicative ratio `1.25` falsely braked learning rate when training loss descended toward 3.50 because the holdout generalization gap is $\approx 1.0$ nat.

## Proposed Changes
1. **Restore Pristine Weights & Curriculum**:
   - Restore `geomind_steady_state_weights.bin` from `geomind_steady_state_weights.bin.bak`.
   - Reset `corpus.json` to pre-divergence position (Epoch 8.0, Dataset 5.0, offset 3696882.0).
   - Truncate diverged log entries in `logs/stage2_ce_training.log`.
2. **Restore Mathematically Indispensable Gradient Scaling**:
   - `test/geomind/train.cl`: Restore `0.0197642f` to `geomind_sgd_backward` outer-product step.
   - `test/geomind/train.cl`: Restore `0.0197642` to CPU fallback loop (`cartan_tensor_train_step`).
   - `test/geomind/train.cl`: Restore `0.025f` to `geomind_streams_backward` and `geomind_input_grad_update`.
3. **Calibrate Adaptive Generalization Gap Threshold**:
   - Widen divergence check to `ema_val_loss > (atl * 1.35) && (ema_val_loss - atl) > 1.20`, accounting for natural multi-register holdout gap.
   - Set Stage 2 `lr_floor = 0.001`, `stage_ceiling_lr = 0.006`.
4. **Compile & Empirical Verification**:
   - Recompile `geomind.exe` with `cartanc.exe`.
   - Synchronize across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
   - Verify all 4 semantic vector analogies evaluate to Rank 1.
   - Run live training verification pass and inspect loss descent and learning rate stability.

## Verification Criteria
- [x] Uncorrupted backup weights restored; min/max bounded $[-0.46, +0.55]$.
- [x] 4/4 vector analogies confirmed Rank 1 (`geomind --eval-analogy`).
- [x] Recompiled cleanly via `cartanc.exe`; SHA-256 synchronized across all 3 binaries.
- [x] Live empirical training confirms steady loss descent ($TL \approx 2.97 - 4.10$, $ATL \to 3.87$) without divergence or false-alarm braking.
