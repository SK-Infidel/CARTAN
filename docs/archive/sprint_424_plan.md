# Sprint 424 Implementation Plan: NSES Interactive Chat Integration & Live Hebbian Feedback Adaptation

## 1. Objectives
1. **Clock ABI Resolution (`[ISSUE-159]`)**: Formally verify and document the MSVCRT `clock()` 32-bit register return ABI in CARTAN LLVM codegen, ensuring sub-millisecond benchmark and turn latency reporting.
2. **Interactive Chat NSES Memory Integration (`test/geomind/chat.cl`)**: Transition chat from ephemeral turn reloading to a persistent resident `NSES_Pipeline` instance, and inject authentic assembled prompt scaffolds into the token embedding pass.
3. **Live Hebbian Feedback Adaptation in Production**: Connect human reward (`+1.0` / `-1.0`) and corrections in `geomind_chat_apply_human_feedback` and `geomind_chat_apply_correction` to live synaptic edge weight reinforcement and decay on the resident CSR graph.
4. **Empirical Regression Verification**: Create and pass `test/geomind/nses/test_sprint11_chat_nses_hebbian.car` across all functional gates, followed by clean native recompilation of `geomind.exe`.

---

## 2. Technical Architecture

### A. Resident NSES Pipeline State in `chat.cl`
- Global resident state:
  ```cartan
  var g_chat_nses_pipe: NSES_Pipeline;
  var g_chat_nses_init: float = 0.0;
  var g_last_chat_domain: float = 1.0;
  var g_last_chat_traversed: float = 0.0;
  ```
- `geomind_chat_get_nses_pipeline() -> NSES_Pipeline`: Initializes once from `test/geomind/trainingdata/nses_knowledge.car_graph` and maintains state in RAM across all conversation turns.
- In `geomind_chat_start()`, eagerly mount the resident pipeline and display active node/edge telemetry.

### B. Authentic Prompt Scaffold Injection
- In `geomind_chat_generate_reply_multimodal`:
  - Run `nses_pipeline_execute_turn` against resident pipeline.
  - If `cartan_string_length(nses_turn.assembled_prompt) > 0.0`, encode the structured 4-block scaffold into `prompt_tokens` so that the neural model and Hopfield resonator are directly conditioned on the inviolable system bounds, retrieved domain facts, and lateral associations.
  - Scan generated candidate text against `nses_pipe.veto_reg` with `veto_gate_scan`.

### C. Live Hebbian Feedback Adaptation
- In `geomind_chat_apply_human_feedback(prompt, reply, reward)`:
  - If `reward > 0.0`: Call `hebbian_reinforce_edge` on the active domain's traversed edges (incrementing weight by `+0.10`, clamped at `5.0`).
  - If `reward < 0.0`: Call `hebbian_decay_edge` on contradictory edges (decaying weight by `-0.10`, floored at `1.0`).
- In `geomind_chat_apply_correction(prompt, correct_reply)`:
  - Execute SFT natural gradient update and reinforce the corrected domain pathways in resident graph memory.

---

## 3. Definition of Done
- [ ] `[ISSUE-159]` marked as `[FIXED]` in `ISSUES.md`.
- [ ] `test/geomind/chat.cl` updated with resident NSES pipeline, scaffold injection, and Hebbian graph adaptation.
- [ ] `test/geomind/nses/test_sprint11_chat_nses_hebbian.car` passing 100% of gates.
- [ ] `geomind.exe` compiled cleanly with Zig `-O3 LTO Vectorized Pass Pipeline`.
- [ ] `geomind.exe --verify` and `geomind.exe --sleep` verified.
- [ ] `CHANGELOG.md` updated with version `[8.382.0]`.
- [ ] Sprint artifacts archived to `docs/archive/`.
