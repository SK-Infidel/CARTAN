# Sprint 516 Task List: Native Standalone Compiler Linker Driver

- [x] **Task 1: Pre-Sprint Scrum & Issue Logging**
  - [x] Log `[ISSUE-369]` and `[ISSUE-370]` in `ISSUES.md`.
  - [x] Update `docs/ROADMAP.md` with Phase 24 Sprint 516 tracking.
  - [x] Consult specialized subagents (`cartan_compiler_engineer`, `cartan_qa_tester`, `cartan_architect`).

- [x] **Task 2: Implement Pure CARTAN Toolchain Resolution & Linker Driver**
  - [x] In `src/cartanc/core_runtime.car`, implement `cartan_resolve_compiler_path()`.
  - [x] In `src/cartanc/core_runtime.car`, implement `cartan_get_compiler_lib_flags()`.
  - [x] Update build logic in `src/cartanc/main.car` and `cartan_jit_eval` in `src/cartanc/core_runtime.car` to format and invoke native Clang directly via `system(cmd)`.
  - [x] Replace `Compiling LLVM IR to native executable via Zig...` with concise, accurate compiler status logging.

- [x] **Task 3: Compiler Frontend Hygiene**
  - [x] Remove `[DEBUG include]` and `[DEBUG lex]` trace statements from `src/cartanc/main.car`.

- [x] **Task 4: 3-Stage Bootstrap Verification & Parity Proof**
  - [x] Build Stage 1 with root `cartanc.exe`.
  - [x] Build Stage 2 with Stage 1.
  - [x] Build Stage 3 with Stage 2.
  - [x] Validate bit-for-bit SHA-256 fixpoint parity of `cartanc_stage2.ll` vs `cartanc_stage3.ll` (`2BE39C010FC91AF8E176D5AFE9FB34DD9C3D0D012DD4090AC641D0070A321573`).
  - [x] Promote Stage 2 binary to root `cartanc.exe` and `bin/cartanc.exe`.

- [x] **Task 5: Empirical Regression Suite & Definition of Done**
  - [x] Run affected test targets using `tools/run_affected_tests.ps1 -Auto` (7/7 passed in 12.95s).
  - [x] Verify canary file severance test with `tools/zig_wrapper.py` renamed (Build 0, Run 0).
  - [x] Verify GeoMind full neural engine build (`bin/geomind_test.exe`) and CLI `--help` invocation.
  - [x] Document results in `docs/archive/sprint_516_walkthrough.md`.
  - [x] Update `CHANGELOG.md`.
