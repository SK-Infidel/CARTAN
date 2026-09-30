# Sprint 494 Walkthrough: Startup Biometric Authentication, Dynamic Guest Onboarding & Consensual Face Enrollment

**Sprint**: 494  
**Date**: 2026-09-30  
**Status**: Completed & Verified  

---

## 1. Executive Summary

Sprint 494 implemented automatic startup biometric facial verification and a dynamic guest onboarding protocol for GeoMind:
1. **Startup Camera Snapshot & 1:N Biometric Matching**:
   Upon booting (`geomind.exe` in interactive REPL or `--chat` mode), GeoMind automatically triggers the webcam via `tools/capture_camera.exe`, extracts a 320-D eikonal face feature vector projected onto the unit hypersphere $S^{319}$, and queries all registered face profiles in SQLite Tier 2 Cognitive Memory (`Domain 10: USERS_AND_RELATIONSHIPS`).
2. **Seamless Creator Auto-Login**:
   If the captured face matches a registered profile (e.g., `User:Rick` with cosine similarity $\ge 0.85$), GeoMind immediately authenticates the session without asking questions or requesting consent. The cognitive preamble reinforces Rick as Creator and Architect.
3. **Dynamic Guest Onboarding & Conversational Consent**:
   If an unrecognized face is observed, GeoMind flags `g_pending_guest_face = 1.0` in RAM and conditions its cognitive preamble:
   > *"The person speaking with you is an unrecognized guest whom you just observed through the camera. Greet them politely, introduce yourself as GeoMind, acknowledge Rick as your creator, ask what their name is, and ask if they would like you to remember their face and name for future interactions."*
4. **Consensual Dynamic Profile Enrollment & Zero-Retention Privacy**:
   - If the guest provides their name and grants consent (`"Yes"`, `"Remember me"`, etc.), GeoMind dynamically enrolls `User:<Name>` in Domain 10, persists the 320-D eikonal embedding, elevates the session, and clears the pending snapshot.
   - If the guest declines (`"No"`, `"Don't"`, `"Refuse"`), GeoMind strictly respects their privacy: the pending embedding is purged from RAM and zero biometric records are written to SQLite.
5. **Subsequent Recognition**:
   On all future boots, the newly enrolled person is recognized automatically through 1:N matching without repeating the onboarding sequence.

---

## 2. Key Code Changes

### A. Multi-User Registered Face Lookup (`src/std/sqlite_vec.cl`)
- Implemented `sqlite_vec_prepare_registered_face_users(db)` and `cartan_sqlite_prepare_registered_face_users(db)`:
  ```cartan
  SELECT entity_name FROM entity_states
  WHERE domain_id = 10.0 AND attribute_name = 'face_registered' AND attribute_value = '1';
  ```
- Ensures leak-free iteration over registered profiles in Domain 10.

### B. Automatic Startup Biometric Scan (`test/geomind/chat.cl`)
- Added global state `g_pending_guest_face: float = 0.0`.
- Hardened `geomind_chat_capture_face_frame()`:
  - Purges any stale `scratch/camera_frame.bmp` before invoking `tools/capture_camera.exe`.
  - Unlinks the temporary BMP file immediately after loading pixel buffers into RAM.
- Implemented `geomind_chat_startup_biometric_scan(db)`:
  - Iterates through registered face maps via `sqlite_vec_prepare_registered_face_users`.
  - Deserializes candidate embeddings from CSV, computes cosine similarity on $S^{319}$, and frees candidate memory immediately to prevent heap buildup.
  - If $\max(\text{sim}) \ge 0.85$: authenticates user, elevates session, clears guest flag.
  - If $\max(\text{sim}) < 0.85$: sets `g_active_user_id = "User:Guest"`, `g_active_user_verified = 0.0`, and retains captured vector with `g_pending_guest_face = 1.0`.

### C. Cognitive Preamble Conditioning & Consent Protocol (`test/geomind/chat.cl`)
- Conditioned `geomind_chat_build_cognitive_preamble(db)`:
  - When `g_pending_guest_face == 1.0`, instructs the model to introduce GeoMind, acknowledge Rick, ask for their name, and request permission to store their face map.
- Updated `geomind_chat_learn_conversational_turn(speaker, text)`:
  - Extracts guest name patterns (*"My name is..."*, *"I am..."*, *"Call me..."*).
  - Evaluates consent affirmations (*"yes"*, *"sure"*, *"remember me"*, *"permission granted"*): persists `User:<Name>` in Domain 10 with the 320-D embedding and elevates session.
  - Evaluates consent refusals (*"no"*, *"don't"*, *"refuse"*): immediately discards pending embedding with zero database writes.

