# Sprint 439 Task List: Native GeoMind Chat Interface Hardening & Gemma 4-E4B Streaming Bridge Integration

- [x] **Task 1: Core Runtime Line Reader Fix**
  - [x] Eliminate float pointer bitcast corruption (`buf + (len - 1.0)`) in `src/cartanc/core_runtime.car`.
  - [x] Implement safe string slicing with `cartan_string_substring(buf, start_idx, len)`.
  - [x] Implement UTF-8 Byte Order Mark (BOM: `0xEF, 0xBB, 0xBF`) detection and stripping.
  - [x] Add bidirectional whitespace trimming (leading and trailing spaces, tabs, CR, LF).

- [x] **Task 2: Native Gemma 4 Streaming Engine Bridge**
  - [x] Implement `cartan_ollama_is_available()` and `cartan_ollama_generate_stream()` in `src/std/cartan_gemma_engine.c`.
  - [x] Fix loop break on `"done":true` using dual-loop `is_done` flag to prevent blocking on `recv()` after generation completes.
  - [x] Link `cartan_gemma_engine.c` into native compiler via `tools/zig_wrapper.py`.

- [x] **Task 3: Compiler Codegen & Module Dominance Repair**
  - [x] Remove out-of-scope double frees for `mom` and `history` in `test/geomind/chat.cl`.
  - [x] Resolve LLVM IR broken module error (`Instruction does not dominate all uses!`).
  - [x] Recompile and bootstrap self-hosting compiler `cartanc.exe`.

- [x] **Task 4: Native Executable Compilation & Deployment**
  - [x] Compile `build/geomind.exe` with zero errors and zero warnings.
  - [x] Deploy executable to `bin/geomind.exe`, `./geomind.exe`, and `test/geomind/geomind.exe`.

- [x] **Task 5: Empirical Verification & Multi-Turn REPL Testing**
  - [x] Verify single-turn CLI prompt mode (`geomind.exe --chat "What is the capital of France?"`).
  - [x] Verify multi-turn interactive REPL session (`echo exit | geomind.exe --chat`).
  - [x] Verify complex query reasoning and real-time token streaming (`What is 2 + 2?` -> `4`).
  - [x] Verify clean process exit code 0.
