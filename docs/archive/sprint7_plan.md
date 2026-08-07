# Sprint 7 Implementation Plan: High-Speed Foundations & Rich Diagnostics

## Goal
Implement Pillar 1 infrastructure upgrades across the C runtime, parser, type checker, LLVM code generator, and test runner:
1. **`[BACKLOG-PERF-01]` $O(1)$ Open-Addressing Hash Symbol Table**
2. **`[BACKLOG-MEM-01]` Region / Bump Arena Allocator**
3. **`[BACKLOG-DIAG-01]` Rich Diagnostics Engine (`cartan_diag`)**

---

## 1. Phase Breakdown

### Phase 1: $O(1)$ Hash Dictionary & Arena Allocator ([c_runtime.c](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/c_runtime.c))
- Implement FNV-1a open-addressing hash dictionary (`cartan_hash_dict_get`, `cartan_hash_dict_set`).
- Implement bump arena allocation (`cartan_arena_alloc`, `cartan_arena_reset`) for AST nodes.
- Synchronize `src/cartanc/c_runtime.c` with `C:\Users\rich-\.cartan\c_runtime.c`.

### Phase 2: AST `SourceSpan` Plumbing ([ast.ch](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/ast.ch), [parser.car](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/parser.car))
- Extend `Span` in `ast.ch` with column ranges and line ranges (`SourceSpan`).
- Attach `SourceSpan` metadata to AST nodes during parser initialization and token consumption.

### Phase 3: Rich Diagnostic Caret Formatter (`cartan_diag`) ([parser.car](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/parser.car))
- Implement line gutter rendering with `^^^` caret pointers and `did_you_mean` typo suggestions for syntax and type errors.

### Phase 4: Automated Verification ([run_tests.car](file:///C:/Users/rich-/source/repos/CARTAN/test/compiler_suite/run_tests.car))
- Verify clean compilation, test suite execution, and issue sign-offs.
