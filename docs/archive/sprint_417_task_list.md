# Sprint 417 Task List: Rapid-Cadence Metacognitive Sleep & Reactive Loss-Spike Quenching

- [x] **Task 1: Pre-Sprint Review & State Tracking**
  - [x] Review `test/geomind/train.cl` sleep trigger condition and variables.
  - [x] Add `val_climb_streak` and reactive trigger state variables.
- [x] **Task 2: Implement Rapid Cadence & Reactive Interrupt**
  - [x] Change sleep cadence to every `num_datasets * 2.0` chunks (every other cycle = 20 chunks).
  - [x] Implement reactive sleep trigger when `val_climb_streak >= 2.0` or instantaneous `vl - ema_val_loss > 0.35`.
  - [x] Format consolidation report and append to `log_file`.
- [x] **Task 3: Compilation & Empirical Verification**
  - [x] Compile `geomind.exe` with `cartanc.exe`.
  - [x] Verify clean execution with `geomind.exe --verify`.
  - [x] Run all 7 NSES test suites.
  - [x] Clean up `.bak_sprint417`.
- [x] **Task 4: Retrospective & Documentation**
  - [x] Author `docs/archive/sprint_417_walkthrough.md`.
  - [x] Update `CHANGELOG.md` for `[8.375.0]`.
