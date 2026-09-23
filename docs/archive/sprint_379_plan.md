# Sprint 379 Plan: Eliminate Weight Decay Erosion & Calibrate Adaptive LR Braking

## Objective
Resolve `[ISSUE-129]`: Stop runaway validation loss ($VPPL \to 693.881$, $VL \to 6.70$) and learning rate collapse ($LR \to 0.00075$) caused by unscaled per-token weight decay multiplying 6.5M weights by $0.99995$ on every token step.

## Root Cause
1. **Unscaled Weight Decay Erosion**: `decay_factor = 0.99995` applied 256 times per chunk eroded 99% of all weights within 100,000 steps, flattening logits into uniform noise ($VENT = 11.3219\text{b} = \log_2(2560)$) and destroying analogies.
2. **Cascading LR Collapse**: Artificial validation gap ($AVL - ATL = 1.18$) triggered continuous $0.95\times$ interval braking, driving LR to the floor ($0.00075$) and persisting it into `corpus.json`.

## Steps
1. Restore `decay_factor = 1.0` in both OpenCL and CPU SGD loops (`test/geomind/train.cl`).
2. Restore clean baseline weights from `geomind_steady_state_weights.bin.bak` over `geomind_steady_state_weights.bin`.
3. Reset `test/geomind/trainingdata/corpus.json` to dataset 0, offset 0.0, epoch 1.0, and LR 0.0022.
4. Calibrate proportionate adaptive LR braking in `test/geomind/train.cl` ($0.98\times$ at $> 1.30$, $0.99\times$ at $> 1.00$, $0.995\times$ at $> 0.70$).
5. Rebuild with `cartanc.exe`, verify SHA-256 binary parity, and verify 4/4 analogies pass at Rank 1.
