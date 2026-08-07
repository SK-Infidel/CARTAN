# Sprint 10 Implementation Plan: Toolchain, `static_assert!` & Package Infrastructure

## Goal
Implement Pillar 4 toolchain primitives, compile-time assertions, package manifests, and C header exports across the parser, type checker, main entrypoint, and regression test runner:
1. **`[BACKLOG-ASSERT-01]` User-Facing Compile-Time Assertions (`static_assert!`)**
2. **`[BACKLOG-PKG-01]` Package Manifest (`cartan.toml`) & C Header Exporter (`--emit-c-headers`)**

---

## 1. Phase Breakdown

### Phase 1: `static_assert!` Parsing & Const Evaluator ([parser.car](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/parser.car), [type_checker.car](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/type_checker.car))
- Parse `static_assert!(condition, "Error message")` in `src/cartanc/parser.car`.
- Evaluate constant expressions in `src/cartanc/type_checker.car` and emit rich diagnostic carets on invariant assertion failure.

### Phase 2: Package Manifest & C Header Exporter ([main.car](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/main.car), [llvm_codegen.car](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car))
- Parse `cartan.toml` package metadata.
- Implement `--emit-c-headers` pass in `main.car` to emit `.h` C-ABI function declarations for CARTAN libraries.

### Phase 3: Test Target & Runner Integration ([test/compiler_suite/test_static_assert.car](file:///C:/Users/rich-/source/repos/CARTAN/test/compiler_suite/test_static_assert.car), [run_tests.car](file:///C:/Users/rich-/source/repos/CARTAN/test/compiler_suite/run_tests.car))
- Create test target `test_static_assert.car` (`// run-pass`).
- Register target `[8/8]` in `run_tests.car`.

### Phase 4: Documentation & Verification
- Update `ISSUES.md`, `CHANGELOG.md` (`v0.12.0`), and save walkthrough to `docs/archive/sprint10_walkthrough.md`.
