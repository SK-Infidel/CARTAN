# Startup Code Review: Sprint 493 — Domain 10 USERS_AND_RELATIONSHIPS, Camera Capture, Eikonal Face Mapping & Interlocutor Verification

## Executive Summary
This startup code review establishes the architectural blueprint for Sprint 493. The objective is to eliminate ungrounded assumptions regarding interlocutor identity by implementing:
1. Genuine hardware camera capture via Windows Media Foundation (`tools/capture_camera.exe`).
2. Authentic facial feature extraction and eikonal geodesic projection into 320-D normalized tangent vectors (`src/std/vision.cl`).
3. Domain 10 (`USERS_AND_RELATIONSHIPS`) in SQLite Cognitive Memory (`cognitive_memory.db`) to decouple GeoMind's self-identity (Domain 9) from user profiles, facial embeddings, and relationships (`src/std/sqlite_vec.cl`).
4. An interactive dialogue protocol that greets unverified speakers neutrally, requests identity confirmation, and offers voluntary facial verification/enrollment (`test/geomind/chat.cl`, `test/geomind/main.car`).

---

## 1. Codebase Inventory & Component Audit

### Component A: Hardware Camera Ingestion (`tools/capture_camera.c`, `src/std/fs.cl`)
- **Current State**: `docs/spec.md` specified stream syntax (`stream[rgba, 60fps]("camera://0")`), but no concrete camera capture runtime existed. Multimodal inputs relied on static disk paths (`--image <path>`).
- **Hardware Audit**: Physical verification confirmed active hardware:
  - `HP 5MP Camera` (Status: `OK`, active video capture source).
  - `HP IR Camera` (Status: `OK`, infrared depth/biometric).
  - `Logi C615 HD WebCam` (Status: `Unknown`).
- **Solution**: Author `tools/capture_camera.c` utilizing Windows Media Foundation (`IMFSourceReader`, `MFVideoFormat_RGB32`, hardware video processor). Compiles natively with `zig cc -lmf -lmfplat -lmfreadwrite -lmfuuid -lole32` into `tools/capture_camera.exe`. Supports target resolutions (640x480 default for 2ms decode latency) and writes standard uncompressed 24-bit BMP to disk.

### Component B: Computer Vision & Eikonal Face Mapping (`src/std/vision.cl`)
- **Current State**: `src/std/vision.cl` implements `Image`, `vision_load_bmp`, `vision_extract_patch`, and `vision_project_to_eikonal_stream`. However, it lacks dedicated facial quadrant localization, unit hypersphere normalization, cosine similarity metrics, and vector serialization routines.
- **Solution**:
  1. Implement `vision_extract_face_patch(img: Image, patch_dim: float) -> ptr` to sample the central facial region with luminance normalization.
  2. Implement `vision_extract_face_embedding(img: Image) -> ptr` to project the face patch into a 320-D eikonal stream and normalize to unit Euclidean length ($\|\vec{f}\| = 1.0$).
  3. Implement `vision_cosine_similarity(vec_a: ptr, vec_b: ptr, dim: float) -> float`.
  4. Implement `vision_serialize_vector(vec: ptr, dim: float) -> string` and `vision_deserialize_vector(str: string, dim: float) -> ptr` for persistent SQLite storage.

### Component C: Domain 10 `USERS_AND_RELATIONSHIPS` (`src/std/sqlite_vec.cl`)
- **Current State**:
  - `User.preferred_name` was previously stored in Domain 1 (`PHYSICS_AND_WORLD`).
  - Domain 9 (`SELF_AND_IDENTITY`) tracks `Self.name`, `Self.creator`, `Self.role`, `Self.nature`.
  - Storing user preferences globally creates identity collision when another speaker interacts with GeoMind.
- **Solution**:
  1. Register Domain 10: `USERS_AND_RELATIONSHIPS` ("Interpersonal identities, user profiles, face maps, and creator relationships").
  2. Default seed: `User:Rick` (`preferred_name='Rick'`, `role='Creator & Architect'`, `relationship='Father / Primary Creator'`, `permission_tier='root'`, `face_registered='0'`).
  3. Default seed: `User:Guest` (`preferred_name='Guest'`, `role='Visitor'`, `relationship='Unverified Interlocutor'`, `permission_tier='guest'`, `face_registered='0'`).
  4. Add API functions in `sqlite_vec.cl`:
     - `sqlite_vec_get_user_attr(db, user_id, attr)`
     - `sqlite_vec_set_user_attr(db, user_id, attr, val)`
     - `sqlite_vec_save_user_face_embedding(db, user_id, emb_str)`
     - `sqlite_vec_get_user_face_embedding(db, user_id) -> string`

