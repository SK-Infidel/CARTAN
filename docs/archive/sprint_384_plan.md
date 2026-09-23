# Sprint 384 Implementation Plan: Prevent Premature De-throttling & Enforce Exact Match Convergence Gate

## 1. Context & Diagnosis
In the live test, the generalization gap successfully dropped from $25.8 \to 19.59\text{ PPL}$ ($val\_gap \to 0.206\text{ nats}$). However, it plateaued around 18 and bounced back open.
Root cause analysis revealed **premature de-throttling**:
1. When $val\_gap$ approached $0.20$, `val_divergent` flipped to `0.0`.
2. Target-loss progress annealing immediately blended $10\%$ of ceiling LR ($0.0024$) per interval, surging nominal LR from $0.00127 \to 0.00180$.
3. Concurrently, the temperature controller cooled $T$ from $1.15 \to 1.01$.
4. With cold temperature and high LR, the network immediately resumed memorizing training chunks ($TL \to 4.07$), re-opening the validation divergence gap.

## 2. Sprint Goal
Enforce exact-match convergence ($\Delta PPL \le 2.5\text{ PPL}$ / $val\_gap \le 0.03\text{ nats}$) by eliminating premature de-throttling:
1. Gate upward LR progress annealing until $val\_gap \le 0.05\text{ nats}$ ($\Delta PPL \le 3.0$).
2. Prevent temperature cooling until the gap genuinely approaches match parity ($val\_gap \le 0.03$).
3. Configure Chunk Convergence Gate to drive toward match tolerance ($2.5\text{ PPL}$) with up to 8 passes and plateau detection.
4. Maintain disciplined conservative LR ($\le 0.0010$) across chunk advancements.

## 3. Targeted Modifications
- **`test/geomind/train.cl`**:
  - Lines 1806-1845: Update convergence threshold from $18.0 \to 2.5\text{ PPL}$, max passes to 8, and add plateau detection.
  - Lines 1955-1962: Lower annealing gating threshold from $val\_gap > 0.20$ to $val\_gap > 0.05$.
  - Lines 2040-2050: Scale temperature directly from $val\_gap > 0.03$ with gain $1.50\times$, preventing premature cooling at gap 18.

## 4. Verification Protocol
1. Compile via `cartanc.exe build test/geomind/main.car -o test/geomind/geomind.exe`.
2. Synchronize binary across `bin/geomind.exe` and `./geomind.exe`.
3. Verify 4/4 semantic vector analogies at Rank 1.
4. Update `CHANGELOG.md` (`[8.341.0]`) and `ISSUES.md` (`[ISSUE-133]`).
