# Startup Code Review — Sprint 458

## Executive Summary
This startup review explores compiler frontend AST arity consistency, statement discriminant line indices in `llvm_codegen.car`, and actor/concurrency block lowering (`spawn`, `evolve`, `receive`) for Sprint 458.

---

## Identified Issues & Technical Debt

### 1. Statement Discriminant Outdated Line Numbers (`[ISSUE-242]`)
In `src/cartanc/llvm_codegen.car:llvm_visit_stmt`:
- Statements 43 through 62 check line numbers (`103..126`) that belong to an obsolete version of `ast.ch`.
- Crucially, `124.0`, `125.0`, and `126.0` collide directly with `ExprStmt` (line 124), `EnumDecl` (line 125), and `VarDecl` (line 126), causing statement interception.
- Canonical line numbers from `ast.ch:enum Stmt`:
  - `ParameterDecl`: index 7.0, line 130.0
  - `SequenceDecl`: index 9.0, line 132.0
  - `BlockDecl`: index 10.0, line 133.0
  - `LatticeDecl`: index 11.0, line 134.0
  - `TreeDecl`: index 12.0, line 135.0
  - `ExternFunctionDecl`: index 15.0, line 138.0
  - `Block`: index 40.0, line 163.0
  - `AsyncCompute`: index 43.0, line 166.0
  - `Backward`: index 44.0, line 167.0
  - `VmapBlock`: index 49.0, line 172.0
  - `DoubtBlock`: index 50.0, line 173.0
  - `ChainBlock`: index 51.0, line 174.0
  - `RouteBlock`: index 52.0, line 175.0
  - `GrokBlock`: index 53.0, line 176.0
  - `OverrideBlock`: index 54.0, line 177.0
  - `ToolDecl`: index 55.0, line 178.0
  - `Satisfy`: index 56.0, line 179.0
  - `FluidPrecisionBlock`: index 59.0, line 182.0
  - `SparsityBlock`: index 60.0, line 183.0
  - `PruneGraph`: index 61.0, line 184.0
  - `EmitSpike`: index 62.0, line 185.0

### 2. AST Definition Arity Mismatch in `ast.ch:enum Stmt` (`[ISSUE-243]`)
- `parser.car:638` constructs `Stmt::EvolveBlock(name, body)` with 2 fields, while `ast.ch:155` declares `EvolveBlock(ptr)` with 1 field.
- `parser.car:732` constructs `Stmt::Spawn(name, body)` with 2 fields, while `ast.ch:159` declares `Spawn(ptr)` with 1 field.
- `parser.car:672` constructs `Stmt::ReceiveDecl(name, params, body)` with 3 fields, while `ast.ch:158` declares `ReceiveDecl(string, ptr)` with 2 fields.
- Mismatching parameter counts cause `allocate_node` and enum payload indexing to corrupt adjacent AST fields.

### 3. Missing Lowering for `spawn` and `evolve` in `llvm_codegen.car` (`[ISSUE-244]`)
- `parser.car` parses `spawn Target { ... }` and `evolve Block { ... }`.
- `llvm_codegen.car` completely lacks visit handlers for `Spawn` (36.0 / 159.0) and `EvolveBlock` (32.0 / 155.0), causing them to be silently dropped during compilation.
- `core_runtime.car` already provides `cartan_async_spawn(fn_ptr) -> float`, `cartan_async_yield() -> float`, and `cartan_async_await(id) -> float`.

---

## Logical Dependency Tree
```
ast.ch (Stmt::EvolveBlock, Stmt::Spawn, Stmt::ReceiveDecl arity aligned)
  └── parser.car (constructs canonical AST nodes)
        └── type_checker.car (validates body stmts with dual discriminants)
              └── llvm_codegen.car (lowers statements using canonical line numbers)
                    └── core_runtime.car (invokes cartan_async_spawn, yield, await)
                          └── test_async_spawn_evolve.car (Target 68 verification)
```
