# Sprint 533 Walkthrough: Terminal Interface Improvements, Async Key Interruption & Structured Output Buffering

## 1. Overview
In Sprint 533, we addressed key UI usability, readability, and interactivity issues in GeoMind's interactive console session:
1. **Asynchronous Key Interruption**: Pressing the `/` key (ASCII 47) during active token generation immediately halts decoding, safely bypasses remaining layers, suppresses episodic memory/attractor corruption from partial fragments, and transitions the REPL directly into command mode (`Command> /`).
2. **Visual Framing & Output Sanitization**: Cognitive thinking passes, agentic tool execution notifications, and final assistant replies are visually distinct and clean. Internal XML protocol tags (`<think>`, `<tool_call:...>`, `<tool_response>`) are sanitized from user-facing output.
3. **Structured Output Buffering**: Generation defaults to buffered mode (`g_chat_buffered_output == 1.0`), suppressing token-by-token character jitter and streaming leaks, emitting clean `GeoMind> <response>` blocks upon completion.
4. **Interactive Toggles & Shortcuts**: Added REPL commands `/think` (`t`), `/telemetry` (`m`), `/stream` (`s`), and updated the `/help` dialog.

All operations strictly comply with the **Zero-Mock Rule**—all mathematical operations (Sasaki brainstem routing, continuous Hopfield relaxation, concept taxonomy) execute unconditionally even when visual display is toggled off.

---

## 2. Architecture & Technical Implementation

### A. Compiler Lowering for CRT `_kbhit` & `_getch` (`src/cartanc/llvm_codegen.car` & `src/cartanc/core_runtime.car`)
- **ABI Hazard Resolution**: In Windows UCRT / MSVCRT, `_kbhit()` and `_getch()` return 32-bit signed integers in register `EAX`. Direct float lowering expected returns in `XMM0`, clobbering returns with residual GEMM floating-point register states and causing false-positive aborts.
- **Canonical `i32` ABI Lowering**:
  - Registered in `src/cartanc/llvm_codegen.car` (builtin externs line 506, Pass 1 extern line 835).
  - Implemented call-site lowering in `cartan_lower_call_with_conv` (line 3466) emitting `call i32 @<func>()` followed by `sitofp i32 %res to double`, ensuring accurate 0.0 vs 1.0 return semantics.
  - Declared `extern fn _kbhit() -> float;` and `extern fn _getch() -> float;` in `src/cartanc/core_runtime.car`.

### B. Single Byte Buffer Append Primitives (`src/std/prompt_scaffold.cl`)
- Implemented `prompt_scaffold_append_char(buf: prompt_scaffold_t, ch: float)` to permit character-by-character string buffering without allocation overhead during output sanitization.

### C. Output Sanitization & Protocol Tag Stripping (`test/geomind/chat.cl`)
- Implemented `geomind_string_starts_with_offset(s, s_len, offset, prefix, prefix_len)` for zero-allocation substring prefix matching.
- Implemented `geomind_sanitize_output_for_display(raw: string) -> string`, which strips internal `<think>`, `</think>`, `<tool_call:...>`, `<tool_response>`, and `<|turn>` blocks from raw token streams while preserving conversational text.

### D. Zero-Mock Structured Reasoning Framing (`test/geomind/chat.cl`)
- Refactored `geomind_chat_generate_reasoning_pass(prompt, temp)`:
  - Executes genuine cognitive mathematics (Hopfield energy, concept classification, Sasaki metric routing) unconditionally.
  - When `g_chat_show_thinking == 1.0`: renders structured UTF-8 framing box (`┌── [💭 Thought Process] ──┐`, domain, routing weights, energy delta).
  - When `g_chat_show_thinking == 0.0`: renders a concise `[🧠 Thinking complete]` indicator.

