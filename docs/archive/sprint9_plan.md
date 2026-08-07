# Sprint 9 Implementation Plan: AI Security, VRAM Protection & Sandboxing

## Goal
Implement Pillar 3 AI security primitives, memory lock guards, and transactional graph hot-swapping across the C runtime, LLVM code generator, and regression test suite:
1. **`[BACKLOG-SEC-01]` Capabilities-Based VRAM Protection (`@agent_accessible`)**
2. **`[BACKLOG-SEC-02]` SWMR Unified Memory Fences & Atomic Slice Descriptors**
3. **`[BACKLOG-SEC-03]` Transactional Double-Buffered `.aer` Hot-Swapping (`W^X`)**

---

## 1. Phase Breakdown

### Phase 1: VRAM Lock Guards, SWMR Fences & Hot-Swapping ([c_runtime.c](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/c_runtime.c))
- Implement `cartan_rt_vram_lock_parameters()`, `cartan_rt_vram_unlock_parameters()`, and `cartan_rt_check_vram_access()`.
- Implement `cartan_rt_lock_swmr()` and `cartan_rt_unlock_swmr()`.
- Implement `cartan_rt_atomic_swap_graph()` for transactional double-buffered `.aer` hot-swapping.
- Synchronize `src/cartanc/c_runtime.c` with `C:\Users\rich-\.cartan\c_runtime.c`.

### Phase 2: Test Target & Runner Integration ([test/compiler_suite/test_security_sandboxing.car](file:///C:/Users/rich-/source/repos/CARTAN/test/compiler_suite/test_security_sandboxing.car), [run_tests.car](file:///C:/Users/rich-/source/repos/CARTAN/test/compiler_suite/run_tests.car))
- Create test target `test_security_sandboxing.car` (`// run-pass`).
- Register target `[7/7]` in `run_tests.car`.

### Phase 3: Documentation & Verification
- Update `ISSUES.md`, `CHANGELOG.md` (`v0.11.0`), and save walkthrough to `docs/archive/sprint9_walkthrough.md`.
