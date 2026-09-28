# Sprint 458 Task List: Statement Line Index Alignment, AST Arity Harmonization, and Spawn/Evolve Block Lowering

## Pre-Sprint Checklist
- [x] Full startup code review completed and documented in `docs/archive/startup_code_review_sprint458.md`.
- [x] Logical dependency tree established.
- [x] Identified technical issues registered in `ISSUES.md` (`[ISSUE-242]` through `[ISSUE-244]`).
- [x] Scrum discussion with Rick.

---

## Sprint Tasks

### Phase 1: AST Arity Harmonization (`[ISSUE-243]`)
- [x] Align `EvolveBlock(string, ptr)` in `src/cartanc/ast.ch:enum Stmt`.
- [x] Align `Spawn(string, ptr)` in `src/cartanc/ast.ch:enum Stmt`.
- [x] Align `ReceiveDecl(string, tree<ptr>, ptr)` in `src/cartanc/ast.ch:enum Stmt`.

### Phase 2: Statement Discriminant Alignment (`[ISSUE-242]`)
- [x] Align `ParameterDecl` to `7.0 || 130.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `SequenceDecl` to `9.0 || 132.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `BlockDecl` to `10.0 || 133.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `LatticeDecl` to `11.0 || 134.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `TreeDecl` to `12.0 || 135.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `ExternFunctionDecl` to `15.0 || 138.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `Block` to `40.0 || 163.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `AsyncCompute` to `43.0 || 166.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `Backward` to `44.0 || 167.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `MultimodalBlock` to `48.0 || 171.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `VmapBlock` to `49.0 || 172.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `DoubtBlock` to `50.0 || 173.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `ChainBlock` to `51.0 || 174.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `RouteBlock` to `52.0 || 175.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `GrokBlock` to `53.0 || 176.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `OverrideBlock` to `54.0 || 177.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `ToolDecl` to `55.0 || 178.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `Satisfy` to `56.0 || 179.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `FluidPrecisionBlock` to `59.0 || 182.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `SparsityBlock` to `60.0 || 183.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `PruneGraph` to `61.0 || 184.0` in `src/cartanc/llvm_codegen.car`.
- [x] Align `EmitSpike` to `62.0 || 185.0` in `src/cartanc/llvm_codegen.car`.

### Phase 3: Lowering `Spawn` and `EvolveBlock` (`[ISSUE-244]`)
- [x] Implement `Stmt::Spawn` handler in `src/cartanc/llvm_codegen.car`.
- [x] Implement `Stmt::EvolveBlock` handler in `src/cartanc/llvm_codegen.car`.
- [x] Implement `Stmt::ReceiveDecl` handler in `src/cartanc/llvm_codegen.car`.
- [x] Implement `cartan_tensor_alloc_nd` in `src/cartanc/core_runtime.car`.

### Phase 4: Empirical Verification & Toolchain Integration
- [x] Rebuild self-hosted `cartanc.exe`.
- [x] Author Target 68 regression test: `test/compiler_suite/test_async_spawn_evolve.car`.
- [x] Verify Target 68 passes all gates cleanly.
- [x] Register Target 68 in `test/compiler_suite/run_tests.car` and verify all 68 targets pass.
- [x] Update `ISSUES.md` (`[ISSUE-242]` to `[ISSUE-244]` marked `[FIXED]`).
- [x] Update `CHANGELOG.md` (`[8.416.0]`).
- [x] Archive walkthrough in `docs/archive/sprint_458_walkthrough.md`.
