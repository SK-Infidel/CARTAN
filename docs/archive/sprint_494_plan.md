# Sprint 494 Implementation Plan: Startup Biometric Authentication, Dynamic Guest Onboarding & Face Consent Protocol

## 1. Objectives & Architectural Scope
- Implement automatic startup camera capture and 1:N biometric identification against all registered users in Domain 10 (`USERS_AND_RELATIONSHIPS`).
- If recognized ($\ge 0.85$ cosine similarity), authenticate immediately without interrogating the user.
- If unrecognized, initiate a guest session with a pending face snapshot (`g_pending_guest_face = 1.0`), condition the cognitive preamble to introduce GeoMind, acknowledge Rick as creator, ask the guest's name, and request consent to remember their face and name.
- Upon conversational consent, enroll the new profile `User:<Name>` into Domain 10 with the captured 320-D eikonal face embedding.
- Prove subsequent startup recognition and maintain 100% zero-regression status across the 88-target compiler test suite.

---

## 2. Technical Design & Interfaces

### Component 1: Multi-User Registered Face Enumeration (`src/std/sqlite_vec.cl`)
```cartan
fn sqlite_vec_prepare_registered_face_users(db: ptr) -> ptr {
    let sql = "SELECT entity_name FROM entity_states WHERE domain_id = 10.0 AND attribute_name = 'face_registered' AND attribute_value = '1';";
    return sqlite_vec_prepare(db, sql);
}
```

### Component 2: Startup Biometric Scan (`test/geomind/chat.cl`)
```cartan
var g_pending_guest_face: float = 0.0;

fn geomind_chat_startup_biometric_scan(db: ptr) -> float;
```
- Calls `tools/capture_camera.exe scratch/camera_frame.bmp 640 480`.
- If successful, extracts 320-D eikonal embedding on $S^{319}$.
- Queries all registered users via `sqlite_vec_prepare_registered_face_users(db)`.
- Calculates `vision_cosine_similarity(live_emb, user_emb, 320.0)` for each registered user.
- If `max_similarity >= 0.85`:
  - `g_active_user_id = best_user`
  - `g_active_user_verified = 1.0`
  - `g_pending_guest_face = 0.0`
  - Logs authentication to terminal.
- Else:
  - `g_active_user_id = "User:Guest"`
  - `g_active_user_verified = 0.0`
  - `g_pending_guest_face = 1.0`
  - Caches live embedding in `g_active_face_embedding`.
  - Logs guest observation.

### Component 3: Cognitive Preamble Conditioning (`test/geomind/chat.cl`)
- When `g_pending_guest_face == 1.0`:
  > *"The person speaking with you is an unrecognized guest whom you just observed through the camera. Greet them politely, introduce yourself as GeoMind, acknowledge Rick as your creator, ask what their name is, and ask if they would like you to remember their face and name for future interactions."*

### Component 4: Conversational Onboarding & Consent Extraction (`test/geomind/chat.cl`)
- In `geomind_chat_learn_conversational_turn`:
  - Extracts candidate name.
  - If `g_pending_guest_face == 1.0`:
    - Checks for consent keywords (`"yes"`, `"sure"`, `"ok"`, `"please"`, `"remember"`, `"save"`).
    - If consent detected:
      - Creates `User:<Name>` in Domain 10.
      - Serializes `g_active_face_embedding` to CSV and saves via `sqlite_vec_save_user_face_embedding(db, u_id, csv)`.
      - Sets `g_active_user_id = u_id`, `g_active_user_verified = 1.0`, `g_pending_guest_face = 0.0`.
    - If refusal detected (`"no"`, `"don't"`, `"do not"`):
      - Rejects enrollment, clears `g_pending_guest_face = 0.0`.

### Component 5: REPL Chat Integration (`test/geomind/main.car`)
- Triggers `geomind_chat_startup_biometric_scan(db)` at the entrance of `geomind_chat_interactive_loop`.

---

## 3. Verification Plan
- Author `test/geomind/test_startup_biometric_onboarding.car` with 4 gates:
  - Gate 1: Startup biometric scan with known face -> auto-authentication as Rick.
  - Gate 2: Startup biometric scan with unknown face -> guest mode + pending face snapshot + consent preamble.
  - Gate 3: Conversational onboarding turn with consent -> dynamic `User:Alice` enrollment and immediate session elevation.
  - Gate 4: Subsequent scan after onboarding -> recognized and authenticated automatically without prompting.
- Run `tools/run_affected_tests.ps1 -All` verifying 88/88 targets.
