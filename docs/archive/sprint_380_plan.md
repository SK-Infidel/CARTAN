# Sprint 380 Plan: Symmetrized Perplexity Metrics & Holistic Evaluation Ruler

## Objective
Harmonize `TPPL` and `VPPL` calculation so they operate on identical smoothed mathematical rulers, eliminating artificial 30+ point swings caused by evaluating raw instantaneous single-chunk training loss against 95% smoothed validation holdouts.

## Root Cause
- `TPPL` was evaluated as $\exp(TL)$ where $TL$ is raw, unsmoothed single-chunk loss. Minor fluctuations in passage difficulty ($0.40\text{ nats}$) caused exponential swings from $69 \to 104$.
- `VPPL` was evaluated as $\exp(AVL)$ from $ema\_val\_loss$ (95% smoothed over 100 holdout chunks).
- Asymmetry caused the appearance of massive swings in training perplexity while validation perplexity was rock steady.
- LR and Temp appeared frozen because the generalization gap ($AVL - ATL \approx 0.16\text{ nats}$) is well below the divergence threshold ($0.45\text{ nats}$), correctly keeping Temp at 1.0 and LR at full cruising speed.

## Solution
1. Update `cur_tppl` to $\exp(ATL)$ in `test/geomind/train.cl`, matching `vppl = exp(AVL)`.
2. Compile and verify binary parity and analogy benchmarks.
