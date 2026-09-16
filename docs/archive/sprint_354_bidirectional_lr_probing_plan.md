# Sprint 354 Implementation Plan: Bidirectional LR Probing on Floor Oscillation & Starvation

## Problem Statement
Perplexity can oscillate and spike when the learning rate is too low. At the floor (`0.001`), parameter updates are choked to $1.5 \times 10^{-6}$ per step. The network lacks the gradient capacity to absorb mini-batch variations across differing text segments. When harder tokens arrive, instantaneous loss and perplexity bounce, creating high-variance fluctuations that an overshooting-only controller misdiagnoses as overshooting. Trapped at the floor, the controller cannot decay further and never tests whether a higher LR restores stable descent.

## Proposed Architecture
1. **Interval Sign-Flip Oscillation Tracker**:
   - Compares current $\Delta\text{TPPL}$ with previous $\Delta\text{TPPL}$.
   - Detects when perplexity bounces between descent and ascent:
     `((delta_tppl > 0.20 && prev_delta_tppl < -0.20) || (delta_tppl < -0.20 && prev_delta_tppl > 0.20))`
2. **Symmetrical Oscillation Handling (`oscillation_count >= 3.0`)**:
   - If starved near floor (`lr <= 0.003`): Gently hike LR upward ($1.15\times$, capped at $0.008$) to probe for sufficient gradient step capacity.
   - If elevated (`lr > 0.003`): Decay LR downward ($0.95\times$) toward center.
3. **Starved Floor Rise Handling (`delta_tppl > 0.20` for 2 intervals)**:
   - If `lr <= 0.0025`: Hike LR upward ($1.15\times$, capped at $0.008$) instead of decaying.
   - Else (`lr > 0.0025`): Decay LR downward ($0.95\times$) toward center.
4. **Descent Reset**:
   - 3 consecutive stable descent intervals (`stable_descent_streak >= 3.0`) clears `oscillation_count`.

## Verification Criteria
1. Recompile cleanly with self-hosting `cartanc.exe`.
2. Synchronize 4 production binary locations (`test/geomind/geomind.exe`, `bin/geomind.exe`, `build/geomind.exe`, `./geomind.exe`).
3. Verify bit-for-bit SHA-256 hash match.
