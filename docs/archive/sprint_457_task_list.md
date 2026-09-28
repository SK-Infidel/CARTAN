# Sprint 457 Task List: AST Variant Hardening, Statement Collisions & Attention/Fused Codegen

## Pre-Sprint Checklist
- [x] Full startup code review completed and documented in `docs/archive/startup_code_review_sprint457.md`.
- [x] Logical dependency tree established.
- [x] Identified technical issues registered in `ISSUES.md` (`[ISSUE-237]` through `[ISSUE-241]`).
- [x] Scrum discussion with Rick.

---

## Sprint Tasks

### Phase 1: Statement Discriminant Collision Rectification (`[ISSUE-237]`)
- [x] Align `SequenceDecl` in `src/cartanc/llvm_codegen.car` to `9.0 || 127.0`.
- [x] Align `BlockDecl` in `src/cartanc/llvm_codegen.car` to `10.0 || 128.0`.
- [x] Align `LatticeDecl` in `src/cartanc/llvm_codegen.car` to `11.0 || 129.0`.
- [x] Align `TreeDecl` in `src/cartanc/llvm_codegen.car` to `12.0 || 130.0`.
- [x] Align `ParameterDecl` in `src/cartanc/llvm_codegen.car` to `7.0 || 125.0`.
- [x] Align `ExternFunctionDecl` in `src/cartanc/llvm_codegen.car` to `15.0 || 133.0`.
- [x] Align `Block` in `src/cartanc/llvm_codegen.car` to `40.0 || 158.0`.
- [x] Align `FunctionCall` in `src/cartanc/llvm_codegen.car` to `17.0 || 81.0` (unblocking `Expr::Attention` at 27.0).

### Phase 2: AST Variant Declarations & Type Support (`[ISSUE-238]`)
- [x] Add `SievingCacheInit`, `FractalAttentionInit`, `ElasticVocabularyInit`, `SpikePrimitive`, `NeuronPrimitive` to `src/cartanc/ast.ch:enum Expr`.
- [x] Update `src/cartanc/type_checker.car` with dual discriminant checks for new AST variants.
- [x] Update `src/cartanc/llvm_codegen.car` to lower the new AST variants safely.

### Phase 3: Authentic `@attention` Primitives & Codegen (`[ISSUE-239]`)
- [x] Implement `cartan_attention(target: ptr, routing: ptr) -> ptr` in `src/cartanc/core_runtime.car`.
- [x] Export top-level `attention(target: ptr, routing: ptr) -> ptr` wrapper in `src/cartanc/core_runtime.car`.
- [x] Add dual discriminant checking in `src/cartanc/type_checker.car` (`27.0 || 91.0`).
- [x] Add prototype registration and LLVM IR lowering in `src/cartanc/llvm_codegen.car`.
- [x] Add `@` prefix token handling in `src/cartanc/lexer.car` and expression parsing for routing in `src/cartanc/parser.car`.

### Phase 4: `fused { ... }` Kernel Codegen (`[ISSUE-240]`)
- [x] Add dual discriminant checking in `src/cartanc/type_checker.car` (`26.0 || 90.0`).
- [x] Implement block statement execution and return value extraction in `src/cartanc/llvm_codegen.car`.

### Phase 5: MethodCall Argument Dispatch (`[ISSUE-241]`)
- [x] Update `MethodCall` discriminant check in `src/cartanc/llvm_codegen.car` to `18.0 || 82.0`.
- [x] Loop over `args`, evaluate parameters, and format parameter registers in the call string.

### Phase 6: Empirical Verification & Toolchain Integration
- [x] Rebuild self-hosted `cartanc.exe`.
- [x] Author Target 67 regression test: `test/compiler_suite/test_attention_fused_methods.car`.
- [x] Verify Target 67 passes all gates cleanly.
- [x] Register Target 67 in `test/compiler_suite/run_tests.car` and verify all 67 test targets pass.
- [x] Update `ISSUES.md` (`[ISSUE-237]` to `[ISSUE-241]` marked `[FIXED]`).
- [x] Update `CHANGELOG.md` (`[8.415.0]`).
- [x] Archive walkthrough in `docs/archive/sprint_457_walkthrough.md`.
