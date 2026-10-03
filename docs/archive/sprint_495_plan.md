# Sprint 495 Plan: GPU Acceleration, Conversational Camera Tool Trigger, Clean CLI Output & Preamble Identity Guardrails

**Sprint**: 495  
**Date**: 2026-09-30  
**Status**: In Progress  

---

## 1. Executive Summary

Sprint 495 addresses four critical operational, architectural, and conversational feedback points identified by Rick during live interactive execution:
1. **GPU Hardware Acceleration & Fast Manifold Inference (`[ISSUE-325]`)**:
   Incorporate GPU acceleration via CARTAN's native OpenCL engine (`src/std/gpu.cl`) and provide high-speed cached manifold inference so interactive chat generates instantly without 42-layer disk-read stalls.
2. **Conversational Camera Tool Awareness & Natural Intent Trigger (`[ISSUE-326]`)**:
   Add explicit tool capability declarations to the cognitive preamble and implement a conversational intent parser in `geomind_chat_learn_conversational_turn` that activates camera capture and profile enrollment when prompted in natural speech (*"take a pic and associate it with me"*).
3. **Debug Telemetry Gating Behind `--debug` / `/debug` (`[ISSUE-327]`)**:
   Gate all internal debug telemetry (`[Layer Pipeline RMS...]`, `Prompt token #...`, `<think>`, `[Hopfield Energy...]`) behind a global `g_chat_debug_mode` flag, keeping the default REPL output clean and silent.
4. **Preamble Identity Guardrails & Factual Isolation (`[ISSUE-328]`)**:
   Eliminate creator name leakage in unverified guest sessions. Purge `User.preferred_name` from Domain 1 world state and strictly instruct the model not to assume or address the interlocutor as Rick until biometrically authenticated.

---

## 2. Work Breakdown

### Task 1: Clean Terminal Output & Telemetry Print Gating (`test/geomind/chat.cl`, `test/geomind/main.car`)
- Define `var g_chat_debug_mode: float = 0.0;` in `test/geomind/chat.cl`.
- Add `geomind_chat_set_debug_mode(flag: float)` and `geomind_chat_get_debug_mode() -> float`.
- Wrap all internal telemetry `printf` calls behind `if (g_chat_debug_mode == 1.0)`.
- In `test/geomind/main.car`:
  - Parse CLI flags `-debug` and `--debug`.
  - Add interactive REPL command `/debug` to toggle telemetry output on/off dynamically.

### Task 2: Preamble Identity Guardrail & Domain 1 Disentanglement (`test/geomind/chat.cl`)
- Remove legacy `sqlite_vec_upsert_entity_state(g_chat_db, 1.0, "User", "preferred_name", "Rick", 1.0);` from `geomind_chat_get_db()`.
- Update `geomind_chat_build_cognitive_preamble(db)`:
  - When `g_active_user_verified == 0.0`:
    State clearly that the interlocutor is UNVERIFIED and UNKNOWN. Forbid assuming or calling them Rick.
  - When `g_active_user_id == "User:Rick"` AND `g_active_user_verified == 1.0`:
    Reinforce that the interlocutor is Rick (Verified Creator & Architect).

### Task 3: Conversational Tool Awareness & Natural Language Intent Trigger (`test/geomind/chat.cl`)
- In `geomind_chat_build_cognitive_preamble(db)`:
  Add tool capability notice informing GeoMind that it possesses a live hardware camera and 320-D eikonal facial mapper.
- In `geomind_chat_learn_conversational_turn(speaker, prompt)`:
  Implement intent recognition for camera requests (*"take a pic"*, *"take a photo"*, *"take a picture"*, *"snap a photo"*, *"capture my face"*, *"associate it with me"*, *"save my face"*, *"register my face"*).
  When triggered:
  - Invoke `geomind_chat_capture_face_frame()`.
  - Save 320-D embedding to active user in Domain 10.
  - Set confirmation state and return notification string so the model acknowledges the capture authentically.

### Task 4: GPU Acceleration & Fast Manifold Inference (`src/std/gpu.cl`, `test/geomind/chat.cl`, `test/geomind/main.car`)
- Initialize OpenCL hardware acceleration on startup when available via `cartan_gpu_init()`.
- Provide an optimized decode path that leverages the cached E8 manifold trajectory and GPU-accelerated projection rather than un-cached 42-layer disk-streaming per token.
- Support CLI flag `--gpu` / `--webgpu` to enable GPU-accelerated execution.

### Task 5: Empirical Verification & Regression Testing
- Author dedicated verification suite `test/geomind/test_gpu_and_conversational_tools.car`.
- Execute full 88-target compiler regression suite (`tools/run_affected_tests.ps1 -All`).
- Update `ISSUES.md`, `CHANGELOG.md`, `docs/ROADMAP.md`, and walkthrough.
