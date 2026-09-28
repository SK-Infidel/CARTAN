# Sprint 430 Task List: Scale-Invariant Adaptive Domain Focus & Hard-Dataset Plateau Prevention

- [ ] **Phase 1: Architecture & Scheduler Implementation**
  - [ ] Declare focus configuration globals (`g_focus_ppl_delta`, `g_focus_ppl_ratio`, `g_focus_exit_delta`, `g_focus_exit_ratio`, `g_focus_max_session_chunks`) in [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl).
  - [ ] Add `focus_session_chunks` counter and session budget yield logic in `train.cl`.
  - [ ] Upgrade lag detection loop to check `(ppl_ratio > g_focus_ppl_ratio || ppl_delta > g_focus_ppl_delta)`.
  - [ ] Upgrade catch-up exit condition to `(cur_ppl_delta <= g_focus_exit_delta || cur_ppl_ratio <= g_focus_exit_ratio)`.
  - [ ] Wire CLI parameters in [`test/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car).

- [ ] **Phase 2: Empirical Regression Verification**
  - [ ] Authored test harness [`test/geomind/nses/test_sprint17_adaptive_focus.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/nses/test_sprint17_adaptive_focus.car).
  - [ ] Execute `test_sprint17_adaptive_focus.exe` and confirm 100% pass across Gates TS-17.1 to TS-17.4.
  - [ ] Execute existing test harnesses (`test_sprint16`, `test_sprint15`) to confirm zero regressions.

- [ ] **Phase 3: Production Build & Executable Synchronization**
  - [ ] Build `bin/geomind.exe` with Zig `-O3 LTO Vectorized Pass Pipeline`.
  - [ ] Run `bin/geomind.exe --verify`.
  - [ ] Synchronize `bin/geomind.exe` to `build/geomind.exe`, `geomind.exe`, and `test/geomind/geomind.exe`.

- [ ] **Phase 4: Documentation & Tracking**
  - [ ] Archive `sprint_430_plan.md`, `sprint_430_task_list.md`, and `sprint_430_walkthrough.md` to `docs/archive/`.
  - [ ] Update `ISSUES.md` with `[ISSUE-178] [FIXED]`.
  - [ ] Update `CHANGELOG.md` to `[8.388.0]`.
