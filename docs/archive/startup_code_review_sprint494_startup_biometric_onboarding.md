# Startup Code Review: Sprint 494 — Startup Biometric Authentication, Dynamic Guest Onboarding & Face Consent Protocol

## 1. Context & Objectives
- **Context**: In Sprint 493, we established Domain 10 (`USERS_AND_RELATIONSHIPS`), built the hardware camera capture tool (`tools/capture_camera.exe`), implemented 320-D eikonal face feature extraction with unit hypersphere $S^{319}$ projection and cosine similarity in `src/std/vision.cl`, and created interactive verification commands.
- **Sprint 494 Mandate (from Rick)**:
  1. Automatic startup camera snapshot and biometric scan upon REPL boot (`geomind.exe chat`).
  2. If the face matches a registered profile (e.g. `User:Rick`, cosine similarity $\ge 0.85$), immediately authenticate the session and address Rick directly without asking who he is.
  3. If the face is unrecognized, initiate a guest session with a pending face snapshot, introduce itself as GeoMind created by Rick, ask for their name, and ask permission to remember their face and name for future interactions.
  4. If permission is granted in conversation, enroll the new profile `User:<Name>` into Domain 10 with the captured 320-D face map.
  5. On subsequent startups, recognize the newly enrolled person automatically.

---

## 2. Issues Discovered

### [ISSUE-322] Absence of Automatic Startup Biometric Scan in REPL Chat Boot Pipeline
- **Component**: [`test/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car), [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl)
- **Finding**: `geomind_chat_interactive_loop` and `geomind_chat_start` boot up passively into `g_active_user_id = "User:Guest"` without invoking the camera or checking registered face embeddings in Domain 10.
- **Required Action**: Implement `geomind_chat_startup_biometric_scan(db)` triggered at the entrance of `geomind_chat_interactive_loop` and `geomind_chat_generate_reply_multimodal`.

### [ISSUE-323] Missing Multi-User Registered Face Lookup in SQLite Vector Domain 10
- **Component**: [`src/std/sqlite_vec.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/sqlite_vec.cl)
- **Finding**: `sqlite_vec.cl` only provides point lookups for individual users (`sqlite_vec_get_user_face_embedding(db, user_id)`). It lacks a mechanism to enumerate all registered users with active face maps (`face_registered == '1'`) to perform 1:N biometric identification.
- **Required Action**: Implement `sqlite_vec_prepare_registered_face_users(db)` (or helper list) executing `SELECT entity_name FROM entity_states WHERE domain_id = 10.0 AND attribute_name = 'face_registered' AND attribute_value = '1'`.

### [ISSUE-324] Unhandled Guest Face Consent and Conversational Biometric Enrollment Protocol
- **Component**: [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl)
- **Finding**: `geomind_chat_build_cognitive_preamble` and `geomind_chat_learn_conversational_turn` have no state tracking for an unrecognized face waiting for consent (`g_pending_guest_face`). If an unknown person speaks, the model does not ask permission to save their face, and conversational learning only stores text attributes in Domain 10 without attaching the captured face embedding.
- **Required Action**:
  - Add `g_pending_guest_face` flag and cache the live 320-D eikonal embedding.
  - Condition the guest preamble when `g_pending_guest_face == 1.0` to introduce GeoMind, acknowledge Rick, ask for their name, and request consent to store their face map.
  - In `geomind_chat_learn_conversational_turn`, detect consent/rejection. If consented, serialize and save the 320-D embedding to `User:<Name>` in Domain 10.

---

## 3. Logical Dependency Graph
```
[tools/capture_camera.exe] (Windows Media Foundation Hardware Ingestion)
       │
       ▼
[src/std/vision.cl] (320-D Eikonal Feature Extraction & Cosine Similarity)
       │
       ▼
[src/std/sqlite_vec.cl] (Domain 10: USERS_AND_RELATIONSHIPS 1:N Face Scan)
       │
       ▼
[test/geomind/chat.cl] (Startup Biometric Scan & Consent Protocol)
       │
       ▼
[test/geomind/main.car] (REPL Loop Entry Integration)
       │
       ▼
[test/geomind/test_startup_biometric_onboarding.car] (4-Gate Verification Suite)
```

---

## 4. Architectural Sign-Off
- Zero mock / zero simulation compliance: authentic camera frame capture, genuine L2 normalization on $S^{319}$, real SQLite transactions, and genuine conversational turn analysis.
- Privacy & Consent: Face embeddings are never stored without explicit user consent.
- Ready to proceed to Sprint 494 Plan and Task List.