### D. REPL Boot Integration & Production Sync (`test/geomind/main.car`)
- Integrated `geomind_chat_startup_biometric_scan(db)` at the head of `geomind_chat_interactive_loop` and one-shot `--chat`.
- Synchronized production `geomind.exe` binary across `./geomind.exe`, `bin/geomind.exe`, and `test/geomind/geomind.exe`.

---

## 3. Empirical Verification Results

### Dedicated Suite (`test/geomind/test_startup_biometric_onboarding.car`)
Execution command:
```powershell
.\cartanc.exe build test/geomind/test_startup_biometric_onboarding.car -o scratch/test_onboarding.exe
.\scratch\test_onboarding.exe
```

Test Results:
```text
======================================================================
[TEST] Sprint 494: Startup Biometric Authentication & Guest Onboarding
======================================================================

--- GATE 1: Startup Biometric Scan with Known Face (User:Rick Auto-Login) ---
    Evaluating 'User:Rick' (Rick) face map -> similarity: 0.9994
    INTERLOCUTOR RECOGNIZED: Rick (Father / Primary Creator, similarity 0.9994 >= 0.85). Authenticated.
  Rick Preamble: "You are GeoMind. Your creator and architect is Rick. Your role is Neuro-Symbolic Cognitive Assistant. The user speaking with you is Rick (Creator & Architect, Verified). Always identify yourself as GeoMind and acknowledge Rick as your creator."
  [PASS] Gate 1: Known Face Startup Auto-Login Verified.

--- GATE 2: Startup Biometric Scan with Unknown Face (Guest Onboarding) ---
  Cross-similarity between Rick and Alice: 0.0382
    Evaluating 'User:Rick' (Rick) face map -> similarity: 0.0382
    Interlocutor not recognized (best similarity 0.0382 < 0.85). Initiating Guest onboarding.
  Guest Onboarding Preamble: "You are GeoMind. Your creator and architect is Rick. Your role is Neuro-Symbolic Cognitive Assistant. The person speaking with you is an unrecognized guest whom you just observed through the camera. Greet them politely, introduce yourself as GeoMind, acknowledge Rick as your creator, ask what their name is, and ask if they would like you to remember their face and name for future interactions."
  [PASS] Gate 2: Unknown Face Guest Mode and Consent Preamble Verified.

--- GATE 3: Conversational Onboarding Turn with Consent ---
    Consensual enrollment: Saved 320-D face map for 'User:Alice' in Domain 10.
  Reconstructed Alice face cosine similarity: 1.000000
  [PASS] Gate 3: Dynamic User Enrollment & Face Map Persistence Verified.

--- GATE 4: Subsequent Startup Recognition (Cold Boot) ---
    Evaluating 'User:Alice' (Alice) face map -> similarity: 0.9994
    Evaluating 'User:Rick' (Rick) face map -> similarity: 0.0381
    INTERLOCUTOR RECOGNIZED: Alice (Conversational Partner, similarity 0.9994 >= 0.85). Authenticated.
  Alice Cold Boot Preamble: "You are GeoMind. Your creator and architect is Rick. Your role is Neuro-Symbolic Cognitive Assistant. The user speaking with you is Alice (Verified Interlocutor). Always identify yourself as GeoMind and acknowledge Rick as your creator."
  [PASS] Gate 4: Subsequent Startup Recognition Verified.
======================================================================
[SUMMARY] Passed: 4, Failed: 0
======================================================================
```

---

## 4. How to Test Interactively

1. **Launch GeoMind REPL**:
   ```powershell
   .\geomind.exe
   ```
2. **What Happens Automatically**:
   - The camera indicator will light up briefly as `tools/capture_camera.exe` captures a 640x480 frame.
   - GeoMind extracts your face map and checks `Domain 10: USERS_AND_RELATIONSHIPS`.
   - If your face is already registered via `/register-face`, GeoMind will display:
     `[BIOMETRIC] Verified interlocutor: Rick (similarity: 0.9994 >= 0.85). Authenticated.`
   - If you have not registered your face yet, run `/register-face` once while seated in front of the camera.
   - Next time you boot, you are automatically recognized.
3. **Testing Guest Onboarding**:
   - Have a guest sit in front of the camera, or cover the camera to simulate a stranger.
   - GeoMind will boot into Guest mode and greet them: introducing itself, acknowledging Rick as creator, asking their name, and requesting consent to remember them.
   - When they reply: *"My name is Alice and yes, you have permission to remember me"*, GeoMind dynamically enrolls them.
