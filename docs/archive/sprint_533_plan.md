# Sprint 533 Plan: Terminal Interface Improvements, Async Key Interruption & Structured Output Buffering

## 1. Objectives & Deliverables
1. **Asynchronous Key Interruption (`/` Abort)**:
   - Poll `_kbhit()` inside the autoregressive decode loop (`step < max_t`).
   - If `/` (ASCII 47) is detected, abort generation immediately, set `g_chat_interrupted = 1.0`, emit `[Generation Interrupted: Switched to Command Mode]`, and transition the REPL directly into `/` command entry.
2. **Output Separation & State Indicators**:
   - Indicator for Reasoning/Thinking: `[🧠 Thinking...]`.
   - Indicator for Generation: `[✨ Generating response... (press '/' to interrupt)]`.
   - Indicator for Tool Execution: Clean `[⚙️ Executing Tool: name(args)...]` and `[⚙️ Tool Completed: status]`, suppressing raw protocol tags from user view.
3. **Structured Response Buffering (Clean End-of-Turn Emission)**:
   - Introduce `g_chat_buffered_output` (default `1.0`).
   - In buffered mode, suppress token-by-token character streaming to stdout; accumulate tokens in `PromptScaffoldBuffer`; emit the clean, complete assistant response all at once upon completion:
     `GeoMind> <response text>`
   - Provide toggle to switch back to streaming mode if desired (`/stream` or `s`).
4. **Interactive Toggles & Keyboard Shortcuts**:
   - `/think` or shortcut `t`: Toggle thinking display (`g_chat_show_thinking`, default `0.0`). When enabled, renders a clean visual block: `┌─ [💭 Thought Process] ──┐`.
   - `/telemetry` or shortcut `m`: Toggle performance metrics (`g_chat_show_telemetry`, default `0.0`). When enabled, renders a clean summary: `┌─ [📊 Inference Telemetry] ──┐`.
   - `/stream` or shortcut `s`: Toggle between `BUFFERED` (clean text upon completion) and `STREAMING` (live token flow).
   - Update `/help` documentation.
5. **Empirical Verification**:
   - Build dedicated verification suite `test/geomind/test_interface_formatting.car`.
   - Rebuild `bin/geomind.exe` and test live prompt interaction.
   - Run selective compiler regression test suite (`tools/run_affected_tests.ps1 -Sprint 533`).

---

## 2. Squad Work Breakdown

### A. Compiler & Runtime Squad (`cartan_runtime_engineer`, `cartan_compiler_engineer`)
- Expose `_kbhit()` and `_getch()` from CRT.
- Ensure non-blocking polling introduces zero latency jitter into the INT4 / GPU decode step.

### B. Architecture & Perception Squad (`cartan_architect`)
- Design clean visual formatting frames for thinking, tools, and telemetry.
- Ensure strict zero-mock compliance: all mathematical passes (Hopfield energy, concept taxonomy, Sasaki routing) execute regardless of whether thinking display is visible or hidden.

### C. QA & Benchmark Squad (`cartan-qa-tester`)
- Build `test/geomind/test_interface_formatting.car` validating:
  - Toggle states and getter/setter functions.
  - Thinking display suppression vs formatting.
  - Buffered output formatting vs streaming.
  - Clean tool call execution indicators.
  - Non-blocking `_kbhit()` integration.
- Run compiler regression suite (`tools/run_affected_tests.ps1 -Sprint 533`).

---

## 3. DoD (Definition of Done)
- [ ] Code passes static type checking and LLVM IR codegen via `cartanc.exe`.
- [ ] Zero runtime regressions on target benchmarks (16/16 PASS).
- [ ] All new functions include brief, clear comments explaining intent.
- [ ] Empirical proof of mid-stream `/` interruption and clean buffered output.
- [ ] `docs/archive/sprint_533_plan.md`, `task_list.md`, and `walkthrough.md` archived.
- [ ] `CHANGELOG.md` updated to `[8.489.0]`.
- [ ] `ISSUES.md` updated with `[ISSUE-391]`.
