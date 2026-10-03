# Sprint 511 Walkthrough: Real-Time Biometric Onboarding & Interlocutor Recognition

## Executive Summary
In Sprint 511, we diagnosed and resolved the root cause of why startup biometric face scanning and profile creation failed to actively prompt/enroll Rick's face and create a user profile in Domain 10 (`USERS_AND_RELATIONSHIPS`) of `cognitive_memory.db`.

Rick reported:
> *"Biometrics isn't working. It never tries to register my face or create a profile for me. I don't think it tries to recognize the user at startup.."*

Through systematic architectural analysis, interactive onboarding implementation, compiler bootstrap convergence, and empirical hardware verification with the physical webcam, we achieved seamless live biometric registration and cold-start recognition.

---

## 1. Root Cause Analysis

### A. Passive Startup Deadlock (`test/geomind/chat.cl:1553`)
When `geomind_chat_startup_biometric_scan` executed at startup:
- The webcam captured a frame and extracted a 320-D eikonal embedding on $S^{319}$.
- Because no enrolled face existed in Domain 10 (or `best_sim < 0.85`), the function silently printed:
  `[GeoMind Biometrics] Unrecognized interlocutor. Initiating Guest onboarding session.`
- It returned `0.0` without prompting the user to register or configure a profile.
- The REPL then started as an unverified guest session without offering any onboarding options.

### B. Conversational Enrollment Exclusion of Rick (`test/geomind/chat.cl:1071`)
In `geomind_chat_learn_conversational_turn`:
- When an interlocutor said *"My name is Rick"*, the name extraction matched `User:Rick`.
- However, the code containing `sqlite_vec_save_user_face_embedding` was nested strictly inside the `else` branch of `cand_user` matching (intended for new unknown guest names).
- As a result, whenever Rick introduced himself, his face map was completely discarded!

### C. Missing REPL Discovery (`test/geomind/main.car:580`)
- The interactive REPL loop lacked `/help`, obscuring commands like `/register-face`, `/verify-face`, and `/whoami`.
- `/register-face` required raw entity names without automatically formatting `User:<name>`.

### D. Compiler Bootstrap Fixpoint Lag
- Sprint 508 introduced `@cartan_simd_dot_i8_f32` in `src/cartanc/llvm_codegen.car`, but the active `bin/cartanc.exe` binary had not completed a 3-stage bootstrap fixpoint rebuild.
- When compiling `bin/geomind.exe`, the compiler emitted unresolved external symbol references to `@cartan_simd_dot_i8_f32`.

---

## 2. Implementations & Architecture

### A. Interactive Startup Onboarding (`test/geomind/chat.cl`)
In `geomind_chat_startup_biometric_scan`:
- When an unmapped face is detected at startup, the system actively prompts:
  `[GeoMind Biometrics] Unregistered interlocutor detected. Would you like to register your biometric face map and configure your profile? (y/n): `
- If `y` / `yes`:
  - Prompts for Name (Enter defaults to `"Rick"`).
  - Prompts for Role/Relationship (Enter defaults to `"Creator & Architect"`).
  - Normalizes the 320-D eikonal embedding to unit length on $S^{319}$ and serializes to CSV.
  - Persists to Domain 10 (`USERS_AND_RELATIONSHIPS`) in `cognitive_memory.db` with `face_registered = '1'`, `verified = '1'`, `role = 'Creator & Architect'`, and `permission_tier = 'root'`.
  - Authenticates the session immediately.
- If non-interactive (piped / Enter / EOF): defaults safely without blocking.

### B. Robust String Handling & Heap Safety (`test/geomind/chat.cl`)
- Handled `cartan_read_line()` contract where empty inputs return static literal `"exit"`.
- Guarded `veto_string_to_lower` against freeing static literals `""` (`if (cartan_string_length(ptr) > 0.0) { free(ptr); }`), eliminating Windows heap corruption (`0xC0000374`).