### E. Stream Jitter Suppression & Interruption (`test/geomind/chat.cl`)
- Gated `geomind_print_token_fluid` and `geomind_poll_char_stream` with `if (g_chat_buffered_output == 1.0) { return; }`, eradicating intermediate sub-token character leakage across layers 0..41.
- Integrated `_kbhit()` check in `geomind_chat_generate_reply_multimodal`:
  - Drains extended keys (`ch == 0.0 || ch == 224.0`).
  - Halts immediately when `/` is pressed, sets `g_chat_interrupted = 1.0`, and outputs `\n[Generation Interrupted: Switched to Command Mode]\n`.
  - Bypasses Hopfield basin writes, episodic SQLite storage, and Online Critic updates when interrupted to prevent state corruption.

### F. REPL Slash Commands & Shortcuts (`test/geomind/main.car`)
- Added `/think` (shortcut `t`) to toggle thinking output.
- Added `/telemetry` (shortcut `m`) to toggle metrics/telemetry.
- Added `/stream` (shortcut `s`) to toggle between buffered and streaming output.
- Implemented post-interruption handler in the REPL loop transitioning interrupted sessions directly into `/` command mode.

---

## 3. Empirical Verification Results

### 1. Dedicated Verification Suite (`test/geomind/test_interface_formatting.car`)
Compiled and executed natively via `./cartanc.exe`:
```
=== TEST GATE 1: UI Toggle State Variables ===
[PASS] Default values verified.
[PASS] Mutator state changes verified.

=== TEST GATE 2: Output Sanitization Engine ===
[PASS] Internal protocol tags stripped cleanly.
[PASS] Conversational text preserved.

=== TEST GATE 3: Unconditional Reasoning Pass ===
[PASS] Sasaki router activated: domain=0.00, weight=0.9995
[PASS] Genuine cognitive mathematics executed with zero-mock.

=== TEST GATE 4: Non-Blocking Keyboard Polling ABI ===
[PASS] _kbhit() returned valid non-crashing integer status (0.0000).
[PASS] Calling convention verified with zero register clobbering.

=== TEST GATE 5: High-Frequency Polling Latency Benchmark ===
[PASS] Completed 10,000 _kbhit() calls in 216 ms (0.0216 ms/call).
[PASS] Polling overhead represents < 0.06% of token decode step time.
```

### 2. Live REPL & Prompt Verification (`bin/geomind.exe`)
- Tested live prompt execution with clean buffered output:
```
[🧠 Thinking complete]
[✨ Generating response... (press '/' to interrupt)]

GeoMind> Paris is the capital and largest city of France.
```
- Verified interactive slash command session (`/think`, `/stream`, `/telemetry`, `/help`) via piped stdin.

### 3. Compiler Regression Test Suite
Executed Sprint 533 preset via `tools/run_affected_tests.ps1 -Sprint 533`:
- **16/16 Test Targets PASS** in 117.13 seconds with 100% pass rate.

---

## 4. Summary of Changes
- `src/cartanc/llvm_codegen.car`: Added canonical `i32` ABI lowering and `sitofp` conversion for `_kbhit` and `_getch`.
- `src/cartanc/core_runtime.car`: Added declarations for CRT `_kbhit` and `_getch`.
- `src/std/prompt_scaffold.cl`: Implemented `prompt_scaffold_append_char`.
- `test/geomind/chat.cl`: Added UI state variables, sanitization engine, buffered output suppression, non-blocking `/` key interruption, and memory poisoning guards.
- `test/geomind/main.car`: Added `/think`, `/telemetry`, `/stream` commands, command mode transition, and updated `/help`.
- `test/geomind/test_interface_formatting.car`: 5-gate empirical verification test suite.
- `tools/run_affected_tests.ps1`: Added Sprint 533 preset.
- `ISSUES.md`: Recorded and closed `[ISSUE-391]`.
- `CHANGELOG.md`: Updated to `[8.489.0]`.
- `docs/ROADMAP.md`: Updated Phase 25 (Item 15).
