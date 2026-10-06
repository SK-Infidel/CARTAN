# Sprint 534 Task List: ANSI Terminal Text Coloring & Dynamic ASCII Animations

- [x] **1. Compiler `\e` String Literal Lowering (`src/cartanc/core_runtime.car`)**
  - [x] Add `\e` (101.0 -> 27.0) to `cartan_llvm_format_string_literal`.
  - [x] Rebuild self-hosted compiler `cartanc.exe` and `bin/cartanc.exe`.
  - [x] Verify `\e` string literals lower into `\1B` global string constants in LLVM IR.

- [x] **2. UI State Variables & ANSI Palette Engine (`test/geomind/chat.cl`)**
  - [x] Declare `g_chat_use_color`, `g_chat_use_animation`, and `g_chat_anim_frame`.
  - [x] Implement getters/setters: `geomind_chat_get_use_color`, `geomind_chat_set_use_color`, `geomind_chat_get_use_animation`, `geomind_chat_set_use_animation`.
  - [x] Implement color helpers: `geomind_col_reset`, `geomind_col_bold`, `geomind_col_dim`, `geomind_col_green`, `geomind_col_cyan`, `geomind_col_yellow`, `geomind_col_amber`, `geomind_col_red`, `geomind_col_gray`, `geomind_col_erase_line`.
  - [x] Ensure all color helpers return `""` when `g_chat_use_color == 0.0`.

- [x] **3. Dynamic In-Place ASCII Thinking Spinner (`test/geomind/chat.cl`)**
  - [x] Implement `geomind_get_spinner_frame(frame_idx: float) -> string`.
  - [x] In `geomind_chat_generate_reasoning_pass`, emit in-place thinking spinner frames with `\r` as genuine math executes.
  - [x] Erase spinner line cleanly upon completion.
  - [x] Color-style the structured Thought Process box with amber borders when thinking is visible.

- [x] **4. Dynamic In-Place Buffered Generation Counter & Spinner (`test/geomind/chat.cl`)**
  - [x] In `geomind_chat_generate_reply_multimodal`, emit rotating spinner, token count, and tok/s throughput using `\r` on active token decode steps.
  - [x] Erase spinner line cleanly on turn completion or interruption.
  - [x] Color-style assistant response label (`\e[1;32mGeoMind>\e[0m`), tool execution banners (`\e[1;33m`), and interruption notices (`\e[1;31m`).

- [x] **5. Interactive REPL Slash Commands & Styling (`test/geomind/main.car`)**
  - [x] Add `/color` and single-key `c` command handlers.
  - [x] Add `/anim` and single-key `a` command handlers.
  - [x] Color-style the REPL input prompts (`User:Rick>`, `Command>`).
  - [x] Update `/help` dialog.

- [x] **6. Dedicated Test Suite & Empirical Verification**
  - [x] Create `test/geomind/test_interface_coloring_and_animation.car` covering all 5 gates.
  - [x] Compile and execute test suite with status 0.
  - [x] Rebuild native `bin/geomind.exe` with `cartanc.exe`.
  - [x] Verify live prompt execution and interactive command session with colored text and animated spinner.
  - [x] Add preset `534` to `tools/run_affected_tests.ps1` and run regression suite (16/16 PASS).

- [x] **7. Documentation & Sprint Closure**
  - [x] Record and close `[ISSUE-392]` in `ISSUES.md`.
  - [x] Update `CHANGELOG.md` to `[8.490.0]`.
  - [x] Update Phase 25 (Item 16) in `docs/ROADMAP.md`.
  - [x] Check off all tasks in `docs/archive/sprint_534_task_list.md`.
  - [x] Save walkthrough to `docs/archive/sprint_534_walkthrough.md`.