### C. Conversational Face Enrollment Fix (`test/geomind/chat.cl`)
- Unified pending face enrollment across all names, ensuring that when the interlocutor introduces themselves as Rick, the pending face embedding is saved to `User:Rick`.
- Generalized `geomind_chat_build_cognitive_preamble` to dynamically query Domain 10 and condition the system preamble with the recognized user's name and role.

### D. REPL Command Polish (`test/geomind/main.car`)
- Added `/help` command listing all interactive commands: `/whoami`, `/who`, `/identity`, `/state`, `/clear`, `/new`, `/reset`, `/debug`, `/sleep`, `/register-face`, `/verify-face`, and `/capture-face`.
- Upgraded `/register-face [user]` to auto-prefix `"User:"` and trigger immediate live webcam ingestion.

### E. Compiler 3-Stage Bootstrap Fixpoint
- Recompiled `cartanc_fresh.exe` -> `cartanc_stage3.exe` -> `cartanc_stage4.exe`.
- Confirmed bit-for-bit SHA-256 fixpoint parity:
  `SHA256(cartanc_stage3.ll) == SHA256(cartanc_stage4.ll) == 8F0D487C714F5EF8C755167A872188CD7643F225EAFBDA9E2BD4E62775A20B7B`.
- Synchronized fresh binary to `bin/cartanc.exe` and `cartanc.exe`.
- Rebuilt `bin/geomind.exe` with clean compilation and linkage.

---

## 3. Empirical Verification Results

### A. Real Hardware Biometric Enrollment
1. Executed live enrollment on Rick's physical webcam:
   - Captured 640x480 frame via Windows Media Foundation (`tools/capture_camera.exe`).
   - Extracted 320-D eikonal hypersphere vector on $S^{319}$.
   - Registered `User:Rick` with role `Creator & Architect`, `permission_tier: root`, `face_registered: 1`.

### B. Cold-Boot Startup Recognition (100% Real Hardware & Zero Prompts)
1. Launched `bin/geomind.exe -prompt "Hello"`:
   - Scanned webcam frame at startup.
   - 1:N scan across registered Domain 10 profiles computed cosine similarity:
     $$\cos(\theta) = 0.9967 \ge 0.85 \quad (\text{Threshold: } 0.85)$$
   - Output log:
     `[GeoMind Biometrics] Verified Interlocutor: User:Rick (sim=0.9967 >= 0.8500). Authenticated as Creator & Architect.`
   - Conditioned cognitive preamble:
     `You are GeoMind, a sovereign neuro-symbolic cognitive architecture created by Rick. The user speaking with you is Rick (Creator & Architect).`
   - Generated authentic dialogue without asking any onboarding questions!

### C. Conversational Trigger Verification
1. Tested conversational command: `"register my face as Rick"`:
   - Dynamically triggered webcam capture, projected 320-D eikonal embedding, updated `User:Rick` in Domain 10.
   - Verification via `/whoami` confirmed authenticated root session.

### D. Unit & Selective Regression Testing
1. `bin/test_face_mapping_and_user_domain.exe`:
   - Gate 1: Domain 10 Schema & User Partitioning -> PASS
   - Gate 2: Eikonal Face Normalization & CSV Serialization -> PASS
   - Gate 3: Cosine Similarity Metric Discrimination -> PASS (self=1.0000, perturbed=0.9984, orthogonal=0.0000)
   - Gate 4: Cognitive Preamble Conditioning -> PASS
2. `bin/test_startup_biometric_onboarding.exe`:
   - Gate 1: Known Face Automatic Authentication -> PASS ($sim = 0.9994 \ge 0.85$)
   - Gate 2: Unknown Interlocutor Guest Onboarding Preamble -> PASS
   - Gate 3: Conversational Face Enrollment & Name Mapping -> PASS
   - Gate 4: Subsequent Cold-Boot Recognition -> PASS
3. Selective Regression Suite (`tools/run_affected_tests.ps1 -Target "48, 50, 51, 52, 54, 55"`):
   - 6/6 affected targets passed cleanly (82.24s total).
