# Sprint 495 Task List: GPU Acceleration, Conversational Camera Tool Trigger, Clean CLI Output & Preamble Identity Guardrails

- [ ] **Task 1: Clean Terminal Output & Telemetry Print Gating (`test/geomind/chat.cl`, `test/geomind/main.car`)**
  - [ ] Add `g_chat_debug_mode` global flag and getters/setters in `test/geomind/chat.cl`.
  - [ ] Gate internal telemetry `printf` calls (`[Layer Pipeline Input...]`, `Prompt token #...`, `<think>`, `[Hopfield Energy...]`, `[Hybrid Ensemble...]`) behind `if (g_chat_debug_mode == 1.0)`.
  - [ ] Parse `-debug` and `--debug` in `test/geomind/main.car`.
  - [ ] Add `/debug` command in REPL to toggle telemetry.

- [ ] **Task 2: Preamble Identity Guardrail & Domain 1 Disentanglement (`test/geomind/chat.cl`)**
  - [ ] Remove `sqlite_vec_upsert_entity_state(g_chat_db, 1.0, "User", "preferred_name", "Rick", 1.0);` from `geomind_chat_get_db()`.
  - [ ] Condition preamble when `g_active_user_verified == 0.0` to forbid calling the speaker Rick.
  - [ ] Ensure only authenticated `User:Rick` sessions state that the interlocutor is Rick.

- [ ] **Task 3: Conversational Tool Awareness & Natural Language Intent Trigger (`test/geomind/chat.cl`)**
  - [ ] Declare camera and face-mapping tool capabilities in `geomind_chat_build_cognitive_preamble()`.
  - [ ] Implement natural intent parsing in `geomind_chat_learn_conversational_turn` for camera capture/face association requests.
  - [ ] Execute camera capture, save 320-D embedding to Domain 10, elevate session, and supply conversational feedback.

- [ ] **Task 4: GPU Acceleration & Fast Manifold Inference (`src/std/gpu.cl`, `test/geomind/chat.cl`, `test/geomind/main.car`)**
  - [ ] Wire `cartan_gpu_init()` during boot when GPU acceleration is requested.
  - [ ] Provide accelerated manifold inference path avoiding redundant 42-layer disk sweeps.
  - [ ] Support `--gpu` / `--webgpu` CLI options in `main.car`.

- [ ] **Task 5: Empirical Verification & Regression Testing**
  - [ ] Author `test/geomind/test_gpu_and_conversational_tools.car` testing all 4 gates.
  - [ ] Execute `tools/run_affected_tests.ps1 -All` verifying 88/88 targets.
  - [ ] Update `ISSUES.md` (`[ISSUE-325]`, `[ISSUE-326]`, `[ISSUE-327]`, `[ISSUE-328]`).
  - [ ] Update `CHANGELOG.md` (`[8.453.0]`) and `docs/ROADMAP.md`.
  - [ ] Save walkthrough to `docs/archive/sprint_495_walkthrough.md`.
