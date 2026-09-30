# Sprint 493 Plan: Domain 10 USERS_AND_RELATIONSHIPS, Camera Capture, Eikonal Face Mapping & Interlocutor Verification

## Sprint Goal
Eliminate ungrounded interlocutor assumptions by delivering a hardware camera capture tool (`tools/capture_camera.exe`), authentic eikonal face feature extraction and cosine verification in `src/std/vision.cl`, Domain 10 (`USERS_AND_RELATIONSHIPS`) in SQLite `cognitive_memory.db`, and an interactive dialogue protocol that greets guests neutrally and supports voluntary face enrollment.

---

## Architecture & Work Breakdown

### Work Package 1: Hardware Camera Capture Tool (`tools/capture_camera.c` -> `tools/capture_camera.exe`)
- Leverage Windows Media Foundation (`IMFSourceReader`, `MFVideoFormat_RGB32`).
- Accept optional arguments: `tools/capture_camera.exe [output_path] [width] [height]`.
- Default to 640x480 resolution for low-latency (< 2ms) BMP decoding in pure CARTAN.
- Write valid uncompressed 24-bit BMP with proper padding and headers.

### Work Package 2: Native Eikonal Face Mapping & Cosine Similarity (`src/std/vision.cl`)
- `vision_extract_face_embedding(img: Image) -> ptr`:
  - Extract central facial receptive field patch (e.g. 16x16 RGB = 768 features).
  - Project through `vision_project_to_eikonal_stream(patch, 768.0, 320.0)`.
  - Normalize to unit L2 length: $\hat{f} = \vec{f} / \|\vec{f}\|_2$.
- `vision_cosine_similarity(vec_a: ptr, vec_b: ptr, dim: float) -> float`:
  - Compute authentic dot product $\sum_{i=0}^{d-1} a_i b_i$ across 320 dimensions.
- Vector serialization routines for SQLite storage:
  - `vision_serialize_vector_csv(vec: ptr, dim: float) -> string`
  - `vision_deserialize_vector_csv(str: string, dim: float) -> ptr`

### Work Package 3: Domain 10 `USERS_AND_RELATIONSHIPS` (`src/std/sqlite_vec.cl`)
- Register Domain 10 in `sqlite_vec_init_schema` and `sqlite_vec_init_domains`.
- Seed initial profiles:
  - `User:Rick` (`preferred_name='Rick'`, `role='Creator & Architect'`, `relationship='Father / Primary Creator'`, `permission_tier='root'`, `face_registered='0'`).
  - `User:Guest` (`preferred_name='Guest'`, `role='Visitor'`, `relationship='Unverified Interlocutor'`, `permission_tier='guest'`, `face_registered='0'`).
- Implement user profile helpers:
  - `sqlite_vec_get_user_attr(db, user_id, attr) -> string`
  - `sqlite_vec_set_user_attr(db, user_id, attr, val) -> float`
  - `sqlite_vec_save_user_face_embedding(db, user_id, emb_str) -> float`
  - `sqlite_vec_get_user_face_embedding(db, user_id) -> string`

### Work Package 4: Interactive Interlocutor Protocol (`test/geomind/chat.cl`, `test/geomind/main.car`)
- Maintain active interlocutor state (`g_active_user_id`, defaults to `"User:Guest"`).
- In `geomind_chat_build_cognitive_preamble()`:
  - If interlocutor is `"User:Guest"`, format neutral guest instruction:
    `"The user speaking with you is an unverified guest. Greet them politely and ask who they are without assuming their identity."`
  - If interlocutor is `"User:Rick"`, format creator instruction:
    `"The user speaking with you is Rick (Creator & Architect, Verified). Always identify yourself as GeoMind and acknowledge Rick as your creator."`
- Implement interactive commands:
  - `/whoami`: Display active interlocutor ID, name, role, and verification status.
  - `/capture-face`: Snap webcam frame to `scratch/camera_frame.bmp` and compute 320-D eikonal embedding.
  - `/register-face [user_id]`: Save active face embedding to specified user profile in Domain 10.
  - `/verify-face`: Snap live frame, compare against registered face embeddings in Domain 10 via cosine similarity, and authenticate if $\ge 0.85$.
  - `/switch-user [user_id]`: Manually switch active interlocutor profile.

### Work Package 5: Empirical Verification & Regression Clearance
- Author regression test `test/geomind/test_face_mapping_and_user_domain.car` testing:
  - Gate 1: Domain 10 registration and user entity seeding (`User:Rick`, `User:Guest`).
  - Gate 2: Vector serialization/deserialization bit-for-bit fidelity and L2 normalization.
  - Gate 3: Face patch projection and cosine similarity validation (orthogonal vs identical vs perturbed vectors).
  - Gate 4: Interlocutor verification and cognitive preamble conditioning.
- Rebuild production `geomind.exe` and synchronize binaries.
- Run full 88-target compiler regression suite (`tools/run_affected_tests.ps1 -All`).
