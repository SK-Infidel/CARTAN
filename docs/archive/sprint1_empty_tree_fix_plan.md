# Sprint 1 Implementation Plan: Empty Tree Bug Fix (`ISSUE-009`)

## Problem Statement
The self-hosted compiler `main.exe` emits `Entering generate()! len=0.000000` because `cartan_tree_len_f` is invoked in `src/cartanc/main.car` and `src/cartanc/llvm_codegen.car`, but is missing from `src/cartanc/c_runtime.c` and header declarations.

## Affected Files
1. `src/cartanc/c_runtime.c` - Add `cartan_tree_len_f` wrapper function.
2. `src/cartanc/main.car` - Add `extern fn cartan_tree_len_f(t: ptr) -> float;` declaration and deduplicate externs.
3. `src/cartanc/ast.ch` - Verify/add `cartan_tree_len_f` header declaration.
4. `ISSUES.md` - Mark `ISSUE-009` fixed.
5. `CHANGELOG.md` - Document fix under release notes.

## Verification Criteria
1. Rebuild `cartanc.exe`.
2. Compile test Cartan source (`scratch/test_simple.car` or `src/cartanc/main.car`).
3. Verify `len` reported by `ast_expansion_pass` and `generate()` is non-zero (`len > 0.0`).
