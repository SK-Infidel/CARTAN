# Sprint 450 Task List: Freestanding Runtime Completeness & Warning Hygiene

- [x] **Task 1: Eliminate Compiler Diagnostic Warning (`[ISSUE-212]`)**
  - [x] 1.1 In `src/std/cartan_native_io.c`, wrap `#define _CRT_SECURE_NO_WARNINGS` with `#ifndef _CRT_SECURE_NO_WARNINGS`.
  - [x] 1.2 Verify clean compilation with zero warnings.

- [x] **Task 2: Implement Cognitive Control Block Hooks in Core Runtime (`[ISSUE-211]`)**
  - [x] 2.1 In `src/cartanc/core_runtime.car`, implement `cartan_rt_multimodal_sync_start()` and `cartan_rt_multimodal_sync_end()`.
  - [x] 2.2 In `src/cartanc/core_runtime.car`, implement `cartan_rt_doubt_begin()`, `cartan_rt_doubt_end()`, and doubt query state functions.
  - [x] 2.3 In `src/cartanc/core_runtime.car`, implement `cartan_rt_chain_begin()` and `cartan_rt_chain_end()`.
  - [x] 2.4 In `src/cartanc/core_runtime.car`, implement `cartan_rt_route_begin()` and `cartan_rt_route_end()`.
  - [x] 2.5 In `src/cartanc/core_runtime.car`, implement `cartan_rt_grok_begin()` and `cartan_rt_grok_end()`.
  - [x] 2.6 In `src/cartanc/core_runtime.car`, implement `cartan_rt_override_begin()` and `cartan_rt_override_end()`.

- [x] **Task 3: Implement Built-In Tensor & String Operations (`[ISSUE-211]`)**
  - [x] 3.1 In `src/cartanc/core_runtime.car`, implement `cartan_tensor_ones_like(A: ptr) -> ptr`.
  - [x] 3.2 In `src/cartanc/core_runtime.car`, implement `cartan_tensor_zeros_like(A: ptr) -> ptr`.
  - [x] 3.3 In `src/cartanc/core_runtime.car`, implement `cartan_tensor_transpose(A: ptr) -> ptr`.
  - [x] 3.4 In `src/cartanc/core_runtime.car`, implement `cartan_pattern_match(cond: string, pat: string) -> float`.
  - [x] 3.5 In `src/cartanc/lexer.car`, add missing `override` keyword to `check_keyword`.

- [x] **Task 4: Recompile Self-Hosted Compiler & Verify**
  - [x] 4.1 Recompile `cartanc.exe` using `./cartanc.exe build src/cartanc/main.car -o cartanc.exe`.
  - [x] 4.2 Author regression test `test/compiler_suite/test_core_builtins.car` verifying the new built-ins.
  - [x] 4.3 Execute `build/run_tests.exe` and confirm 100% test passes with 0 failures across all 60 targets.
  - [x] 4.4 Update `ISSUES.md`, `CHANGELOG.md`, and write `docs/archive/sprint_450_walkthrough.md`.
