# Sprint 291 Implementation Plan: Compiler Subcommands & Runtime Fencing Hardening

## Goal
Resolve `[ISSUE-032]` (compiler subcommand stubs for `lsp` and `pkg` in `src/cartanc/main.car`) and `[ISSUE-033]` (runtime stubs for async coroutines, VRAM write-lock sandboxing, SWMR locking, atomic graph swapping, and C-header export in `src/cartanc/core_runtime.car`), achieving 3-stage bit-for-bit self-hosted bootstrap parity.

## Target Changes

### 1. `[ISSUE-032]` Compiler Subcommands (`src/cartanc/main.car`)
- **`cartan pkg`**:
  - Read `cartan.toml` manifest.
  - Compute authentic FNV-1a checksum string via `cartan_hash_string(content)`.
  - Parse manifest package name and version if present.
  - Write authentic `cartan.lock` with computed checksum and resolved dependency blocks.
- **`cartan lsp`**:
  - Implement persistent JSON-RPC 2.0 request loop over stdio.
  - Parse incoming JSON-RPC methods (`initialize`, `textDocument/hover`, `textDocument/completion`, `shutdown`, `exit`).
  - Return compliant JSON-RPC response payloads:
    - `initialize`: capabilities for hover, completion, definition, textDocumentSync.
    - `textDocument/hover`: hover documentation for CARTAN syntax and types.
    - `textDocument/completion`: keywords and core library symbols.
    - `shutdown`: null result.
    - `exit` or EOF: terminate loop cleanly.

### 2. `[ISSUE-033]` Core Runtime Fencing & Async Primitives (`src/cartanc/core_runtime.car`)
- **VRAM Sandboxing**:
  - Global variable `g_vram_param_locked`.
  - `cartan_rt_vram_lock_parameters()` sets `g_vram_param_locked = 1.0`.
  - `cartan_rt_vram_unlock_parameters()` sets `g_vram_param_locked = 0.0`.
  - `cartan_rt_check_vram_access(p, is_write)` returns 0.0 if locked and writing; 1.0 otherwise.
- **SWMR Reader-Writer Lock**:
  - Global variables `g_swmr_readers`, `g_swmr_writer`.
  - `cartan_rt_lock_swmr(p, ro)`: writer denied if readers > 0 or writer > 0; reader denied if writer > 0.
  - `cartan_rt_unlock_swmr(p)`: releases writer or decrements readers.
- **Atomic Graph Swap**:
  - `cartan_rt_atomic_swap_graph(slot, shadow)`: replaces `slot[0]` with `shadow` and returns prior pointer.
- **Async Coroutine Runtime**:
  - Global task queue and monotonic task counter.
  - `cartan_async_spawn(fn_ptr)`: enqueues task and returns task ID.
  - `cartan_async_yield()`: advances round-robin scheduler.
  - `cartan_async_await(task_id)`: awaits task ID completion.
- **C Header Exporter**:
  - `cartan_export_c_headers(out_h_path, content)`: writes content to file via `cartan_write_file`.

## Verification Steps
1. Apply edits to `src/cartanc/main.car` and `src/cartanc/core_runtime.car`.
2. Re-bootstrap compiler through 3 stages (`stage1` $\to$ `stage2` $\to$ `stage3`).
3. Verify bit-for-bit parity via `fc.exe /N scratch\stage2.ll scratch\stage3.ll`.
4. Promote verified Stage 3 compiler to `cartanc.exe`.
5. Execute regression targets:
   - `test/compiler_suite/test_security_sandboxing.car`
   - `test/compiler_suite/test_async_coroutines.car`
   - `test/compiler_suite/test_lsp.car`
   - `cartanc.exe pkg`
   - Full 47-target regression test suite (`test/compiler_suite/run_tests.car`).
6. Update `ISSUES.md`, `CHANGELOG.md`, and retrospective.
