# Sprint 494 Task List: Startup Biometric Authentication, Dynamic Guest Onboarding & Face Consent Protocol

- [x] **Task 1: Multi-User Registered Face Query (`src/std/sqlite_vec.cl`)**
  - [x] Implement `sqlite_vec_prepare_registered_face_users(db: ptr) -> ptr` in `src/std/sqlite_vec.cl`.
  - [x] Add backward-compatible `cartan_sqlite_prepare_registered_face_users` alias.

- [x] **Task 2: Automatic Startup Biometric Scan (`test/geomind/chat.cl`)**
  - [x] Add `g_pending_guest_face` global flag in `test/geomind/chat.cl`.
  - [x] Implement `geomind_chat_startup_biometric_scan(db: ptr) -> float` querying registered users in Domain 10 and executing 1:N cosine verification ($\tau = 0.85$).
  - [x] Set `g_active_user_id`, `g_active_user_verified`, and `g_pending_guest_face` according to match status.

- [x] **Task 3: Preamble Conditioning & Conversational Consent Protocol (`test/geomind/chat.cl`)**
  - [x] Update `geomind_chat_build_cognitive_preamble()` to condition guest introductions and consent solicitation when `g_pending_guest_face == 1.0`.
  - [x] Update `geomind_chat_learn_conversational_turn()` to detect name supply and consent/refusal.
  - [x] On consent: persist user profile in Domain 10, save 320-D eikonal embedding, clear pending flag, and elevate session.
  - [x] On refusal: respect privacy, discard pending embedding, clear pending flag.

- [x] **Task 4: REPL Boot Integration (`test/geomind/main.car`)**
  - [x] Trigger `geomind_chat_startup_biometric_scan(db)` at the entrance of `geomind_chat_interactive_loop`.
  - [x] Trigger `geomind_chat_startup_biometric_scan(db)` before single-turn `--chat` execution.
  - [x] Rebuild production `geomind.exe` and synchronize binaries.

- [x] **Task 5: Empirical Verification & Regression Testing**
  - [x] Author `test/geomind/test_startup_biometric_onboarding.car` verifying all 4 gates.
  - [x] Execute `tools/run_affected_tests.ps1 -All` verifying 88/88 targets.
  - [x] Update `ISSUES.md` (`[ISSUE-322]`, `[ISSUE-323]`, `[ISSUE-324]`).
  - [x] Update `CHANGELOG.md` (`[8.452.0]`) and `docs/ROADMAP.md`.
  - [x] Save walkthrough to `docs/archive/sprint_494_walkthrough.md`.

