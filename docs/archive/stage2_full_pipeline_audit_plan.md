# CARTAN Self-Hosting Pipeline: Full Code Review, Dependency Tree & Parity Plan

## 1. Logical Architecture & Dependency Graph

The CARTAN self-hosting compiler pipeline consists of 8 modules arranged in a strict linear and hierarchical dependency topology:

```
┌────────────────────────────────────────────────────────┐
│                   src/cartanc/ast.ch                   │
│   (Enum Expr, Enum Stmt, Struct Token, Struct Span)   │
└───────────┬──────────────┬──────────────┬──────────────┘
            │              │              │
            ▼              ▼              ▼
     lexer.car       parser.car   type_checker.car
            │              │              │
            └──────────────┼──────────────┘
                           │
                           ▼
                     optimizer.car
                           │
                           ▼
                   llvm_codegen.car
                           │
    ┌──────────────────────┴──────────────────────┐
    │                                             │
    ▼                                             ▼
main.car (CLI / Driver)                  c_runtime.c (C ABI)
    │                                             │
    └──────────────────────┬──────────────────────┘
                           │ (Zig Clang LLVM Linker)
                           ▼
                    cartanc_stage2.exe
```

### Module Roles & Interfaces
1. [`src/cartanc/ast.ch`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/ast.ch):
   - **Root data definition**: defines `enum Expr` (50 variants), `enum Stmt` (64 variants), `struct Token`, `struct Span`, and `enum TokenType`.
   - All modules depend on its memory layout and sequential 0-based discriminant ordering.
2. [`src/cartanc/lexer.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/lexer.car):
   - Scans UTF-8 CARTAN source code, creating tokens with `token_type: ptr` and `span: Span`.
3. [`src/cartanc/parser.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/parser.car):
   - Consumes tokens and constructs the AST tree. Uses `Stmt::<Variant>` and `Expr::<Variant>` enum constructors.
4. [`src/cartanc/type_checker.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/type_checker.car):
   - Validates types, checks function declarations, and infers struct/pointer representations. Uses canonical `ast.ch` discriminants.
5. [`src/cartanc/optimizer.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/optimizer.car):
   - Performs constant folding and Dead Code Elimination.
6. [`src/cartanc/llvm_codegen.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car):
   - Lowers AST nodes into LLVM IR text, orchestrating Pass 1 (type/extern declarations), Pass 2 (function signatures), and Pass 3 (instruction generation).
7. [`src/cartanc/c_runtime.c`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/c_runtime.c):
   - Bare-metal execution engine (Tensors, WebGPU, GC/arena, OS file I/O, CLI args).
8. [`src/cartanc/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/main.car):
   - Top-level compiler driver managing CLI arguments, module inclusion expansion (`ast_expansion_pass`), pipeline stages, and invoking the Zig linker.

---

## 2. Comprehensive Code Review Findings & Predicted Risks

### A. Duplicate Symbol Conflict (`sys_get_arg` / `sys_get_arg_count`) [CRITICAL]
- **Location**: [`src/cartanc/llvm_codegen.car:241-248, 818-827`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L241)
- **Problem**: Lines 818–827 emit native LLVM function definitions (`define ptr @sys_get_arg`). In Pass 1, `sys_get_arg` is not present in `self_ptr.declared_externs`, so when `main.car:40` declares `extern fn sys_get_arg`, Pass 1 emits `declare ptr @sys_get_arg`, causing Zig to halt with `error: invalid redefinition of function 'sys_get_arg'`.
- **Downstream Effect**: Halts LLVM IR compilation at line 1429.
- **Predicted Solution**: Register `sys_get_arg` and `sys_get_arg_count` in `declared_externs` during codegen initialization.

