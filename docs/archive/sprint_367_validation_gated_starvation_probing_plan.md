# Sprint 367 Plan: Validation-Gated Starvation Probing & Ping-Pong Loop Elimination

## 1. Context & Problem Statement
During Stage 2 pre-training across local split corpora (`mined_expanded_corpus_cloze_part03.txt`), a tug-of-war loop was observed in the adaptive learning rate controller:
1. Training loss (`ATL: 3.55`) diverged from holdout validation loss (`AVL: 4.27`), widening the generalization gap to ~20% ($AVL > ATL \times 1.08$) and raising validation perplexity (`VPPL` ~71–72).
2. The TPPL controller evaluated starvation at floor (`lr <= lr_floor * 1.05`) independently of validation status, repeatedly hiking LR upward ($1.15\times \to 0.001725$).
3. Divergence braking detected $AVL > ATL \times 1.08$ on subsequent steps, braking LR back down to `0.0015` ($0.92\times$).
4. This oscillation pumped LR into the overfitting regime every few steps, preventing the generalization gap from contracting.

## 2. Technical Solution
1. Introduce an explicit validation divergence flag `val_divergent = (ema_val_loss > atl * 1.08)` before TPPL evaluation.
2. Guard all upward starvation probing branches (oscillating, rising, stalled) with `val_divergent == 0.0`.
3. Suppress LR hikes when validation divergence is active, locking LR at `lr_floor = 0.0015`.
4. Recompile with `cartanc.exe`, synchronize binaries, and verify live stability.
