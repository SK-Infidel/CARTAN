# Sprint 11 Implementation Plan: `comptime` Evaluation & Static Autograd

## Goal
Implement the final backlog item across all 4 Pillars (`[BACKLOG-COMPTIME-01]`) across the parser, type checker, runtime, and automated regression test runner:
1. **`[BACKLOG-COMPTIME-01]` `comptime` Expression Evaluation & Static Autograd (`grad(f)`, `vmap(f)`)**

---

## 1. Phase Breakdown

### Phase 1: `comptime` & Autograd Helpers ([c_runtime.c](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/c_runtime.c))
- Implement `cartan_rt_autograd_forward_grad()` and `cartan_rt_vmap_eval()` zero-allocation autograd helpers in `src/cartanc/c_runtime.c`.
- Synchronize `src/cartanc/c_runtime.c` with `C:\Users\rich-\.cartan\c_runtime.c`.

### Phase 2: Test Target & Runner Integration ([test/compiler_suite/test_comptime_autograd.car](file:///C:/Users/rich-/source/repos/CARTAN/test/compiler_suite/test_comptime_autograd.car), [run_tests.car](file:///C:/Users/rich-/source/repos/CARTAN/test/compiler_suite/run_tests.car))
- Create test target `test_comptime_autograd.car` (`// run-pass`).
- Register target `[9/9]` in `run_tests.car`.

### Phase 3: Final Master Backlog Completion & Verification
- Update `ISSUES.md` (Mark all backlog items 100% completed!), `CHANGELOG.md` (`v1.0.0`), and save walkthrough to `docs/archive/sprint11_walkthrough.md`.
