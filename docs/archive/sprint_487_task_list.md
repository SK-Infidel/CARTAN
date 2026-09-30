# Sprint 487 Task List: Phase 3 Standard Library Integrity & Complete C Runtime Elimination

## Gate 1: Native SQLite3 C-ABI Integration in `llvm_codegen.car`
- [x] **Task 1.1**: Register `sqlite3_*` extern signatures with precise parameter and return types in `src/cartanc/llvm_codegen.car`.
- [x] **Task 1.2**: Add `sqlite3_` prefix handler in `llvm_codegen.car` call expression generator for `i32` return value translation (`sitofp i32 to double`).
- [x] **Task 1.3**: Add `i32`/`i64` argument cast generation for `sqlite3_*` function parameters.

## Gate 2: Pure Native CARTAN `src/std/sqlite_vec.cl` & Elimination of `cartan_sqlite.c`
- [x] **Task 2.1**: Implement low-level SQLite3 wrappers (`sqlite_vec_open`, `sqlite_vec_close`, `sqlite_vec_exec`, `sqlite_vec_prepare`, `sqlite_vec_step`, `sqlite_vec_finalize`, `sqlite_vec_column_text`, `sqlite_vec_column_double`, `sqlite_vec_bind_*`) in pure native CARTAN in `src/std/sqlite_vec.cl`.
- [x] **Task 2.2**: Implement 6-table cognitive memory schema, CRUD routines, and metacognitive consolidation in pure CARTAN in `src/std/sqlite_vec.cl`.
- [x] **Task 2.3**: Add backwards compatibility aliases `cartan_sqlite_*` to ensure zero breaking changes for existing callers.
- [x] **Task 2.4**: Permanently delete `src/std/cartan_sqlite.c`.
- [x] **Task 2.5**: Remove `cartan_sqlite.c` compilation rule from `tools/zig_wrapper.py`.

## Gate 3: Portable Filesystem Swap in `src/std/fs.cl`
- [x] **Task 3.1**: Replace `MoveFileExA` in `fs_atomic_swap` with portable ISO C `remove(dst)` and `rename(src, dst)` in `src/std/fs.cl`.
- [x] **Task 3.2**: Remove `MoveFileExA` extern declaration from `src/std/fs.cl` and `llvm_codegen.car`.

## Gate 4: 3-Stage Bootstrap Fixpoint Convergence
- [x] **Task 4.1**: Execute 3-stage bootstrap (`bin/cartanc_stage1.exe` -> `bin/cartanc_fresh.exe` -> `bin/cartanc_stage3.exe`).
- [x] **Task 4.2**: Prove bit-for-bit fixpoint convergence via SHA256 comparison (`F62C9D21341111A0B9D74D0C3E6088046CE5532E9D5836AA26152D825088DB6E`).
- [x] **Task 4.3**: Synchronize `cartanc.exe` and `bin/cartanc.exe`.

## Gate 5: Empirical Regression Clearance & Chat Verification
- [x] **Task 5.1**: Recompile `build/geomind.exe` with new compiler and verify Tier 2 cognitive memory startup.
- [x] **Task 5.2**: Test chat inference: `What is the capital of Iran` -> `The capital of Iran is **Tehran**`.
- [x] **Task 5.3**: Synchronize `test/geomind/geomind.exe`.
- [x] **Task 5.4**: Run full 87-target regression test suite (`tools/run_affected_tests.ps1 -All`).
- [x] **Task 5.5**: Update `CHANGELOG.md`, `ISSUES.md`, and write `docs/archive/sprint_487_walkthrough.md`.
