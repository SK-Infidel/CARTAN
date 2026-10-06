# Sprint 534 Implementation Plan: ANSI Terminal Text Coloring & Dynamic ASCII Animations

## Sprint Goal
Equip GeoMind with an ANSI terminal styling system and in-place dynamic ASCII animations for cognitive thinking passes and buffered token generation, elevating visual hierarchy and terminal ergonomics while strictly adhering to the Zero-Mock Rule and self-hosting fixpoint parity.

---

## User Stories
1. **As Rick (User & Architect)**, I want distinct color styling across the interface (prompts, assistant replies, thoughts, tool executions, errors, and telemetry) so that I can immediately delineate internal model processes from conversation.
2. **As Rick**, I want dynamic ASCII animations (rotating spinners and live token counts) during thinking and buffered generation so that I have clear real-time feedback on model activity without screen jitter or token leak.
3. **As a System Engineer**, I want colors and animations to be dynamically toggleable (`/color`, `/anim`) so that headless logging and pipe redirection remain clean.

---

## Technical Specifications & Architecture

### 1. Compiler `\e` Escape String Literal Lowering (`src/cartanc/core_runtime.car`)
- In `cartan_llvm_format_string_literal`:
  - When `b == 92.0` (`\`) and `next == 101.0` (`e`): set `b = 27.0` and increment index `i = i + 1.0`.
  - Enables `"\e[..."` string literals across all CARTAN codebases, lowering to `\1B` in LLVM IR global string constants.
  - Rebuild `cartanc.exe` and `bin/cartanc.exe` to self-host.

### 2. UI State Variables & ANSI Palette Engine (`test/geomind/chat.cl`)
- State variables:
  - `var g_chat_use_color: float = 1.0;` (enabled by default)
  - `var g_chat_use_animation: float = 1.0;` (enabled by default)
  - `var g_chat_anim_frame: float = 0.0;` (global frame counter)
- Getters and setters:
  - `geomind_chat_get_use_color() -> float;`
  - `geomind_chat_set_use_color(val: float) -> float;`
  - `geomind_chat_get_use_animation() -> float;`
  - `geomind_chat_set_use_animation(val: float) -> float;`
- Palette functions (return ANSI code if `g_chat_use_color == 1.0`, otherwise `""`):
  - `geomind_col_reset()` -> `\e[0m`
  - `geomind_col_bold()` -> `\e[1m`
  - `geomind_col_dim()` -> `\e[2m`
  - `geomind_col_green()` -> `\e[1;32m` (assistant response label & success)
  - `geomind_col_cyan()` -> `\e[1;36m` (user prompt & factual metrics)
  - `geomind_col_yellow()` -> `\e[1;33m` (tool execution banner)
  - `geomind_col_amber()` -> `\e[33m` (cognitive thought process box)
  - `geomind_col_red()` -> `\e[1;31m` (interruption & errors)
  - `geomind_col_gray()` -> `\e[90m` (telemetry & fine borders)
  - `geomind_col_erase_line()` -> `\e[2K\r`

### 3. Dynamic In-Place ASCII Thinking Spinner (`test/geomind/chat.cl`)
- In `geomind_chat_generate_reasoning_pass(prompt, temp)`:
  - When starting cognitive math:
    - If `g_chat_use_animation == 1.0`:
      Emit initial in-place frame: `\r%s[🧠 ⠋ Thinking...]%s Analyzing prompt semantics and cognitive topology...`
      Flush stdout.
  - As each cognitive stage finishes (energy calculation, concept taxonomy LCA search, Sasaki brainstem routing):
    - Update spinner symbol (`⠋, ⠙, ⠹, ⠸, ⠼, ⠴, ⠦, ⠧, ⠇, ⠏` with `| / - \` fallback).
  - Upon completion:
    - Clear spinner line with `\e[2K\r` + trailing padding.
    - If `g_chat_show_thinking == 1.0`: Render full Thought Process box with amber borders.
    - If `g_chat_show_thinking == 0.0`: Render concise `\r[🧠 Thinking complete]\n` in green/cyan.

### 4. Dynamic In-Place Buffered Generation Counter & Spinner (`test/geomind/chat.cl`)
- In `geomind_chat_generate_reply_multimodal`:
  - When `g_chat_buffered_output == 1.0`:
    - In decode loop `while (step < max_t)`:
      On each token step (or every 2 steps if fast):
      Compute live `tok_per_sec = (step * 1000.0) / elapsed_ms`.
      Select spinner symbol for current frame.
      Emit in-place line with `\r`:
      `\r%s[✨ %s Generating response... (%.0f tokens, %.1f tok/s) (press '/' to interrupt)]%s`
      Flush stdout.
  - Upon finish or interruption:
    - Erase spinner line with `\e[2K\r` + padding.
    - Emit colored assistant response:
      `\n%sGeoMind>%s %s\n` (green label, clean text).

### 5. Interactive REPL Slash Commands & Styling (`test/geomind/main.car`)
- Add REPL commands:
  - `/color` or `c`: Toggle `g_chat_use_color`.
  - `/anim` or `a`: Toggle `g_chat_use_animation`.
- Format interactive user prompt:
  - `User:Rick>` in Bold Cyan (`\e[1;36mUser:Rick>\e[0m `).
  - `Command>` in Bold Yellow (`\e[1;33mCommand>\e[0m /`).
- Update `/help` dialog.

### 6. Empirical Verification & Regression Testing
- Create `test/geomind/test_interface_coloring_and_animation.car` covering:
  - Gate 1: Compiler `\e` lowering & dynamic escape synthesis.
  - Gate 2: Color toggle state changes & palette collapse to empty strings when disabled.
  - Gate 3: In-place thinking animation & zero-mock mathematical pass.
  - Gate 4: Buffered decode spinner with line erasure & clean output.
  - Gate 5: REPL command parsing & live interruption compatibility.
- Add preset `534` to `tools/run_affected_tests.ps1` and run 16/16 compiler regression tests.
