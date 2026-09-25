# Sprint 415 Task List: Top-3 Anchor Perplexity (IVPPL) Dynamic Focus Scheduler

- [x] **Task 1: Top-3 Anchor PPL Calculation**
  - [x] Implement Top-3 minimum validation loss search ($VL_{\min 1}, VL_{\min 2}, VL_{\min 3}$).
  - [x] Compute baseline anchor perplexity $P_{\text{anchor}} = \frac{1}{K}\sum \exp(VL_{\min k})$.
- [x] **Task 2: PPL Delta Evaluation & Threshold Refinement**
  - [x] Implement $\Delta \text{IVPPL} = \text{PPL}_d - P_{\text{anchor}}$.
  - [x] Set engagement trigger to $\Delta \text{IVPPL} > 150.0$.
  - [x] Set disengagement parity threshold to $\Delta \text{IVPPL} \le 50.0$.
- [x] **Task 3: Compilation & Empirical Verification**
  - [x] Backup `test/geomind/train.cl` before edits.
  - [x] Edit `test/geomind/train.cl` with new PPL anchor logic.
  - [x] Rebuild `geomind.exe` with `cartanc.exe`.
  - [x] Verify zero regressions across all 7 NSES test suites and `geomind.exe --verify`.
  - [x] Remove backup on clean verification.
- [x] **Task 4: Retrospective & Documentation**
  - [x] Author `docs/archive/sprint_415_walkthrough.md`.
  - [x] Update `CHANGELOG.md` for `[8.373.0]`.
