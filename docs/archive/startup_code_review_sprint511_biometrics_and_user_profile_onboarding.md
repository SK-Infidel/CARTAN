# Startup Code Review: Sprint 511 - Biometrics, Interlocutor Recognition & User Profile Onboarding

## Executive Summary
This startup code review inspects the biometric face capture, eikonal unit-hypersphere embedding ($S^{319}$), Domain 10 (`USERS_AND_RELATIONSHIPS`) database storage, and interactive onboarding dialogue flow within `test/geomind/chat.cl`, `test/geomind/main.car`, `src/std/vision.cl`, and `src/std/sqlite_vec.cl`.

## Root Cause Analysis: Why Startup Biometrics & Profile Creation Failed
1. **Passive Onboarding Deadlock (`test/geomind/chat.cl:1553-1563`)**:
   - In `geomind_chat_startup_biometric_scan(db)`, when `tools/capture_camera.exe` successfully captures a live webcam frame and extracts a 320-D eikonal embedding, it iterates over all registered users in Domain 10 where `face_registered = '1'`.
   - Because Domain 10 initially seeds `User:Rick` and `User:Guest` with `face_registered = '0'`, zero registered face records exist.
   - The scan function evaluated `best_sim = -1.0`, printed `[GeoMind Biometrics] No enrolled face maps in Domain 10. Initiating Guest onboarding session.`, assigned `g_active_user_id = "User:Guest"`, and immediately returned `0.0`.
   - It **never prompted the interlocutor** to register their face, specify their identity, or link their profile.

2. **REPL Session Ignoring Unregistered Interlocutor (`test/geomind/main.car:556-566`)**:
   - In `geomind_chat_interactive_loop`, following `geomind_chat_startup_biometric_scan(db)`, the loop printed `[GeoMind Chat] Interactive REPL Session Ready` and `User> `, entering normal chat without offering registration.
   - The only manual enrollment path was the undocumented `/register-face` slash command.

3. **Conversational Face Enrollment Exclusion Bug (`test/geomind/chat.cl:1071-1100`)**:
   - In `geomind_chat_learn_conversational_turn`, when an interlocutor stated *"My name is Rick"*, the system matched `cartan_string_contains(lower_u, "rick") == 1.0` and set `g_active_user_id = "User:Rick"`.
   - However, the pending face enrollment block (`if (g_pending_guest_face == 1.0 && g_active_face_embedding != 0.0)`) was nested inside the `else` branch (only for non-Rick names).
   - As a result, Rick's pending face was never associated with `User:Rick`, and `face_registered` remained `'0'`.

4. **Live Hardware Verification**:
   - Running `tools/capture_camera.exe scratch/camera_frame.bmp 640 480` on the host DirectShow webcam succeeded with exit code 0.
   - In empirical testing (`bin/test_biometric_live.exe`), consecutive frame captures yielded **0.997862** cosine similarity and 1.000000 CSV serialization parity, confirming hardware and math stack integrity.

## Logical Dependency Tree
```
[DirectShow Hardware Webcam]
      │ (Captures 640x480 BMP)
      ▼
tools/capture_camera.exe
      │
      ▼
src/std/vision.cl
      ├── vision_load_bmp (Parses 24/32 bpp BMP)
      ├── vision_extract_face_embedding (Extracts 16x16 central patch, projects to 320-D eikonal, L2 normalizes to S^319)
      ├── vision_cosine_similarity (Computes dot product of unit vectors)
      └── vision_serialize_vector_csv / vision_deserialize_vector_csv (Lossless string encoding)
            │
            ▼
src/std/sqlite_vec.cl
      ├── sqlite_vec_init_domain10 (Seeds Domain 10: USERS_AND_RELATIONSHIPS)
      ├── sqlite_vec_save_user_face_embedding (Persists CSV string, sets face_registered='1')
      ├── sqlite_vec_get_user_face_embedding (Retrieves CSV string)
      ├── sqlite_vec_prepare_registered_face_users (Enumerate users with face_registered='1')
      └── sqlite_vec_get_user_attr / sqlite_vec_set_user_attr (Profile attributes: name, role, relationship, tier)
            │
            ▼
test/geomind/chat.cl
      ├── geomind_chat_startup_biometric_scan (Live scan, matching, and interactive onboarding flow)
      ├── geomind_chat_register_face (Manual/automated enrollment)
      ├── geomind_chat_verify_face (Runtime re-verification)
      ├── geomind_chat_learn_conversational_turn (Bug-free Hebbian name + face association for all users)
      └── geomind_chat_build_cognitive_preamble (Dynamic conditioning: User:Rick vs Verified User vs Guest)
            │
            ▼
test/geomind/main.car
      └── geomind_chat_interactive_loop (Prompts onboarding if unregistered; handles /register-face, /verify-face, /whoami, /help)
```

## Discovered Issues & Technical Debt
- **[ISSUE-364] Missing Startup Biometric Onboarding Prompt & Rick Face Association Exclusion**:
  - `geomind_chat_startup_biometric_scan` passively defaults to Guest without interactively prompting an unrecognized interlocutor at startup.
  - `geomind_chat_learn_conversational_turn` omits face enrollment when `cand_user` contains "rick".
  - REPL loop lacks interactive `/help` command displaying available biometric and session commands.
