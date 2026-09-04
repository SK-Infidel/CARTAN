# Sprint 289 Implementation Plan: Compiler Core Hardening

## Goal
Harden the self-hosted CARTAN compiler core by resolving 4 compiler defects identified during the codebase audit (`[ISSUE-029]`, `[ISSUE-030]`, `[ISSUE-031]`, and `[ISSUE-034]`), followed by 3-stage bit-for-bit self-hosting verification and regression validation.

## Target Changes
1. **`[ISSUE-029]` Lexer Logical NOT (`src/cartanc/lexer.car`)**:
   Add `else { ttype_op = TokenType::Not; }` to the `c == 33.0` match arm so unary `!` is properly tokenized as `TokenType::Not` (137.0).
2. **`[ISSUE-030]` TypeChecker Scope Resolution (`src/cartanc/type_checker.car`)**:
   - Align `struct TypeChecker` fields (`functions`, `symbol_table`, `struct_registry`) with `type_checker_init()`.
   - Initialize the top-level global scope in `type_checker_init()`.
   - Update `pop_scope` to pop the active scope from `symbol_table` using `cartan_tree_remove`.
   - Update `resolve_var` to traverse backwards through `symbol_table` stack frames.
3. **`[ISSUE-031]` AST Optimizer Constant Folding (`src/cartanc/optimizer.car`)**:
   Replace `cartan_float_to_string` string serialization in `optimize_expr` with raw float representations (`Expr::Float(val_l [op] val_r)`).
4. **`[ISSUE-034]` System Command Wrapper (`src/cartanc/core_runtime.car`)**:
   Export `cartan_system(cmd: string) -> float` delegating to `system(cmd)` for `src/std/io.cl:io_exec`.

## Verification Steps
1. Create `scratch/test_sprint289_fixes.car` verifying `!x`, constant folded floats, and `cartan_system`.
2. Compile and run test with current `cartanc.exe`.
3. Bootstrap compiler across 3 stages (`stage1` -> `stage2` -> `stage3`).
4. Compare `scratch/cartanc_stage2.ll` and `scratch/cartanc_stage3.ll` using `fc.exe` to guarantee bit-for-bit fixed-point parity.
5. Promote verified Stage 3 compiler to `cartanc.exe`.
6. Run 47-target compiler test suite (`test/compiler_suite/run_tests.car`).
7. Update `ISSUES.md`, `CHANGELOG.md`, and retrospective.
