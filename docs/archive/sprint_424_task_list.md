# Sprint 424 Task List

- [x] **Task 1: Resolve ISSUE-159 (Clock ABI)**
  - [x] Verify `llvm_codegen.car` clock ABI handling.
  - [x] Mark `[ISSUE-159]` as `[FIXED]` in `ISSUES.md`.

- [x] **Task 2: Persistent NSES Pipeline in Chat (`test/geomind/chat.cl`)**
  - [x] Add global resident `g_chat_nses_pipe`, `g_chat_nses_init`, `g_last_chat_domain`.
  - [x] Implement `geomind_chat_get_nses_pipeline()`.
  - [x] Eagerly mount in `geomind_chat_start()`.

- [x] **Task 3: Prompt Scaffold Injection & Generation Priming (`test/geomind/chat.cl`)**
  - [x] In `geomind_chat_generate_reply_multimodal`, use `nses_turn.assembled_prompt` to condition token encoding.
  - [x] Track `g_last_chat_domain` and `g_last_chat_traversed`.
  - [x] Preserve resident pipeline without freeing at end of turn.

- [x] **Task 4: Live Hebbian Graph Adaptation (`test/geomind/chat.cl`)**
  - [x] In `geomind_chat_apply_human_feedback`, reinforce edges on `reward > 0.0` and decay on `reward < 0.0`.
  - [x] In `geomind_chat_apply_correction`, update graph edge weights along with SFT step.

- [x] **Task 5: Test Suite & Verification**
  - [x] Create `test/geomind/nses/test_sprint11_chat_nses_hebbian.car` (5 verification gates).
  - [x] Run test suite with `cartanc.exe run`.
  - [x] Rebuild `geomind.exe` with `cartanc.exe build`.
  - [x] Verify `geomind.exe --verify` and `geomind.exe --sleep`.

- [x] **Task 6: Documentation & Retrospective**
  - [x] Update `CHANGELOG.md` with `[8.382.0]`.
  - [x] Save walkthrough, plan, and task list to `docs/archive/`.
