# Startup Code Review: Sprint 533 — Terminal Interface Improvements, Async Key Interruption & Structured Output Buffering

## 1. Executive Summary & Codebase State
- **Sprint**: 533
- **Focus**: Terminal Interface & Output Formatting Engine for GeoMind:
  1. Asynchronous keyboard interruption: Hitting the `/` key during generation immediately halts token decoding and transitions into command mode.
  2. Output separation & visual indicators: Distinct, structured indicators for thinking (`[🧠 Thinking...]`), tool execution (`[⚙️ Tool Call...]`), and token generation (`[✨ Generating response...]`).
  3. Clean response buffering: Defaulting to buffered output mode where generated assistant text is emitted cleanly once generation completes, eliminating interleaved token flicker and raw unparsed tags.
  4. Interactive toggles & keyboard shortcuts: Commands and single-key shortcuts to toggle thinking display (`/think`, `t`), performance telemetry (`/telemetry`, `m`), and output mode (`/stream`, `s`).
- **Compiler State**: `cartanc.exe` fixpoint operational. Regression suite passing 16/16 affected targets (Sprint 532).
- **Zero-Mock Adherence**: Real Win32 CRT console polling via `_kbhit()` and `_getch()`, authentic Hopfield/Sasaki mathematical passes during thinking, genuine token buffering in `PromptScaffoldBuffer`.

---

## 2. In-Depth Component Review & Findings

### A. Token Generation & Output Stream (`test/geomind/chat.cl`)
- **Current Behavior**:
  - `geomind_print_token_fluid(tok_0)` is invoked unconditionally inside both the speculative verification loop (lines 4406, 4427) and the standard decode path (line 4469).
  - Tool calls intercepting mid-generation emit `\n  [GeoMind Tool Calling] Executing: ...` and raw `<tool_response>` XML blocks (line 4517) directly to stdout, disrupting conversational formatting.
  - At the end of generation, Hopfield energy minimums and telemetry lines are printed directly to stdout, cluttering conversational replies.
- **Identified Deficiencies**:
  - No mechanism to suppress raw live token streaming in favor of clean end-of-turn display.
  - No visual cues indicating model state transitions (e.g. prefill, reasoning, tool execution, generation).
  - Tool execution dumps raw internal protocol tags directly into the user-facing terminal.

### B. Reasoning Pass Output Formatting (`test/geomind/chat.cl` lines 4802–4879)
- **Current Behavior**:
  - `geomind_chat_generate_reasoning_pass(prompt, temp)` unconditionally outputs raw `<think>` blocks with 14 lines of internal diagnostic telemetry whenever `g_chat_debug_mode != 0.0`.
  - When `g_chat_debug_mode == 0.0`, it returns silently, giving the user no indication that prompt analysis, taxonomy extraction, or Lie stream routing is taking place.
- **Identified Deficiencies**:
  - Lack of a dedicated `g_chat_show_thinking` configuration allowing users to independently inspect or hide the thought process without toggling full developer debug telemetry.
  - Raw `<think>` tag dump lacks clean visual containment (borders, headers).

### C. Console Polling & Key Interruption (`src/cartanc/core_runtime.car`, Windows C Runtime)
- **Current Behavior**:
  - The generation loop `while (step < max_t)` runs synchronously without checking console input buffers until completion or EOS.
  - If a prompt produces a long generation, the user cannot halt the output without killing the process (`Ctrl+C`).
- **Identified Solution**:
  - C runtime provides `_kbhit()` and `_getch()` in MSVCRT/UCRT.
  - Proved in `scratch/test_kbhit.car` that `extern fn _kbhit() -> float;` and `extern fn _getch() -> float;` compile, link, and execute natively with zero overhead.
  - Integrating `_kbhit()` into each decode step enables instant detection of `/` (ASCII 47) to abort generation and switch to command mode.

### D. REPL Command Loop (`test/geomind/main.car` lines 600–760)
- **Current Behavior**:
  - Interactive REPL processes slash commands only after line input (`cartan_read_line()`).
  - No single-key toggle shortcuts or commands for `/think`, `/telemetry`, or `/stream`.
- **Identified Solution**:
  - Add `/think` (shortcut `t`), `/telemetry` (shortcut `m`), and `/stream` (shortcut `s`) handlers.
  - Add state flags and synchronization with `test/geomind/chat.cl`.

---

## 3. Logical Dependency Tree
```
[Windows CRT / ucrt.lib]
    │
    ├── _kbhit() & _getch() (Console Input Polling)
    │
[src/cartanc/core_runtime.car]
    │
    └── Expose _kbhit and _getch symbols to CARTAN AST
            │
            ▼
[test/geomind/chat.cl]
    │
    ├── UI State Flags: g_chat_show_thinking, g_chat_show_telemetry, g_chat_buffered_output, g_chat_interrupted
    ├── geomind_chat_generate_reasoning_pass(): Structured thought framing [💭 Thought Process]
    ├── geomind_chat_generate_reply_multimodal():
    │       ├── Asynchronous _kbhit() polling for '/' key (mid-stream abort)
    │       ├── Clean state banners ([🧠 Thinking...], [✨ Generating...], [⚙️ Tool: ...])
    │       ├── Output buffering in PromptScaffoldBuffer (clean emission on completion)
    │       └── Structured telemetry summary box [📊 Inference Telemetry]
    │
    ▼
[test/geomind/main.car]
    │
    ├── Interactive REPL Command Handlers: /think (t), /telemetry (m), /stream (s)
    ├── Post-interruption handler: seamless transition into '/' command mode
    └── /help update with interface toggles and keyboard shortcuts
    │
    ▼
[test/geomind/test_interface_formatting.car]
    │
    └── Dedicated Empirical Verification Suite (All UI toggles, formatting, and keypress logic)
    │
    ▼
[bin/geomind.exe]
    │
    └── Live interactive validation with genuine display
```

---

## 4. Issues Identified & Tracked
- **`[ISSUE-391]`**: Terminal Output Interleaving, Lack of Mid-Stream `/` Abort, and Missing Interface Display Toggles.
