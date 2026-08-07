# Sprint 8 Implementation Plan: AI Ergonomics & Zero-Copy DLPack FFI

## Goal
Implement Pillar 2 AI interoperability and strided tensor slicing across the C runtime, parser, LLVM code generator, and regression test suite:
1. **`[BACKLOG-FFI-01]` Zero-Copy DLPack & C-ABI PyTorch/C++ Interoperability**
2. **`[BACKLOG-ND-01]` Multi-Dimensional Strided ND-Slicing (`t[a..b:step, :]`)**

---

## 1. Phase Breakdown

### Phase 1: DLPack C-ABI Structures & Zero-Copy Wrappers ([c_runtime.c](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/c_runtime.c))
- Define `DLDeviceType`, `DLDataType`, `DLTensor`, and `DLManagedTensor` standard layouts in `c_runtime.c`.
- Implement `cartan_tensor_from_dlpack()` and `cartan_tensor_to_dlpack()` for zero-copy memory wrapping.
- Implement `cartan_slice_nd()` for multi-dimensional strided slicing.
- Synchronize `src/cartanc/c_runtime.c` with `C:\Users\rich-\.cartan\c_runtime.c`.

### Phase 2: Test Target & Runner Integration ([test/compiler_suite/test_dlpack_slicing.car](file:///C:/Users/rich-/source/repos/CARTAN/test/compiler_suite/test_dlpack_slicing.car), [run_tests.car](file:///C:/Users/rich-/source/repos/CARTAN/test/compiler_suite/run_tests.car))
- Create test target `test_dlpack_slicing.car` (`// run-pass`).
- Register target `[6/6]` in `run_tests.car`.

### Phase 3: Documentation & Verification
- Update `ISSUES.md`, `CHANGELOG.md` (`v0.10.0`), and save walkthrough to `docs/archive/sprint8_walkthrough.md`.