### Component D: Dialogue Protocol & Interlocutor Verification (`test/geomind/chat.cl`, `test/geomind/main.car`)
- **Current State**:
  - `geomind_chat_build_cognitive_preamble()` unconditionally asserted `The user speaking with you is Rick`.
  - When another person speaks, GeoMind addresses them as Rick, causing conversational incoherence.
- **Solution**:
  1. Track active session interlocutor in `g_active_user_id` (defaults to `"User:Guest"` unless authenticated).
  2. If `g_active_user_id == "User:Guest"`, preamble states:
     `"The user speaking with you is an unverified guest. Greet them politely and ask for their identity."`
  3. If authenticated (e.g. via face match or introduction), preamble states:
     `"The user speaking with you is Rick (Creator & Architect, Verified)."`, allowing authentic recognition.
  4. Implement REPL commands:
     - `/whoami`: Displays current active interlocutor, permission tier, and face registration status.
     - `/capture-face`: Triggers camera snapshot, extracts 320-D eikonal face map, and displays telemetry.
     - `/register-face [user_id]`: Saves captured face map to SQLite under the specified user profile.
     - `/verify-face`: Captures a live frame, queries registered face maps in Domain 10, computes cosine similarity, and authenticates the user if $\text{similarity} \ge 0.85$.

---

## 2. Logical Dependency Tree

```
[Physical Webcam Device]
       │
       ▼ (Media Foundation IMFSourceReader)
[tools/capture_camera.exe]
       │
       ▼ (scratch/camera_frame.bmp, uncompressed 24-bit BMP)
[src/std/vision.cl]
  ├── vision_load_bmp()
  ├── vision_extract_face_patch()
  ├── vision_project_to_eikonal_stream()
  ├── cartan_vec_normalize_l2()
  └── vision_cosine_similarity()
       │
       ▼ (320-D Eikonal Face Map)
[src/std/sqlite_vec.cl]
  └── Domain 10: USERS_AND_RELATIONSHIPS
        ├── User:Rick (root, creator, face_embedding)
        └── User:Guest (guest, unverified)
       │
       ▼ (Active Interlocutor State)
[test/geomind/chat.cl]
  ├── geomind_chat_build_cognitive_preamble() (Conditioned on active user)
  ├── geomind_chat_verify_interlocutor_face() (Cosine matching against Domain 10)
  └── geomind_chat_enroll_interlocutor_face() (Voluntary face registration)
       │
       ▼ (Interactive REPL)
[test/geomind/main.car]
  ├── /whoami
  ├── /capture-face
  ├── /register-face
  └── /verify-face
```

---

## 3. New Technical Debt & Issue Identifiers

- **`[ISSUE-319]`**: Absence of Hardware Camera Capture & Real Frame Ingestion Tooling.
- **`[ISSUE-320]`**: Global Interlocutor Assumption & Lack of Domain 10 User/Relationship Profile Separation.
- **`[ISSUE-321]`**: Missing Eikonal Face Feature Extraction & Vector Cosine Verification in Vision Standard Library.

---

## 4. Definition of Done (DoD) for Sprint 493

- [ ] `tools/capture_camera.exe` compiled and verified capturing real frames from `HP 5MP Camera`.
- [ ] `src/std/vision.cl` implements face patch extraction, eikonal 320-D embedding, L2 normalization, cosine similarity, and serialization.
- [ ] `src/std/sqlite_vec.cl` registers Domain 10 (`USERS_AND_RELATIONSHIPS`) with `User:Rick` and `User:Guest` profiles and face embedding persistence.
- [ ] `test/geomind/chat.cl` and `test/geomind/main.car` implement neutral guest preambles, `/whoami`, `/capture-face`, `/register-face`, and `/verify-face`.
- [ ] Empirical regression test `test/geomind/test_face_mapping_and_user_domain.car` passes all gates.
- [ ] `geomind.exe` rebuilt and synchronized.
- [ ] All 88 compiler test suite targets pass with 0 regressions via `tools/run_affected_tests.ps1 -All`.
- [ ] `CHANGELOG.md`, `ISSUES.md`, and `docs/ROADMAP.md` updated and committed.
