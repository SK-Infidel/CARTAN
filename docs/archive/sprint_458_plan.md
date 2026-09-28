# Sprint 458 Plan: Statement Line Index Alignment, AST Arity Harmonization, and Spawn/Evolve Block Lowering

## Core Objectives
1. **[ISSUE-242] Full Statement Line Index Alignment in `llvm_codegen.car`**:
   - Align all statement line discriminant checks in `llvm_visit_stmt` to canonical line numbers in `ast.ch:enum Stmt`.
   - Eliminate critical collisions with `ExprStmt` (line 124), `EnumDecl` (line 125), and `VarDecl` (line 126).
2. **[ISSUE-243] AST Arity Harmonization in `ast.ch:enum Stmt`**:
   - Align `EvolveBlock(string, ptr)` to 2 arguments.
   - Align `Spawn(string, ptr)` to 2 arguments.
   - Align `ReceiveDecl(string, tree<ptr>, ptr)` to 3 arguments.
3. **[ISSUE-244] `spawn` & `evolve` Statement Lowering in `llvm_codegen.car`**:
   - Lower `Stmt::Spawn` (`36.0 || 159.0`): execute inner statements and register async task via `cartan_async_spawn`.
   - Lower `Stmt::EvolveBlock` (`32.0 || 155.0`): execute inner evolution statements under named evolution context.
4. **Empirical Verification**:
   - Author Target 68 regression test: `test/compiler_suite/test_async_spawn_evolve.car`.
   - Rebuild self-hosted `cartanc.exe`.
   - Register Target 68 in `test/compiler_suite/run_tests.car` and verify all 68 snapshot targets pass (0 failures).

---

## Step-by-Step Execution Plan

### Phase 1: AST Arity Harmonization (`src/cartanc/ast.ch`)
- Update `EvolveBlock` to `EvolveBlock(string, ptr)`.
- Update `Spawn` to `Spawn(string, ptr)`.
- Update `ReceiveDecl` to `ReceiveDecl(string, tree<ptr>, ptr)`.

### Phase 2: Statement Discriminant Alignment (`src/cartanc/llvm_codegen.car`)
- Recalculate and align all statement checks in `llvm_visit_stmt`:
  - `ParameterDecl`: `7.0 || 130.0`
  - `SequenceDecl`: `9.0 || 132.0`
  - `BlockDecl`: `10.0 || 133.0`
  - `LatticeDecl`: `11.0 || 134.0`
  - `TreeDecl`: `12.0 || 135.0`
  - `ExternFunctionDecl`: `15.0 || 138.0`
  - `Block`: `40.0 || 163.0`
  - `AsyncCompute`: `43.0 || 166.0`
  - `Backward`: `44.0 || 167.0`
  - `MultimodalBlock`: `48.0 || 171.0`
  - `VmapBlock`: `49.0 || 172.0`
  - `DoubtBlock`: `50.0 || 173.0`
  - `ChainBlock`: `51.0 || 174.0`
  - `RouteBlock`: `52.0 || 175.0`
  - `GrokBlock`: `53.0 || 176.0`
  - `OverrideBlock`: `54.0 || 177.0`
  - `ToolDecl`: `55.0 || 178.0`
  - `Satisfy`: `56.0 || 179.0`
  - `FluidPrecisionBlock`: `59.0 || 182.0`
  - `SparsityBlock`: `60.0 || 183.0`
  - `PruneGraph`: `61.0 || 184.0`
  - `EmitSpike`: `62.0 || 185.0`

### Phase 3: Lowering `Spawn` and `EvolveBlock` (`src/cartanc/llvm_codegen.car`)
- Add `Stmt::Spawn` handler: traverses spawned block statements and emits debug markers and async task initialization.
- Add `Stmt::EvolveBlock` handler: traverses evolution block statements with named checkpoint tagging.

### Phase 4: Target 68 Regression Test & Empirical Validation
- Create `test/compiler_suite/test_async_spawn_evolve.car`.
- Verify standalone compilation and execution.
- Register Target 68 in `test/compiler_suite/run_tests.car`.
- Rebuild `cartanc.exe` and `build/run_tests.exe`.
- Execute full 68-target regression test suite.

### Phase 5: Documentation & Git Commit
- Update `docs/archive/sprint_458_task_list.md`.
- Mark issues `[FIXED]` in `ISSUES.md`.
- Prepend release `[8.416.0]` in `CHANGELOG.md`.
- Update `docs/ROADMAP.md`.
- Author `docs/archive/sprint_458_walkthrough.md`.
- Commit and push to master.
