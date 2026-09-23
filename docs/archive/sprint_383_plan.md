# Sprint 383 Implementation Plan: Closed-Loop Chunk Convergence Gate & In-Place Overfitting Remediation

## 1. Context & User Directive
The user directed:
- **No baseline restoration**: Maintain the current overfit checkpoint weights ([`geomind_steady_state_weights.bin`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/checkpoints/geomind_steady_state_weights.bin)) and manifest position (Dataset 0, 16.4%, $ATL \approx 4.414 \leftrightarrow AVL \approx 4.685$, $\Delta PPL \approx 25.8$).
- **Test In-Place Overfitting Remediation**: Implement the Closed-Loop Chunk Convergence Gate directly on this state to empirically determine if stream suspension and chunk retraining under temperature softening can close the generalization gap.

## 2. Sprint Goal
Implement the Closed-Loop Chunk Convergence Mode in `test/geomind/train.cl`:
1. Hoist `vppl`, `cur_tppl`, and `holdout_path` to epoch scope for continuous chunk-level availability.
2. If $\Delta PPL = (VPPL - TPPL) > 18.0$ (or $val\_gap > 0.18\text{ nats}$):
   - Suspend stream advancement (hold current chunk).
   - Retrain chunk under high-gain temperature softening ($T = 1.25$) and dampened LR ($\eta_{\text{conv}} = 0.75 \times \eta$).
   - Re-evaluate holdout validation after each pass (up to 5 passes).
   - Once $\Delta PPL \le 18.0$, log convergence and resume normal stream advancement.
3. If $\Delta PPL \le 18.0$: train normally (single pass, advance to next chunk).

## 3. Verification Protocol
1. Compile via `cartanc.exe build test/geomind/main.car -o test/geomind/geomind.exe`.
2. Synchronize binary across `bin/geomind.exe` and `./geomind.exe`.
3. Verify 4/4 semantic vector analogies at Rank 1.
4. Update `CHANGELOG.md` (`[8.340.0]`) and `ISSUES.md` (`[ISSUE-132]`).
