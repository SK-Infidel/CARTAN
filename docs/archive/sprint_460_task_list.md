# Sprint 460 Task List: AST Arity Harmonization, Trait/Impl Type Checking & Method Lowering

## Pre-Sprint Checklist
- [x] Full startup code review completed and documented in `docs/archive/startup_code_review_sprint460.md`.
- [x] Logical dependency tree established.
- [x] Technical issues registered in `ISSUES.md` (`[ISSUE-249]` through `[ISSUE-251]`).
- [x] Scrum discussion with Rick.

---

## Sprint Tasks

### Phase 1: AST Signature Harmonization (`[ISSUE-249]`, `src/cartanc/ast.ch:enum Stmt`)
- [x] Align `LayerDecl(string, string, ptr, string)`
- [x] Align `StreamDecl(ptr, string)`
- [x] Align `TopologyDecl(string, ptr)`
- [x] Align `MeshBlock(string, string, ptr)`
- [x] Align `TreeDecl(string, string)`
- [x] Align `FluidPrecisionBlock(string, string, ptr)`
- [x] Align `SparsityBlock(ptr, ptr, ptr)`

### Phase 2: Type Checker Scope & Discriminants (`[ISSUE-250]`, `src/cartanc/type_checker.car`)
- [x] Support dual discriminants `34.0 || 157.0` for `ImplDecl`.
- [x] Correct target struct resolution to index `2.0` in `ImplDecl`.
- [x] Support dual discriminants `33.0 || 156.0` for `TraitDecl`.

### Phase 3: LLVM IR Codegen Lowering for `ImplDecl` (`[ISSUE-251]`, `src/cartanc/llvm_codegen.car`)
- [x] Implement `ImplDecl` lowering in `llvm_visit_stmt` to iterate over and compile member methods.
- [x] Support member method dispatch in `MethodCall` lowering.

### Phase 4: Empirical Verification & Toolchain Integration
- [x] Rebuild self-hosted `cartanc.exe`.
- [x] Author Target 70 regression test: `test/compiler_suite/test_impl_trait_methods.car`.
- [x] Verify Target 70 passes all assertions cleanly.
- [x] Whitelist Target 70 in `.gitignore` and register in `test/compiler_suite/run_tests.car`.
- [x] Recompile `build/run_tests.exe` and verify all 70 targets pass with 0 failures.
- [x] Update `ISSUES.md` (`[ISSUE-249]` through `[ISSUE-251]` marked `[FIXED]`).
- [x] Update `CHANGELOG.md` (`[8.418.0]`).
- [x] Update `docs/ROADMAP.md`.
- [x] Archive walkthrough in `docs/archive/sprint_460_walkthrough.md`.
