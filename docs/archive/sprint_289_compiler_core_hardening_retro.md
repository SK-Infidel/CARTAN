# Sprint 289 Retrospective: Compiler Core Hardening

## Overview
- **Sprint**: 289
- **Scope**: Compiler Core Hardening (`src/cartanc/`), AST/Lexer/Codegen Invariant Enforcement, and Multi-Stage Bootstrap Validation.
- **Status**: Completed & Empirically Validated.

## Issues Resolved
1. **`[ISSUE-029]`**: Fixed lexer dropping logical NOT (`!`) operator by adding missing `else` branch setting `ttype_op = TokenType::Not` in `src/cartanc/lexer.car`. Also resolved latent non-monotonic LLVM register allocation in `src/cartanc/llvm_codegen.car` by allocating comparison registers prior to output registers.
2. **`[ISSUE-030]`**: Resolved `TypeChecker` scope stack and variable resolution disconnection in `src/cartanc/type_checker.car`. Aligned struct fields, pushed initial global scope, implemented `pop_scope` with `cartan_tree_remove`, and added reverse stack traversal in `resolve_var`.
3. **`[ISSUE-031]`**: Fixed AST optimizer constant folding in `src/cartanc/optimizer.car` by replacing string serialization with raw `Expr::Float(val_l [op] val_r)` AST node constructors.
4. **`[ISSUE-034]`**: Added `cartan_system(cmd: string) -> float` wrapper to `src/cartanc/core_runtime.car` and added `CARTAN_WEAK` linkage to `cartan_system` in `src/cartanc/geomind_runtime.c` to prevent duplicate symbol linker warnings.

## Empirical Verification
- `scratch/test_sprint289_fixes.car`: Built and executed cleanly, validating `!x`, constant folded float operations, and `cartan_system` invocation.
- 3-Stage Self-Hosting Bootstrap: `scratch/cartanc_stage2.ll` and `scratch/cartanc_stage3.ll` (37,906 lines) verified bit-for-bit identical via `fc.exe`.
- Regression Suite: All 47 compiler snapshot test targets passed cleanly in `test/compiler_suite/run_tests.car`.
- GeoMind Integration: `geomind.exe` compiled and executed with exit code 0 and zero linker warnings.
