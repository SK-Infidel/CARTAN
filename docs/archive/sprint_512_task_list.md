# Sprint 512 Task List: Thread Pool Idle Standby & Silent REPL Operation

- [x] **Task 1: Runtime Thread Pool Standby Implementation**
  - [x] Declare `extern fn Sleep(dwMilliseconds: float) -> void;` in `src/std/transformer.cl`.
  - [x] Implement `g_trans_pool_standby: float = 0.0`.
  - [x] Implement `cartan_trans_pool_enter_standby() -> float`.
  - [x] Implement `cartan_trans_pool_resume_active() -> float`.
  - [x] Implement `cartan_trans_pool_is_standby() -> float`.
  - [x] Implement `cartan_trans_pool_shutdown() -> float`.
  - [x] Update `cartan_trans_pool_worker_main` with dual-mode standby (`Sleep(10.0)` during standby, adaptive `Sleep(2.0)` on spin > 500,000, fast spin during active dispatch).
  - [x] Add auto-resume checks in `cartan_trans_pool_dispatch*`.

- [x] **Task 2: Interactive REPL Integration**
  - [x] Hook `cartan_trans_pool_enter_standby()` and `cartan_trans_pool_resume_active()` around `cartan_read_line()` in `test/geomind/main.car`.
  - [x] Hook `cartan_trans_pool_enter_standby()` and `cartan_trans_pool_resume_active()` around `cartan_read_line()` in `test/geomind/chat.cl` (biometric registration).
  - [x] Add `cartan_trans_pool_shutdown()` upon interactive REPL session exit in `test/geomind/main.car`.

- [x] **Task 3: Compilation & Empirical Profiling**
  - [x] Compile `bin/geomind.exe` with `cartanc.exe`.
  - [x] Verify CPU load drops from ~40% to ~0.0% at `User> ` prompt (empirically measured 0.00% across 32 cores).
  - [x] Verify token generation speed (tok/s) has zero degradation during active inference.
  - [x] Execute targeted affected tests (`tools/run_affected_tests.ps1 -Sprint 512`: 5/5 passed).

- [x] **Task 4: Sprint Review & Retrospective**
  - [x] Update `ISSUES.md`: mark `[ISSUE-366]` as `[FIXED]`.
  - [x] Update `CHANGELOG.md` with version entry `[8.468.0]`.
  - [x] Document walkthrough in `docs/archive/sprint_512_walkthrough.md`.
