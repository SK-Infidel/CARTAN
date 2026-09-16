# Sprint 353 Implementation Plan: Closed-Loop Training Perplexity Centering Controller

## Problem Statement
The legacy plateau-based learning rate decay mechanism periodically ratcheted `lr` downward whenever holdout loss did not drop by >= 0.005 within 8 intervals. In fine convergence, validation loss moves in smaller increments (~0.0004), causing `lr` to continuously decay to the floor (`0.001`). At `0.001`, parameter updates are choked to 1.5e-6 per step, causing learning to freeze.

## Proposed Architecture
Tie learning rate dynamics directly to **Training Perplexity** (`TPPL = exp(tl)`) with exponential moving average smoothing (alpha = 0.25):
- `ema_tppl = 0.75 * ema_tppl + 0.25 * cur_tppl`
- `delta_tppl = ema_tppl - prev_ema_tppl`

### Closed-Loop Control States
1. **Active Stable Descent (`delta_tppl < -0.20`)**:
   - Training perplexity is actively decreasing.
   - Zero decay applied; hold the sweet-spot LR steady to ride the downward gradient slope uninterrupted.
2. **Rising / Oscillating (`delta_tppl > +0.20`)**:
   - Perplexity is increasing across consecutive intervals, signaling parameter overshooting.
   - Decay LR gently (`lr = lr * 0.95`) toward the descent center until stable descent resumes.
3. **Flat / Stagnant (`|delta_tppl| <= 0.20`)**:
   - If progress stalls for 6 intervals (600 lines):
     - If starved near floor (`lr < 0.003`): Nudge LR upward (1.15x, capped at 0.010) to restore momentum.
     - If elevated (`lr > 0.008`): Trim LR downward (0.95x) toward descent slope.

## Verification Criteria
1. Clean compilation with self-hosting `cartanc.exe`.
2. Binary hash synchronization across release targets.
3. Zero disruption to holdout validation metrics or checkpoint persistence.
