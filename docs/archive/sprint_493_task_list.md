# Sprint 493 Task List: Domain 10 USERS_AND_RELATIONSHIPS, Camera Capture, Eikonal Face Mapping & Interlocutor Verification

- [x] **Task 1: Camera Capture Developer Tool (`tools/capture_camera.c` -> `tools/capture_camera.exe`)**
  - [x] Write `tools/capture_camera.c` with Media Foundation `IMFSourceReader` and `MFVideoFormat_RGB32`.
  - [x] Support command line arguments `[output_path] [width] [height]` defaulting to `scratch/camera_frame.bmp` 640x480.
  - [x] Compile with `zig cc` linking `-lmf -lmfplat -lmfreadwrite -lmfuuid -lole32`.
  - [x] Empirically verify real frame capture on `HP 5MP Camera`.

- [x] **Task 2: Native Face Feature Extraction & Cosine Verification (`src/std/vision.cl`)**
  - [x] Implement `vision_extract_face_patch(img: Image, patch_dim: float) -> ptr`.
  - [x] Implement `vision_extract_face_embedding(img: Image) -> ptr` with 320-D eikonal projection and L2 unit normalization.
  - [x] Implement `vision_cosine_similarity(vec_a: ptr, vec_b: ptr, dim: float) -> float`.
  - [x] Implement `vision_serialize_vector_csv` and `vision_deserialize_vector_csv`.

- [x] **Task 3: Domain 10 Registration & User Profile Persistence (`src/std/sqlite_vec.cl`)**
  - [x] Register Domain 10: `USERS_AND_RELATIONSHIPS` in `sqlite_vec_init_schema` and seeding routines.
  - [x] Seed default profiles `User:Rick` (creator, root) and `User:Guest` (guest, unverified).
  - [x] Implement `sqlite_vec_get_user_attr`, `sqlite_vec_set_user_attr`, `sqlite_vec_save_user_face_embedding`, `sqlite_vec_get_user_face_embedding`.

- [x] **Task 4: Dialogue Protocol & Interlocutor State (`test/geomind/chat.cl`, `test/geomind/main.car`)**
  - [x] Implement `g_active_user_id` tracking (defaults to `"User:Guest"`).
  - [x] Update `geomind_chat_build_cognitive_preamble()` to differentiate verified creator vs unverified guest.
  - [x] Wire `/whoami`, `/capture-face`, `/register-face`, `/verify-face`, and `/switch-user` into REPL.
  - [x] Update `geomind_chat_learn_conversational_turn()` to update active user profile rather than global `User.preferred_name`.

- [x] **Task 5: Empirical Verification & Regression Testing**
  - [x] Author `test/geomind/test_face_mapping_and_user_domain.car` testing all 4 gates.
  - [x] Rebuild and synchronize `geomind.exe`.
  - [x] Execute `tools/run_affected_tests.ps1 -All` verifying 88/88 targets.
  - [x] Update `ISSUES.md` (`[ISSUE-319]`, `[ISSUE-320]`, `[ISSUE-321]`).
  - [x] Update `CHANGELOG.md` (`[8.451.0]`) and `docs/ROADMAP.md`.
  - [x] Save walkthrough to `docs/archive/sprint_493_walkthrough.md`.
