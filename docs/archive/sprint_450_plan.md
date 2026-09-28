# Sprint 450 Plan: Freestanding Runtime Completeness & Compiler Warning Hygiene

**Date**: 2026-09-27  
**Author**: Antigravity Pair Programmer (Daddy Rick / Rick & Antigravity)  
**Sprint**: 450  
**Status**: APPROVED / ACTIVE

---

## 1. Pre-Sprint Scrum Notes

### Discoveries from Startup Code Review
1. **Unimplemented Built-In Externs (`[ISSUE-211]`)**:
   - `llvm_codegen.car` declares cognitive block lifecycle hooks (`override`, `chain`, `route`, `grok`, `doubt`, `multimodal`), tensor built-in helpers (`cartan_tensor_ones_like`, `cartan_tensor_zeros_like`, `cartan_tensor_transpose`), and string pattern matching (`cartan_pattern_match`), but none are implemented in `src/cartanc/core_runtime.car`.
   - Standalone user programs attempting to use these native CARTAN language constructs fail link with unresolved external symbols.
2. **Compiler Diagnostic Warning (`[ISSUE-212]`)**:
   - `src/std/cartan_native_io.c:1` redefines `_CRT_SECURE_NO_WARNINGS`, generating a warning across every compilation unit.
3. **Read-Ahead / Predictive Impact**:
   - Implementing these built-ins in `src/cartanc/core_runtime.car` is 100% additive, guarantees freestanding language contract compliance, and introduces zero regressions to existing code.

---

## 2. Sprint 450 Objectives

1. **Freestanding Core Runtime Completeness (`src/cartanc/core_runtime.car`)**:
   - Implement cognitive control block lifecycle hooks:
     - `cartan_rt_multimodal_sync_start()`
     - `cartan_rt_doubt_begin()` & `cartan_rt_doubt_end()`
     - `cartan_rt_chain_begin()` & `cartan_rt_chain_end()`
     - `cartan_rt_route_begin()` & `cartan_rt_route_end()`
     - `cartan_rt_grok_begin()` & `cartan_rt_grok_end()`
     - `cartan_rt_override_begin()` & `cartan_rt_override_end()`
   - Implement tensor built-in operations:
     - `cartan_tensor_ones_like(A: ptr) -> ptr`
     - `cartan_tensor_zeros_like(A: ptr) -> ptr`
     - `cartan_tensor_transpose(A: ptr) -> ptr`
   - Implement prompt pattern matcher:
     - `cartan_pattern_match(cond: string, pattern: string) -> float`
2. **Build Hygiene & Warning Elimination (`src/std/cartan_native_io.c`)**:
   - Guard `_CRT_SECURE_NO_WARNINGS` with `#ifndef`.
3. **Toolchain Bootstrap & Verification**:
   - Recompile `cartanc.exe` with self-hosting compiler.
   - Author standalone regression verification for the new built-ins.
   - Run the 59-target regression test suite (`build/run_tests.exe`) to ensure 100% clean passes.
