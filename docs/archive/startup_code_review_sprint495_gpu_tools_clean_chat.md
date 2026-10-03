# Startup Code Review: Sprint 495 — GPU Hardware Acceleration, Conversational Camera Tool Trigger, Clean CLI Output & Preamble Identity Isolation

**Date**: 2026-09-30  
**Author**: Antigravity & Rick  
**Sprint**: 495  

---

## 1. Executive Summary & Diagnostic Findings

During live REPL dialogue with GeoMind, four key architectural and user-experience deficiencies were identified:
1. **CPU-Only 42-Layer Sequential Streaming (`[ISSUE-325]`)**:
   `geomind_execute_gemma_decode_step()` in `test/geomind/chat.cl` streams all 42 Gemma layers (15.6 GB) through CPU RAM for every generated token using AVX2 SIMD `cartan_gemma_layer_forward_raw`. The physical NVIDIA RTX 2000 Ada Laptop GPU (8 GB VRAM) sits at 0% utilization while token generation takes tens of seconds.
2. **Missing Conversational Tool Awareness & Natural Language Intent Trigger (`[ISSUE-326]`)**:
   While camera capture was implemented via slash commands (`/register-face`), the LLM preamble contained zero declaration of tool capabilities. When the user prompted in natural conversation *"take a pic and associate it with me"*, GeoMind answered that it lacked a camera.
3. **Verbose Terminal Telemetry Spam (`[ISSUE-327]`)**:
   Every chat turn unconditionally spams internal diagnostic lines: `[Layer Pipeline Input RMS=...]`, `Prompt token #X: ...`, `<think> ... </think>`, `[Hopfield Energy Minimum: ...]`, and `[Hybrid Ensemble Discriminator...]`. There is no CLI flag to silence them.
4. **Preamble Identity Leakage & Premature Name Ingestion (`[ISSUE-328]`)**:
   `geomind_chat_build_cognitive_preamble()` injected `"Your creator and architect is Rick"` even for unverified speakers, and Domain 1 seeded `User.preferred_name = 'Rick'`. This caused `geomind_chat_retrieve_factual_attractor()` to inject "Rick" into latent prompts before biometric identification took place, confusing the model into addressing unknown guests as Rick.

---

## 2. Logical Dependency Tree

```
┌────────────────────────────────────────────────────────┐
│                   test/geomind/main.car                │
│    (CLI Flag Parsing: --debug, /debug REPL command)    │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│                  test/geomind/chat.cl                  │
│  - g_chat_debug_mode: Telemetry Print Gating           │
│  - geomind_chat_build_cognitive_preamble:              │
│    * Tool Capability Declaration (Camera / Biometrics) │
│    * Strict Guest Preamble (Do NOT assume Rick)        │
│  - geomind_chat_learn_conversational_turn:             │
│    * Conversational Intent Matcher ("take a pic...")   │
│    * Immediate Face Snapshot & Domain 10 Enrollment    │
│  - Gemma Decode Optimization / Fast Latent Execution   │
└─────────────┬────────────────────────────┬─────────────┘
              │                            │
              ▼                            ▼
┌───────────────────────────┐ ┌──────────────────────────┐
│   src/std/sqlite_vec.cl   │ │     src/std/gpu.cl       │
│ - Purge User in Domain 1  │ │ - OpenCL GPU VRAM Buffer │
│ - Preserve User:Rick in   │ │   Allocations & Compute  │
│   Domain 10 exclusively   │ │   Shader Acceleration    │
└───────────────────────────┘ └──────────────────────────┘
```

---

## 3. Detailed Component Review

### A. `test/geomind/chat.cl`
- **Telemetry Gating**: Wrap all internal logs (`printf("[Layer Pipeline...", ...)`, `<think>`, `Prompt token #...`, `[Hopfield Energy...]`) inside `if (g_chat_debug_mode == 1.0)`.
- **Tool Awareness in Preamble**:
  Add explicit capability text when camera is available:
  `"Capabilities: You possess direct access to a hardware camera and 320-D eikonal facial mapping. When the user asks you to take a photo, capture their face, or remember their face, you can execute your camera tool."`
- **Conversational Camera Intent Trigger**:
  In `geomind_chat_learn_conversational_turn`:
  Detect patterns like `"take a picture"`, `"take a pic"`, `"take a photo"`, `"snap a photo"`, `"capture my face"`, `"associate it with me"`, `"register my face"`.
  When triggered:
  - Call `geomind_chat_capture_face_frame()`.
  - Save to active user profile in Domain 10.
  - Return confirmation status and feed execution event into conversational context.
- **Preamble Identity Guardrail**:
  When `g_active_user_verified == 0.0`:
  `"You are currently speaking with an UNVERIFIED GUEST whose identity is UNKNOWN. Do NOT call them Rick or assume they are your creator. Address them neutrally as a guest until their identity is verified."`

### B. `src/std/sqlite_vec.cl`
- In `sqlite_vec_init_domain10`: keep `User:Rick` and `User:Guest` cleanly partitioned in Domain 10.
- In `geomind_chat_get_db()`: remove the legacy `sqlite_vec_upsert_entity_state(g_chat_db, 1.0, "User", "preferred_name", "Rick", 1.0);` that poisoned generic domain queries.

### C. `test/geomind/main.car`
- Parse `-debug` and `--debug` CLI flags into `g_chat_debug_mode`.
- Add interactive REPL command `/debug` to toggle debug telemetry on and off.

### D. GPU VRAM & Inference Acceleration
- The full 42 layers in fp32 (15.6 GB) exceed the 8 GB VRAM. However:
  1. The LM head softcapping and projection vectors can be accelerated on GPU or cached in high-speed aligned memory.
  2. For interactive chat, add a `--fast-inference` mode or optimize the decode loop to bypass redundant full-layer disk sweeps when latent state is stabilized on the manifold.
  3. Ensure GPU buffers are mounted via `cartan_gpu_init()` during boot when GPU acceleration is requested.

---

## 4. Issues Logged
- `[ISSUE-325]`: CPU-Only 42-Layer Sequential GEMV Bottleneck & Absence of GPU Hardware Acceleration in Chat Inference
- `[ISSUE-326]`: Lack of Conversational Camera Tool Awareness & Natural Language Biometric Registration Intent Parsing
- `[ISSUE-327]`: Unconditional Diagnostic Telemetry Spam in Terminal Chat Loop (Need Gated `--debug` Flag)
- `[ISSUE-328]`: Creator Identity Leakage and Premature Name Ingestion in Unverified Cognitive Preambles
