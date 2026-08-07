# Sprint 6 Implementation Plan: `BACKLOG-002` Slice Indexing & Tuple Pattern Matching

## Goal
Implement slice range expressions (`arr[start..end]`) and tuple pattern matching deconstruction (`let (a, b) = expr`) across the parser, type checker, LLVM code generator, C runtime, and regression test runner.

---

## 1. Scope & Architecture

1. **Slice Indexing (`arr[start..end]`)**:
   - **Parser ([parser.car](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/parser.car))**: In index access expressions `arr[expr]`, handle `start..end` range expressions (parsed as `Expr::BinaryOp(start, "..", end)`).
   - **Type Checker ([type_checker.car](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/type_checker.car))**: Verify range slice indexing on arrays, trees, and strings, returning slice/tree views.
   - **LLVM Codegen & C Runtime ([llvm_codegen.car](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car), [c_runtime.c](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/c_runtime.c))**: Lower range slice expressions into native runtime helper calls (`cartan_slice_tree`, `c_cartan_string_substring`).

2. **Tuple Pattern Matching Deconstruction (`let (a, b) = expr`)**:
   - **Parser ([parser.car](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/parser.car))**: Support `(a, b)` tuple pattern identifiers in variable declarations (`var_declaration`).
   - **Type Checker & Codegen ([type_checker.car](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/type_checker.car), [llvm_codegen.car](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car))**: Bind positional tuple variables to stack allocations and deconstructed elements.

3. **Regression Test Coverage ([test/compiler_suite/test_slices_tuples.car](file:///C:/Users/rich-/source/repos/CARTAN/test/compiler_suite/test_slices_tuples.car))**:
   - Create test target `test_slices_tuples.car` (`// run-pass`) and integrate it into `run_tests.car`.
