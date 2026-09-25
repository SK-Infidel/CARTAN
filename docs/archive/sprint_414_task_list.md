# Sprint 414 Task List: Dynamic Adaptive Domain Focus & Lag Catch-Up Scheduler

- [x] **Task 1: Architecture & Scheduler State Integration**
  - [x] Initialize focus state variables (`focus_d_idx`, `focus_streak`, `focus_rehearsal_active`) in `test/geomind/train.cl`.
  - [x] Implement mathematical lag detector computing $\Delta_d = VL_d - \overline{VL}_{\text{others}}$.
- [x] **Task 2: Dynamic Catch-Up Loop & Anti-Forgetting Rehearsal**
  - [x] Implement focused burst sequencing on lagging domain `d_idx`.
  - [x] Implement anti-forgetting fleet rehearsal cycle every 4 focused chunks.
  - [x] Implement parity check ($\Delta_d \le 0.35$) and clean disengagement back to standard round-robin.
- [x] **Task 3: Compilation & Empirical Verification**
  - [x] Compile `geomind.exe` with `cartanc.exe`.
  - [x] Verify zero compiler errors or ABI warnings.
  - [x] Test focus trigger and stream execution.
- [x] **Task 4: Retrospective & Documentation**
  - [x] Author `docs/archive/sprint_414_walkthrough.md`.
  - [x] Update `CHANGELOG.md` for version `[8.372.0]`.