### B. AST Discriminant Alignment (Obsolete Variant Numbers) [CRITICAL]
- **Location**: [`src/cartanc/llvm_codegen.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car)
- **Problem**: When `ast.ch` was updated, new variants shifted variant numbers. `type_checker.car` was updated, but `llvm_codegen.car` retained legacy numbers:
  - **Expr**:
    - `MethodCall`: `ast.ch` variant **18.0** vs codegen `29.0`
    - `PropertyAccess`: `ast.ch` variant **20.0** vs codegen `34.0`
    - `ArrayDecl`: `ast.ch` variant **24.0** vs codegen `43.0`
    - `AddressOf`: `ast.ch` variant **42.0** vs codegen `75.0`
    - `Dereference`: `ast.ch` variant **43.0** vs codegen `76.0`
  - **Stmt**:
    - `TensorDecl` (6 vs 12.0), `ParameterDecl` (7 vs 21.0), `VectorDecl` (8 vs 28.0), `SequenceDecl` (9 vs 32.0), `BlockDecl` (10 vs 34.0), `LatticeDecl` (11 vs 36.0), `TreeDecl` (12 vs 39.0)
    - `TryCatch` (20 vs 62.0), `AbsorbWeights` (22 vs 66.0), `Spawn` (36 vs 99.0), `MatchStmt` (41 vs 75.0), `AsyncCompute` (43 vs 103.0)
    - Block statements: `MeshBlock` (47 vs 109.0), `MultimodalBlock` (48 vs 111.0), `VmapBlock` (49 vs 112.0), `DoubtBlock` (50 vs 113.0), `ChainBlock` (51 vs 114.0), `RouteBlock` (52 vs 115.0), `GrokBlock` (53 vs 116.0), `OverrideBlock` (54 vs 117.0), `ToolDecl` (55 vs 118.0), `Satisfy` (56 vs 119.0), `Backtrack` (57 vs 120.0), `FluidPrecisionBlock` (59 vs 123.0), `SparsityBlock` (60 vs 124.0), `PruneGraph` (61 vs 125.0), `EmitSpike` (62 vs 126.0).
- **Downstream Effect**: When Stage-2 runs to compile user code or Stage-3, any code utilizing properties (`obj.field`), methods (`obj.method()`), arrays (`[1, 2]`), or domain blocks would be silently skipped or miscompiled.
- **Predicted Solution**: Update all checks to canonical `ast.ch` values while retaining legacy values with `||` for bulletproof compatibility.

### C. OS Runtime Linkage Integrity [VERIFIED SAFE]
- All external OS functions declared in [`src/cartanc/main.car:11-35`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/main.car#L11) (`cartan_copy_file`, `cartan_get_env`, `cartan_jit_eval`, `cartan_read_line`, `cartan_file_exists`, `cartan_read_file`, `cartan_tree_write_file`) are verified present and exported in [`src/cartanc/c_runtime.c`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/c_runtime.c). Linkage will succeed.

---

## 3. Execution Plan

1. **Fix 1: Suppress Duplicate `sys_get_arg` / `sys_get_arg_count` Declarations**:
   - In [`src/cartanc/llvm_codegen.car:243`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L243), push `"sys_get_arg"` and `"sys_get_arg_count"` to `declared_externs`.
2. **Fix 2: Align All Expression & Statement Discriminants in `llvm_codegen.car`**:
   - Expressions: update `MethodCall` (18.0), `PropertyAccess` (20.0), `ArrayDecl` (24.0), `AddressOf` (42.0), `Dereference` (43.0).
   - Statements: update `TensorDecl` (6.0), `ParameterDecl` (7.0), `VectorDecl` (8.0), `SequenceDecl` (9.0), `BlockDecl` (10.0), `LatticeDecl` (11.0), `TreeDecl` (12.0), `TryCatch` (20.0), `AbsorbWeights` (22.0), `Spawn` (36.0), `MatchStmt` (41.0), `AsyncCompute` (43.0), and blocks (47.0–62.0).
3. **Build & Verification Cycle**:
   - Step A: Rebuild `cartanc.exe` via `.\cartanc_boot.exe build src/cartanc/main.car -o cartanc.exe`.
   - Step B: Verify regression test: `.\cartanc.exe build test/test_add.car -o bin/test_add.exe; .\bin\test_add.exe`.
   - Step C: Self-compile Stage 2: `.\cartanc.exe build src/cartanc/main.car -o cartanc_stage2.exe`.
   - Step D: Validate `cartanc_stage2.exe` compiles `test/test_add.car` and outputs `Result: 42.000000`.
