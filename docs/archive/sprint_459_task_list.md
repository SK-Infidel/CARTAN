# Sprint 459 Task List: Neuro-Symbolic Declarations, JIT & DataFrame Lowering, and AST Alignment

## Pre-Sprint Checklist
- [x] Full startup code review completed and documented in `docs/archive/startup_code_review_sprint459.md`.
- [x] Logical dependency tree established.
- [x] Identified technical issues registered in `ISSUES.md` (`[ISSUE-245]` through `[ISSUE-247]`).
- [x] Scrum discussion with Rick.

---

## Sprint Tasks

### Phase 1: AST Signature Alignment (`[ISSUE-245]`)
- [x] Align `GraphDecl(string, ptr)` in `src/cartanc/ast.ch:enum Stmt`.
- [x] Align `KnowledgeBaseDecl(string, ptr)` in `src/cartanc/ast.ch:enum Stmt`.

### Phase 2: Type Checker Scoping (`[ISSUE-246]`, `[ISSUE-247]`)
- [x] Add `JitBlock` handler in `src/cartanc/type_checker.car:tc_visit_stmt`.
- [x] Add `DataframeDecl` handler in `src/cartanc/type_checker.car:tc_visit_stmt`.
- [x] Add `GraphDecl` handler in `src/cartanc/type_checker.car:tc_visit_stmt`.
- [x] Add `RuleDecl` handler in `src/cartanc/type_checker.car:tc_visit_stmt`.
- [x] Add `KnowledgeBaseDecl` handler in `src/cartanc/type_checker.car:tc_visit_stmt`.

### Phase 3: Codegen Lowering (`[ISSUE-246]`, `[ISSUE-247]`, `[ISSUE-248]`)
- [x] Implement `Stmt::JitBlock` handler in `src/cartanc/llvm_codegen.car:llvm_visit_stmt`.
- [x] Implement `Stmt::DataframeDecl` handler in `src/cartanc/llvm_codegen.car:llvm_visit_stmt`.
- [x] Implement `Stmt::GraphDecl` handler in `src/cartanc/llvm_codegen.car:llvm_visit_stmt`.
- [x] Implement `Stmt::RuleDecl` handler in `src/cartanc/llvm_codegen.car:llvm_visit_stmt`.
- [x] Implement `Stmt::KnowledgeBaseDecl` handler in `src/cartanc/llvm_codegen.car:llvm_visit_stmt`.
- [x] Implement contextual declaration recognition (`graph`, `layer`) in `src/cartanc/parser.car:declaration`.

### Phase 4: Empirical Verification & Toolchain Integration
- [x] Rebuild self-hosted `cartanc.exe`.
- [x] Author Target 69 regression test: `test/compiler_suite/test_neuro_symbolic_jit.car`.
- [x] Verify Target 69 passes all gates cleanly.
- [x] Register Target 69 in `test/compiler_suite/run_tests.car` and verify all 69 targets pass.
- [x] Update `ISSUES.md` (`[ISSUE-245]` to `[ISSUE-248]` marked `[FIXED]`).
- [x] Update `CHANGELOG.md` (`[8.417.0]`).
- [x] Archive walkthrough in `docs/archive/sprint_459_walkthrough.md`.
