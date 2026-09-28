# Sprint 459 Plan: Neuro-Symbolic Declarations, JIT & DataFrame Lowering, and AST Alignment

## Mission & Scope
Harmonize AST signatures in `src/cartanc/ast.ch:enum Stmt` for `GraphDecl` and `KnowledgeBaseDecl`, implement scoping in `src/cartanc/type_checker.car`, and implement robust codegen lowering in `src/cartanc/llvm_codegen.car` for `JitBlock`, `DataframeDecl`, `GraphDecl`, `RuleDecl`, and `KnowledgeBaseDecl`. Verify zero regressions across the compiler suite with new Target 69.

---

## Technical Workstreams

### Phase 1: AST Signature Alignment (`[ISSUE-245]`, `src/cartanc/ast.ch`)
- Update `ast.ch:enum Stmt`:
  - `GraphDecl(string, ptr)` (line 152)
  - `KnowledgeBaseDecl(string, ptr)` (line 154)

### Phase 2: Type Checker Scoping (`[ISSUE-246]`, `[ISSUE-247]`, `src/cartanc/type_checker.car`)
- Add visitor handlers in `tc_visit_stmt`:
  - `JitBlock` (`39.0 || 162.0`): Push scope, visit statements, pop scope.
  - `DataframeDecl` (`37.0 || 160.0`): Push scope, visit statements, pop scope.
  - `GraphDecl` (`29.0 || 152.0`): Push scope, visit statements, pop scope.
  - `RuleDecl` (`30.0 || 153.0`): Visit rule expression via `tc_visit_expr`.
  - `KnowledgeBaseDecl` (`31.0 || 154.0`): Push scope, visit statements, pop scope.

### Phase 3: Codegen Lowering (`[ISSUE-246]`, `[ISSUE-247]`, `src/cartanc/llvm_codegen.car`)
- Implement statement lowerings in `llvm_codegen.car:llvm_visit_stmt`:
  - `Stmt::JitBlock` (`39.0 || 162.0`):
    - Emit comment `; --- Begin JIT Block ---`.
    - Traverse inner statements via `llvm_visit_stmt`.
    - Emit comment `; --- End JIT Block ---`.
  - `Stmt::DataframeDecl` (`37.0 || 160.0`):
    - Emit comment `; --- Begin DataFrame: <name> ---`.
    - Traverse inner schema/column statements via `llvm_visit_stmt`.
    - Emit comment `; --- End DataFrame: <name> ---`.
  - `Stmt::GraphDecl` (`29.0 || 152.0`):
    - Emit comment `; --- Begin Graph: <name> ---`.
    - Traverse inner edge/node statements via `llvm_visit_stmt`.
    - Emit comment `; --- End Graph: <name> ---`.
  - `Stmt::RuleDecl` (`30.0 || 153.0`):
    - Emit comment `; --- Begin Rule: <name> ---`.
    - Lower rule body expression via `llvm_visit_expr`.
    - Store evaluation result in symbol dictionary for lookup.
    - Emit comment `; --- End Rule: <name> ---`.
  - `Stmt::KnowledgeBaseDecl` (`31.0 || 154.0`):
    - Emit comment `; --- Begin KnowledgeBase: <name> ---`.
    - Traverse inner fact/clause statements via `llvm_visit_stmt`.
    - Emit comment `; --- End KnowledgeBase: <name> ---`.

### Phase 4: Empirical Verification & Toolchain Integration
- Rebuild self-hosted `cartanc.exe`.
- Author Target 69 regression test: `test/compiler_suite/test_neuro_symbolic_jit.car`.
- Whitelist Target 69 in `.gitignore`.
- Run Target 69 standalone and verify all gates pass with genuine arithmetic and state updates.
- Register Target 69 in `test/compiler_suite/run_tests.car`.
- Rebuild test runner and execute all 69 targets (verify 0 failures).
- Mark `[ISSUE-245]` through `[ISSUE-247]` as `[FIXED]` in `ISSUES.md`.
- Update `CHANGELOG.md` (`[8.417.0]`).
- Update `docs/ROADMAP.md`.
- Save walkthrough to `docs/archive/sprint_459_walkthrough.md`.
