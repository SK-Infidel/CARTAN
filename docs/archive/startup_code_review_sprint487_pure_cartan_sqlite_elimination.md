# Startup Code Review: Sprint 487 — Phase 3 Standard Library Integrity & Complete C Runtime Elimination

**Date**: 2026-09-29  
**Reviewer**: Antigravity  
**Target Repository**: CARTAN (`SK-Infidel/CARTAN`)  
**Mission Scope**: Phase 3 of Codebase Integrity Master Plan — Elimination of the Last C File (`src/std/cartan_sqlite.c`), Native SQLite3 C-ABI Integration in `llvm_codegen.car`, Portable Cross-Platform Filesystem Swap in `fs.cl`, and 100% Pure CARTAN Self-Hosting.

---

## 1. Executive Summary & Code Audit Findings

During the full repository audit following the successful completion of Sprint 486 (Phase 2 core runtime stub eradication), an exhaustive scan of all `.c` and `.cpp` files was conducted:
- **`src/` Directory Audit**:
  - `src/cartanc/`: 100% CARTAN (`.car`, `.ch`). Zero C files.
  - `src/std/`: Contains **one remaining C file**: [`src/std/cartan_sqlite.c`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/cartan_sqlite.c) (455 lines).
- **`test/` and `tools/` Audit**: Zero C files in `test/` or `tools/`.
- **Compiler Toolchain Dependency (`tools/zig_wrapper.py`)**:
  - Line 57: `if os.path.exists("src/std/cartan_sqlite.c"): clang_args.extend(["-x", "c", "src/std/cartan_sqlite.c"])`.
  - Every CARTAN executable compiled via `zig_wrapper.py` was being bundled with `cartan_sqlite.c` via Clang `-x c`, creating a persistent C runtime bypass and two-language maintenance overhead.
- **Portability Blocker in `src/std/fs.cl`**:
  - `fs_atomic_swap` calls `MoveFileExA` (Win32 specific API), blocking Linux compilation unless gated or replaced. ISO C `remove(dst)` + `rename(src, dst)` provides full POSIX/Windows cross-platform atomic swap.

---

## 2. Detailed Technical Findings

### 2.1 The Last C File: `src/std/cartan_sqlite.c`
- **Location**: `src/std/cartan_sqlite.c` (455 lines).
- **Current Behavior**:
  - Acts as a thin C wrapper around SQLite3 C API (`sqlite3_open`, `sqlite3_close`, `sqlite3_exec`, `sqlite3_prepare_v2`, `sqlite3_step`, `sqlite3_finalize`, `sqlite3_column_text`, `sqlite3_column_double`, `sqlite3_bind_*`).
  - Implements 16 helper functions (`cartan_sqlite_upsert_domain`, `cartan_sqlite_upsert_entity_state`, `cartan_sqlite_init_schema`, etc.) that merely construct SQL strings and execute them.
- **Root Cause of Two-Language Reliance**:
  - `llvm_codegen.car` did not previously define `sqlite3_*` C ABI calling signatures (specifically `i32` parameter and return type casts).
- **Solution**:
  - Register `sqlite3_*` in `src/cartanc/llvm_codegen.car` with authentic C ABI signatures (`i32` return translation via `sitofp i32 to double` and `double` to `i32`/`i64` parameter casting).
  - Port all 26 functions from `cartan_sqlite.c` directly into [`src/std/sqlite_vec.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/sqlite_vec.cl) in 100% pure native CARTAN.
  - Permanently delete `src/std/cartan_sqlite.c`.
  - Remove `cartan_sqlite.c` compilation rule from `tools/zig_wrapper.py`.

### 2.2 Win32 API Leak in `src/std/fs.cl`
- **Location**: [`src/std/fs.cl:21, 43`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/fs.cl).
- **Current Behavior**: `fs_atomic_swap` calls `MoveFileExA(src, dst, 9.0)`.
- **Impact**: Cross-compilation to Linux (`x86_64-linux-gnu`) fails to link due to undefined `MoveFileExA`.
- **Solution**:
  - Replace `MoveFileExA` in `fs_atomic_swap` with portable ISO C `remove(dst)` followed by `rename(src, dst)`.
  - Remove `MoveFileExA` extern declaration from `fs.cl`.

---

## 3. Logical Dependency Tree

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                CARTAN DEPENDENCY GRAPH                                 │
├────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                        │
│   src/cartanc/main.car                                                                 │
│     ├── src/cartanc/lexer.car                                                          │
│     ├── src/cartanc/parser.car                                                         │
│     ├── src/cartanc/type_checker.car                                                   │
│     ├── src/cartanc/optimizer.car                                                      │
│     ├── src/cartanc/llvm_codegen.car                                                   │
│     │     └── [NEW] sqlite3_* C ABI Signature Registry (declare & cast)                │
│     └── src/cartanc/core_runtime.car                                                   │
│                                                                                        │
│   tools/zig_wrapper.py                                                                 │
│     └── [PURGE] Remove `src/std/cartan_sqlite.c` injection                             │
│                                                                                        │
│   src/std/sqlite_vec.cl (100% Pure Native CARTAN)                                      │
│     ├── Direct extern calls to @sqlite3_open, @sqlite3_close, @sqlite3_exec            │
│     ├── Direct extern calls to @sqlite3_prepare_v2, @sqlite3_step, @sqlite3_finalize   │
│     ├── Direct extern calls to @sqlite3_column_text, @sqlite3_column_double            │
│     ├── Direct extern calls to @sqlite3_bind_int64, @sqlite3_bind_double, etc.         │
│     ├── Pure CARTAN 6-Table Cognitive Schema & Metacognitive Consolidation             │
│     └── Backward-compatible aliases: cartan_sqlite_* -> sqlite_vec_*                   │
│                                                                                        │
│   src/std/fs.cl                                                                        │
│     └── Pure portable ISO C `remove` / `rename` (Zero Win32 MoveFileExA)               │
│                                                                                        │
│   Dependents:                                                                          │
│     ├── test/geomind/chat.cl (Tier 2 SQLite Memory & Entity Grounding)                 │
│     ├── test/geomind/main.car (Consolidation & .car_graph v2 Materialization)          │
│     └── 87 Compiler Test Suite Targets                                                 │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Issues Identified & Tracked
- **[ISSUE-306]**: Last C Runtime Dependency: `src/std/cartan_sqlite.c` and Win32 `MoveFileExA` in `fs.cl`.
