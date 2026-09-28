# Sprint 458 Walkthrough: Statement Line Index Alignment, AST Arity Harmonization, and Spawn/Evolve Block Lowering

## Overview
Sprint 458 systematically resolved three fundamental compiler integrity issues logged in `ISSUES.md` (`[ISSUE-242]` through `[ISSUE-244]`), realigning statement line discriminants with canonical indices, harmonizing statement AST constructor arities, and implementing codegen lowering for `Spawn`, `EvolveBlock`, and `ReceiveDecl`.

---

## Changes Implemented

### 1. AST Arity Harmonization (`src/cartanc/ast.ch`, `[ISSUE-243]`)
Aligned the parameter definitions in `src/cartanc/ast.ch:enum Stmt` to match the exact constructions emitted by `src/cartanc/parser.car`:
- `EvolveBlock(string, ptr)` (line 155)
- `ReceiveDecl(string, tree<ptr>, ptr)` (line 158)
- `Spawn(string, ptr)` (line 159)

Added lexical scoping and statement traversal support for these three statement kinds in `src/cartanc/type_checker.car:tc_visit_stmt`.

### 2. Statement Discriminant Alignment (`src/cartanc/llvm_codegen.car`, `[ISSUE-242]`)
Aligned all statement discriminant checks in `src/cartanc/llvm_codegen.car:llvm_visit_stmt` to match the source line positions of `ast.ch:enum Stmt`:
- `ParameterDecl`: `7.0 || 130.0` (was 125.0)
- `SequenceDecl`: `9.0 || 132.0` (was 127.0)
- `BlockDecl`: `10.0 || 133.0` (was 128.0)
- `LatticeDecl`: `11.0 || 134.0` (was 129.0)
- `TreeDecl`: `12.0 || 135.0` (was 130.0)
- `ExternFunctionDecl`: `15.0 || 138.0` (was 133.0)
- `Block`: `40.0 || 163.0` (was 158.0)
- `AsyncCompute`: `43.0 || 166.0` (was 103.0)
- `Backward`: `44.0 || 167.0` (was 104.0)
- `MeshBlock`: `47.0 || 170.0` (was 109.0)
- `MultimodalBlock`: `48.0 || 171.0` (was 111.0)
- `VmapBlock`: `49.0 || 172.0` (was 112.0)
- `DoubtBlock`: `50.0 || 173.0` (was 113.0)
- `ChainBlock`: `51.0 || 174.0` (was 114.0)
- `RouteBlock`: `52.0 || 175.0` (was 115.0)
- `GrokBlock`: `53.0 || 176.0` (was 116.0)
- `OverrideBlock`: `54.0 || 177.0` (was 117.0)
- `ToolDecl`: `55.0 || 178.0` (was 118.0)
- `Satisfy`: `56.0 || 179.0` (was 119.0)
- `Backtrack`: `57.0 || 180.0` (was 120.0)
- `FluidPrecisionBlock`: `59.0 || 182.0` (was 123.0)
- `SparsityBlock`: `60.0 || 183.0` (was 124.0, which collided with ExprStmt)
- `PruneGraph`: `61.0 || 184.0` (was 125.0, which collided with EnumDecl)
- `EmitSpike`: `62.0 || 185.0` (was 126.0, which collided with VarDecl)

### 3. Lowering `Spawn`, `EvolveBlock`, & `ReceiveDecl` (`src/cartanc/llvm_codegen.car`, `src/cartanc/core_runtime.car`, `[ISSUE-244]`)
- Implemented `Stmt::Spawn` (`36.0 || 159.0`):
  - Emits section comment `; --- Begin Spawn Block: <name> ---`.
  - Assigns `@cartan_async_spawn(ptr null)` to a newly allocated register via `next_reg(self_ptr)` preserving LLVM instruction numbering sequence.
  - Recursively visits all nested statements via `llvm_visit_stmt`.
  - Invokes `@cartan_async_yield()` and assigns to register.
  - Emits section closing comment.
- Implemented `Stmt::EvolveBlock` (`32.0 || 155.0`):
  - Emits section comment `; --- Begin Evolve Block: <name> ---`.
  - Recursively visits all nested statements via `llvm_visit_stmt`.
  - Emits section closing comment.
- Implemented `Stmt::ReceiveDecl` (`35.0 || 158.0`):
  - Emits section comment `; --- Begin Receive Handler: <name> ---`.
  - Recursively visits all nested handler statements.
  - Emits section closing comment.
- Implemented `cartan_tensor_alloc_nd(ndim, d0, d1, d2, d3)` in `src/cartanc/core_runtime.car` and corrected its 5-argument extern declaration in `llvm_codegen.car:478`.

### 4. Empirical Verification & Toolchain Integration
- Authored Target 68 regression test: `test/compiler_suite/test_async_spawn_evolve.car`.
- Tested and verified:
  1. `spawn WorkerActor` incremented `g_async_task_counter` and executed mutation accumulator.
  2. `evolve PopulationOptimizer` performed real arithmetic update to `base_fitness`.
  3. `receive packet` inside `spawn ReceptorAgent` executed handler logic.
  4. Collision-free declaration and execution of `sequence`, `block`, `lattice`, `tree`, `parameter`, `VarDecl`, `ExprStmt`, `emit_spike`, and `prune_graph`.
- Whitelisted `test_async_spawn_evolve.car` in `.gitignore`.
- Registered Target 68 in `test/compiler_suite/run_tests.car` and verified all 68 targets pass.

---

## Verification Results
- **Target 68 Standalone**: PASS (Exit Code 0).
- **Regression Suite**: 68/68 targets PASS (Exit Code 0, 0 failures).
