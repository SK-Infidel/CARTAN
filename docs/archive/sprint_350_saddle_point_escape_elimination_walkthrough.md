# Sprint 350 Walkthrough: Elimination of Disruptive Mid-Stream Saddle Point Escape Boosts

## 1. Problem Statement
During active, productive training where loss was dropping from $4.64$ to $4.48$ (with validation loss dropping to $4.55$ and perplexity down to $94$), the optimizer suddenly triggered:
`[Adaptive LR] Saddle point escape triggered after 15.0 stagnant intervals. Boosted LR: 0.0162152 -> 0.035`
This $+115\%$ jump in learning rate shocked the parameter manifold, undoing steady convergence and confusing the model.

## 2. Root Cause Analysis
In `train.cl`, the saddle point escape check:
```cl
if (lr <= (lr_floor * 1.15)) {
    floor_stagnation_count = floor_stagnation_count + 1.0;
    if (floor_stagnation_count >= 15.0) { ... }
}
```
evaluated whether `lr <= 0.01725`. It did NOT check whether loss was actively dropping or whether the model was improving. Therefore, whenever the model naturally annealed down to its productive sweet spot ($0.016$), it inevitably accumulated 15 intervals (only 1,500 lines) and triggered an explosive boost to $0.035$.

## 3. Technical Changes
- Completely removed the 15-interval saddle point escape block from `test/geomind/train.cl`.
- Removed `floor_stagnation_count` tracking and resets.
- Learning rate now settles smoothly into its convergence range ($0.015 - 0.020$) and trains steadily at `lr_floor` (`0.015`) when reached without artificial shocks.
- Preserved general sustained perplexity surge detection to guard against true representational divergence.

## 4. Verification & Parity
- **Compiler**: Rebuilt cleanly via self-hosting `cartanc.exe`.
- **Binaries Updated**: `test/geomind/geomind.exe`, `bin/geomind.exe`, `build/geomind.exe` with SHA-256 `39DA2B14A7951CDE05D619BE0F4A5133A19991CBC8E9C33A20CBF9FE881261BA`.
- `./geomind.exe` is currently locked by the user's active terminal process; it can be synced immediately upon stopping.
