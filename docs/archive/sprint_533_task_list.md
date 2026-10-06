# Sprint 533 Task List: Terminal Interface Improvements, Async Key Interruption & Structured Output Buffering

- [x] **1. Runtime CRT Bindings & UI State Variables (`test/geomind/chat.cl`)**
  - [x] Declare `extern fn _kbhit() -> float;` and `extern fn _getch() -> float;`.
  - [x] Add state variables: `g_chat_show_thinking`, `g_chat_show_telemetry`, `g_chat_buffered_output`, `g_chat_interrupted`.
  - [x] Add getter and setter functions for each state variable.

- [x] **2. Structured Reasoning Pass Framing (`test/geomind/chat.cl`)**
  - [x] Refactor `geomind_chat_generate_reasoning_pass(prompt, temp)` to execute genuine calculations unconditionally.
  - [x] If `g_chat_show_thinking == 1.0`, render formatted `┌─ [💭 Thought Process] ──┐` box.
  - [x] If `g_chat_show_thinking == 0.0`, suppress verbose output and show brief indicator or remain silent.

- [x] **3. Asynchronous Key Interruption & Clean Output Buffering (`test/geomind/chat.cl`)**
  - [x] In `geomind_chat_generate_reply_multimodal`, check `_kbhit()` on every step for `/` (ASCII 47).
  - [x] If `/` is detected, halt generation immediately, set `g_chat_interrupted = 1.0`, and emit interruption status.
  - [x] If `g_chat_buffered_output == 1.0`, display `[✨ Generating response... (press '/' to interrupt)]`, suppress token-by-token character streaming, and output clean `GeoMind> <text>` block upon finish.
  - [x] Format tool call execution cleanly: `[⚙️ Executing Tool: ...]` and suppress raw `<tool_response>` blocks from conversational output.
  - [x] If `g_chat_show_telemetry == 1.0`, render structured `┌─ [📊 Inference Telemetry] ──┐` summary.

- [x] **4. Interactive REPL Commands & Shortcuts (`test/geomind/main.car`)**
  - [x] Add `/think` and single-key `t` command handlers.
  - [x] Add `/telemetry` and single-key `m` command handlers.
  - [x] Add `/stream` and single-key `s` command handlers.
  - [x] Handle post-interruption state: if `g_chat_interrupted == 1.0`, transition into `/` command mode.
  - [x] Update `/help` dialog.

- [x] **5. Empirical Verification & Regression Testing**
  - [x] Create and run `test/geomind/test_interface_formatting.car`.
  - [x] Rebuild native `bin/geomind.exe` with `cartanc.exe`.
  - [x] Test live prompt interaction with `/` interruption, thinking toggle, and buffered response.
  - [x] Add preset `533` to `tools/run_affected_tests.ps1` and run regression suite (16/16 PASS).

- [x] **6. Documentation & Sprint Closure**
  - [x] Record and close `[ISSUE-391]` in `ISSUES.md`.
  - [x] Update `CHANGELOG.md` to `[8.489.0]`.
  - [x] Update Phase 25 (Item 15) in `docs/ROADMAP.md`.
  - [x] Check off all tasks in `docs/archive/sprint_533_task_list.md`.
  - [x] Save walkthrough to `docs/archive/sprint_533_walkthrough.md`.

