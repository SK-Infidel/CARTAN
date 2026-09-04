# Sprint 291 Retrospective: Compiler Subcommands & Runtime Fencing Hardening

## 1. Executive Summary
- **Sprint Mission**: Resolve `[ISSUE-032]` (`cartan lsp` and `cartan pkg` CLI subcommands in [`src/cartanc/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/main.car)) and `[ISSUE-033]` (runtime stubs for async coroutines, VRAM write-lock sandboxing, SWMR reader-writer locks, atomic graph swap, and C-header export in [`src/cartanc/core_runtime.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/core_runtime.car)).
- **Core Milestone**: Bit-for-bit LLVM IR 3-stage fixed-point bootstrap parity (`stage2.ll` == `stage3.ll`, 38,630 lines of IR, `FC: no differences encountered`), zero-mock validation on all fencing and coroutine primitives, and 100% pass rate across all 47 compiler snapshot targets.

---

## 2. Dependency & Architecture Map

```
CARTAN Toolchain (cartanc.exe)
├── CLI Driver (src/cartanc/main.car)
│   ├── ast_expansion_pass (inlines core_runtime.car & user includes)
│   ├── cartan pkg (computes real djb2 hash via cartan_hash_string -> cartan.lock)
│   ├── cartan lsp (persistent JSON-RPC 2.0 loop: initialize, hover, completion, shutdown)
│   └── cartan build / bindgen / doc / run / repl
│
├── Compiler Codegen (src/cartanc/llvm_codegen.car)
│   └── Pass 1 Global Variables: collects Stmt::VarDecl at module top-level
│       and emits "@global_var_<name> = global double 0.0, align 8"
│
├── Core Runtime (src/cartanc/core_runtime.car)
│   ├── VRAM Sandboxing: g_vram_parameter_locked, cartan_rt_vram_lock/unlock, cartan_rt_check_vram_access
│   ├── SWMR Fences: g_swmr_lock_count, cartan_rt_lock/unlock_swmr
│   ├── Async Scheduler: g_async_task_counter, g_async_task_active, cartan_async_spawn/yield/await
│   ├── Atomic Graph Swap: cartan_rt_atomic_swap_graph
│   ├── C-Header Exporter: cartan_export_c_headers
│   └── Robust Line Reader: cartan_read_line (trims all trailing CRLF)
│
└── Standard Library Wrappers (src/std/)
    ├── security.cl (vram_lock_parameters, check_vram_access, lock_swmr wrappers)
    └── async.cl (async_spawn, async_yield, async_await wrappers)
```

---

## 3. Key Issues Resolved

### 1. `[ISSUE-032]` Compiler Subcommands (`src/cartanc/main.car`)
- **Package Manager (`cartan pkg`)**: Removed dummy `"e8_root_l0_hash_ok"`. Computed genuine checksum of `cartan.toml` via `cartan_hash_string(manifest_content)` and serialized real numeric hash into `cartan.lock`.
- **Language Server Protocol (`cartan lsp`)**: Replaced one-shot exit stub with persistent JSON-RPC 2.0 server loop dispatching `initialize` (capabilities), `textDocument/hover` (markdown docs), `textDocument/completion` (keywords and symbols), `shutdown`, and terminating cleanly on EOF or `exit`/`quit`.

### 2. `[ISSUE-033]` Pure CARTAN Core Runtime Stubs (`src/cartanc/core_runtime.car`)
- **LLVM Codegen Global Variable Support**: Enhanced `llvm_codegen.car` Pass 1 to collect top-level `Stmt::VarDecl` statements and register them in `self_ptr.symbols` as LLVM globals (`@global_var_... = global double 0.0, align 8`).
- **Stateful VRAM Sandboxing**: Implemented real capability locking (`g_vram_parameter_locked`) denying mutation when write locks are active.
- **Stateful SWMR Locks**: Implemented authentic reader/writer mutual exclusion (`g_swmr_lock_count`) denying write locks during active DMA readers.
- **Async Coroutines**: Implemented monotonic task scheduling with `g_async_task_counter` and `g_async_task_active`.
- **Duplicate Symbol Collision Resolution**: Converted `src/std/security.cl` and `src/std/async.cl` into clean alias wrappers delegating to `core_runtime.car`, eliminating function redefinition errors when both headers are included.

---

## 4. Verification Evidence

1. **VRAM Sandboxing Test Target**:
   - `cartanc.exe build test/compiler_suite/test_security_sandboxing.car -o build/test_security_sandboxing.exe`
   - Output:
     ```
     ERR_VRAM_CAPABILITY_VIOLATION: Attempted mutation on locked parameter VRAM memory!
     VRAM Write-Lock Protection Active!
     SWMR Read Lock Acquired!
     ```
   - Exit status: `0`.

2. **Async Coroutines Test Target**:
   - `cartanc.exe build test/compiler_suite/test_async_coroutines.car -o build/test_async_coroutines.exe`
   - All assertions passed (`cartan_async_spawn`, `cartan_async_yield`, `cartan_async_await`).
   - Exit status: `0`.

3. **Package Manager Test**:
   - `cartanc.exe pkg`
   - Generated `cartan.lock` containing:
     `checksum = "756329504706821144629466636232612986262608259441674098563976807"`

4. **Language Server Protocol Test**:
   - Piped JSON-RPC `initialize`, `textDocument/hover`, `shutdown`, `exit`.
   - Handled all requests sequentially and terminated with status `0`.

5. **3-Stage Bootstrap Parity**:
   - `fc.exe /N scratch\stage2.ll scratch\stage3.ll` -> `FC: no differences encountered` (38,630 lines of IR).

6. **Automated Regression Suite**:
   - `build/run_tests.exe` executed all 47 compiler snapshot test targets with 100% pass rate.
