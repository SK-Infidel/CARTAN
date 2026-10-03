# Sprint 511 Implementation Plan: Real-Time Biometrics, Startup Face Recognition & Interactive User Profile Onboarding

## Sprint Goal
Enable seamless biometric interlocutor recognition and interactive user profile onboarding in GeoMind:
1. Detect unregistered or unverified interlocutors at startup via live hardware camera scan.
2. Interactively offer to register the user's face, preferred name, and relationship/role into Domain 10 (`USERS_AND_RELATIONSHIPS`) of `cognitive_memory.db`.
3. Provide instant authentication and personalized cognitive preamble conditioning when Rick is recognized at startup (cosine similarity $\ge 0.85$).
4. Fix conversational face enrollment bugs and add `/help` guidance to the REPL.

## User Stories
1. **As Rick (Creator & Architect)**, when I start `bin/geomind.exe` for the first time or with an unmapped face, GeoMind actively detects my presence via the camera and asks if I would like to create a profile and register my biometric face map.
2. **As Rick**, after registering my face, subsequent launches of `bin/geomind.exe` automatically identify me via camera scan, print an authenticated recognition banner, and ground the dialogue session with `User:Rick (Creator & Architect)`.
3. **As an interlocutor**, if I tell GeoMind *"My name is Rick"* or *"Register my face as Rick"*, my active or pending camera frame is immediately enrolled in Domain 10 without getting dropped.

## Architecture & Implementation Gates
- **Gate 1: Interactive Startup Onboarding Dialogue (`test/geomind/chat.cl`, `test/geomind/main.car`)**:
  - In `geomind_chat_startup_biometric_scan`, when camera captures a face but `best_sim < 0.85` or no face maps exist:
    - In interactive mode, prompt:
      `[GeoMind Biometrics] Unregistered interlocutor detected.`
      `Would you like to register your biometric face map and create/update your profile? (y/n): `
    - If `y`: prompt for Name (`[default: Rick]`) and Role/Relationship (`[default: Creator & Architect]`).
    - Serialize 320-D eikonal embedding to CSV and persist via `sqlite_vec_save_user_face_embedding`.
    - Persist `preferred_name`, `role`, `relationship`, `permission_tier = "root"` (for Rick) or `"user"`, and `face_registered = "1"`.
    - Set active session to verified user.
- **Gate 2: Conversational Enrollment Bug Fix (`test/geomind/chat.cl`)**:
  - Refactor `geomind_chat_learn_conversational_turn` so that `g_pending_guest_face == 1.0 && g_active_face_embedding != 0.0` enrolls for `User:Rick` when `cand_user` contains "rick", instead of only enrolling in the `else` branch.
  - Ensure conversational triggers (*"register my face"*, *"associate my face with me"*) save to the active user profile in Domain 10.
- **Gate 3: REPL Command Polish & /help Integration (`test/geomind/main.car`)**:
  - Add `/help` in `geomind_chat_interactive_loop` documenting `/whoami`, `/register-face`, `/verify-face`, `/switch-user`, `/clear`, `/reset`, `/remember`, `/state`, `/sleep`, `/debug`, `/exit`.
  - Update `/register-face` to prompt for camera capture if no active embedding is loaded.
- **Gate 4: Empirical Verification & Regression Testing**:
  - Verify live camera capture, enrollment, authentication, and cognitive preamble conditioning.
  - Run full compiler regression test suite (`tools/run_affected_tests.ps1 -All`) ensuring 88/88 test targets pass.
