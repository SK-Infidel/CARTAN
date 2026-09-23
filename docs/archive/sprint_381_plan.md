# Sprint 381 Implementation Plan: Calibrate Continuous Temperature Controller & Harmonize Overfitting LR Braking

## 1. Context & Problem Statement
During Stage 2 Causal CE training, the model developed a steady generalization gap of $\Delta PPL \approx 22$ ($ATL \approx 4.378 \leftrightarrow AVL \approx 4.622$, $val\_gap \approx 0.244\text{ nats}$).
Despite this persistent gap:
1. `TEMP` remained frozen at the floor `1.0` because divergence detection was thresholded at $val\_gap > 0.45\text{ nats}$ ($\approx 45\text{ PPL}$).
2. Target-loss progress annealing continuously drove nominal LR to ceiling ($0.00235 \to 0.0024$) because gating was set at $(AVL - ATL) > 0.55\text{ nats}$.
3. Without temperature gradient softening ($\delta / T$) or LR dampening, the network continued over-fitting the training text.

## 2. Sprint Goal
Calibrate the closed-loop temperature controller activation threshold to $0.15\text{ nats}$ with proportional scaling ($target\_temp = 1.0 + excess\_scale \times 0.50$), gate LR progress annealing at $0.20\text{ nats}$, and add gentle closed-loop damping for sustained gaps $> 0.25\text{ nats}$.

## 3. Targeted Modifications
- **`test/geomind/train.cl`**:
  1. Line 1910: Lower annealing gate threshold from `> 0.55` to `> 0.20`.
  2. Line 1946: Add mild persistent overfitting damping: `else if (val_gap_brake > 0.25) { lr = lr * 0.999; }`.
  3. Line 1971: Lower divergence threshold from `val_gap > 0.45` to `val_gap > 0.15`.
  4. Line 1991: Lower excess scale threshold from `> 0.05` to `> 0.01`, multiplier to `0.50`, ceiling to `1.35`.

## 4. Verification Protocol
1. Compile using `cartanc.exe build test/geomind/main.car -o test/geomind/geomind.exe`.
2. Synchronize binary across `bin/geomind.exe` and `./geomind.exe`.
3. Run `--eval-analogy` to verify 4/4 semantic vector analogies pass at Rank 1.
4. Record artifacts and update `CHANGELOG.md` and `ISSUES.md`.
