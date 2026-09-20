# Sprint 372 Implementation Plan: Gradient Scale Calibration, Divergence Tripwire Relaxation & Loss Descent Recovery

## Problem Statement & Root Cause
In Stage 2 causal pretraining (`geomind --train-pre`), training loss has stalled at $TL \approx 4.27 - 4.30$ across 7 consecutive epochs (>30 hours of execution). The model reached the theoretical bigram/Markovian entropy floor of natural English but cannot push past it because:
1. **SGD Gradient Attenuation**: An unnecessary $1/\sqrt{\text{dim}} = 0.0197642$ factor in `geomind_sgd_backward` (`train.cl#L296`) and CPU fallback (`train.cl#L644`) attenuates outer-product gradients by $50.6\times$.
2. **Token Embedding Damping**: Token embedding update in `geomind_streams_backward` (`train.cl#L300`) is throttled by $0.025\times$.
3. **Adaptive LR Controller Tripwire**: The divergence check `ema_val_loss > atl * 1.08` misclassifies the standard generalization gap on unseen test holdouts as overfitting, permanently clamping `lr` to `lr_floor = 0.0015` and suppressing stall-recovery hikes.
4. **Combined Microscopic Step Size**: $\eta_{\text{eff}} \approx 2.96 \times 10^{-5}$ on target tokens and $10^{-8}$ on non-target tokens, yielding only 13.2% weight drift over 7 epochs.

## Proposed Changes
1. **Calibrate GPU & CPU SGD Gradient Scaling**:
   - `test/geomind/train.cl`: Remove `inv_sqrt_dim` from `geomind_sgd_backward` outer product update.
   - `test/geomind/train.cl`: Remove `0.0197642` from CPU SGD fallback loop.
2. **Calibrate Riemannian Embedding Step Multiplier**:
   - `test/geomind/train.cl`: Increase embedding update scale in `geomind_streams_backward` from `0.025f` to `0.25f`.
3. **Relax Generalization Gap Divergence Threshold**:
   - `test/geomind/train.cl`: Widen divergence threshold from `atl * 1.08` to `atl * 1.25`, allowing natural generalization gaps while preserving runaway divergence and rising-derivative ($d(\text{AVL})/dt > 0.015$) braking.
   - Enable adaptive controller to re-center learning rate upward when TPPL stalls at crawl.
4. **Compile & Empirical Verification**:
   - Recompile `geomind.exe` with self-hosting compiler `cartanc.exe`.
   - Synchronize binaries across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
   - Verify vector analogies pass at Rank 1.
   - Run short test execution and verify genuine gradient step size and loss descent.

## Verification Criteria
- [ ] `geomind.exe` builds cleanly with zero errors via `cartanc.exe`.
- [ ] SHA-256 binary hash synchronized across all 3 locations.
- [ ] 4/4 semantic vector analogies remain at Rank 1.
- [ ] Gradient step magnitude increases by $\approx 50\times$, breaking through the 4.27 plateau toward target loss.
