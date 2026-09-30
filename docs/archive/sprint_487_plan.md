# Sprint 487 Plan: Phase 3 Standard Library Integrity & Complete C Runtime Elimination

## 1. Context & Motivation
Following the successful completion of Phase 2 in Sprint 486, Sprint 487 executes Phase 3: the complete and permanent elimination of the very last C file in the entire repository (`src/std/cartan_sqlite.c`). This achieves 100% pure self-hosting CARTAN purity across the entire `src/` tree and eliminates the final C compilation hook from `tools/zig_wrapper.py`.

---

## 2. Sprint 487 Deliverables by Gate

### Gate 1: Native SQLite3 C-ABI Integration in `llvm_codegen.car`
- Register `sqlite3_*` functions in [`src/cartanc/llvm_codegen.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car) with precise LLVM IR signatures (`i32` return, `i32` column/size arguments, `i64` binding values).
- Add automatic `i32` return translation (`sitofp i32 to double`) and parameter casts in `llvm_codegen.car` for all calls starting with `sqlite3_`.

### Gate 2: Pure Native CARTAN `src/std/sqlite_vec.cl` & Permanent Elimination of `cartan_sqlite.c`
- Port all 26 functions from `cartan_sqlite.c` into pure native CARTAN in [`src/std/sqlite_vec.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/sqlite_vec.cl):
  - Database lifecycle: `sqlite_vec_open`, `sqlite_vec_close`, `sqlite_vec_exec`, `sqlite_vec_errmsg`.
  - Statement operations: `sqlite_vec_prepare`, `sqlite_vec_step`, `sqlite_vec_finalize`, `sqlite_vec_column_text`, `sqlite_vec_column_double`.
  - Cognitive memory schema & CRUD: `sqlite_vec_init_schema`, `sqlite_vec_upsert_domain`, `sqlite_vec_upsert_entity_state`, `sqlite_vec_upsert_rule`, `sqlite_vec_add_dependency`, `sqlite_vec_add_episode`, etc.
  - Metacognitive consolidation: `sqlite_vec_consolidate_episodes`, `sqlite_vec_apply_ebbinghaus_decay`, `sqlite_vec_materialize_to_cargraph`.
- Provide backward-compatible aliases: `cartan_sqlite_* -> sqlite_vec_*`.
- Permanently delete `src/std/cartan_sqlite.c`.
- In `tools/zig_wrapper.py`, delete the `cartan_sqlite.c` injection block.

### Gate 3: Portable Filesystem Swap in `src/std/fs.cl`
- In [`src/std/fs.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/fs.cl), replace Win32-only `MoveFileExA` with portable ISO C `remove(dst)` followed by `rename(src, dst)`.
- Purge `MoveFileExA` extern declaration and compiler references.

### Gate 4: 3-Stage Bootstrap Fixpoint Convergence
- Execute 3-stage bootstrap: `bin/cartanc_stage1.exe` -> `bin/cartanc_fresh.exe` -> `bin/cartanc_stage3.exe`.
- Prove bit-for-bit fixpoint convergence: `SHA256(bin/cartanc_fresh.ll) == SHA256(bin/cartanc_stage3.ll)`.
- Synchronize `cartanc.exe` and `bin/cartanc.exe`.

### Gate 5: Empirical Regression Clearance & Chat Verification
- Rebuild `build/geomind.exe` with new compiler and verify Tier 2 SQLite Cognitive Memory operations.
- Verify empirical chat generation: `"What is the capital of Iran"` -> `"The capital of Iran is **Tehran**."`.
- Synchronize `test/geomind/geomind.exe`.
- Run full 87-target compiler regression suite via `tools/run_affected_tests.ps1 -All` (87/87 pass).
