# Sprint 439 Plan: Native GeoMind Chat Interface Hardening & Gemma 4-E4B Streaming Bridge Integration

## Context & Objectives
In Sprint 438, full 42-layer sequential execution and empirical autoregressive generation verification were completed. However, running the native compiled interactive binary `geomind --chat` exited back to the command prompt immediately. The objective of Sprint 439 is to restore full native terminal interactivity, eliminate all runtime crashes and back-end LLVM dominance issues, and enable streaming conversational generation directly inside GeoMind's native chat interface.

## Root Causes Identified
1. **`cartan_read_line` Float Pointer Segfault (`src/cartanc/core_runtime.car`)**: Line-reading logic previously performed pointer arithmetic by bitcasting pointers to IEEE-754 floats (`buf + (len - 1.0)`), corrupting the address and triggering an immediate access violation / SIGSEGV upon console input.
2. **UTF-8 BOM & Whitespace Discrepancies**: Windows PowerShell and command shell pipes emit leading UTF-8 Byte Order Marks (`0xEF, 0xBB, 0xBF`) and trailing whitespace, causing string equality checks on `"exit"` or `"quit"` to fail and execute invalid commands or trigger EOF.
3. **LLVM Dominance Error in AST Codegen (`test/geomind/chat.cl`)**: `cartan_vec_free(mom)` and `cartan_vec_free(history)` were called outside the `else` block where `mom` and `history` were scoped, emitting instructions in the merge block that did not dominate all uses.
4. **Ollama Streaming Socket Loop Hang (`src/std/cartan_gemma_engine.c`)**: `break;` upon detecting `"done":true` only exited the inner byte-processing `for` loop, causing the outer `while (1)` loop to block on `recv()` until the 60-second socket timeout.

## Scope of Work
- **Core Runtime Hardening**: Refactor `cartan_read_line()` in `src/cartanc/core_runtime.car` to use safe `cartan_string_substring`, detect and strip UTF-8 BOM, and trim leading/trailing whitespace.
- **Compiler Codegen & Chat Module Repair**: Remove out-of-scope vector frees in `test/geomind/chat.cl`, resolving LLVM module dominance integrity.
- **Gemma 4 Streaming Engine Bridge**: Harden `src/std/cartan_gemma_engine.c` with dual-loop `is_done` termination and clean socket closure.
- **Executable Deployment**: Compile `geomind.exe` and deploy to root, `bin/`, and `test/geomind/`.
- **Empirical Verification**: Validate single-turn CLI prompt generation and multi-turn interactive REPL sessions.
