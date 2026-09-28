# Startup Code Review & Logical Dependency Tree — Sprint 457

## Executive Summary
This startup code review audits the CARTAN compiler and runtime codebase prior to Sprint 457. Following the successful completion and verification of Sprint 456 (Target 66, Release 8.414.0), the codebase was audited for AST completeness, discriminant collisions, expression lowering coverage, runtime fidelity, and zero-mock directive compliance.

---

## 1. Identified Issues & Technical Debt

### `[ISSUE-237]` Statement Discriminant Collisions in `src/cartanc/llvm_codegen.car`
- **Component**: `src/cartanc/llvm_codegen.car:1745-2018`
- **Description**: Statement discriminant checks in `llvm_codegen.car` use legacy line indices that collide with active enum variants in `ast.ch:enum Stmt`:
  - `SequenceDecl`: checks `9.0 || 32.0` (collides with `EvolveBlock` 32.0; correct line is 127.0).
  - `BlockDecl`: checks `10.0 || 34.0` (collides with `ImplDecl` 34.0; correct line is 128.0).
  - `LatticeDecl`: checks `11.0 || 36.0` (collides with `Spawn` 36.0; correct line is 129.0).
  - `TreeDecl`: checks `12.0 || 39.0` (collides with `JitBlock` 39.0; correct line is 130.0).
  - `ExternFunctionDecl`: checks `15.0 || 48.0` (collides with `MultimodalBlock` 48.0; correct line is 133.0).
  - `Block`: checks `36.0 || 99.0` (collides with `Spawn` 36.0; correct line is 158.0, index 40.0).
- **Remediation**: Update statement discriminant checks to match canonical enum indices and line numbers from `ast.ch`.

### `[ISSUE-238]` Missing AST Variants in `src/cartanc/ast.ch:enum Expr`
- **Component**: `src/cartanc/ast.ch:63-115`, `src/cartanc/parser.car:1882-1916`
- **Description**: `parser.car` constructs and returns `Expr::SievingCacheInit`, `Expr::FractalAttentionInit`, `Expr::ElasticVocabularyInit`, `Expr::SpikePrimitive`, and `Expr::NeuronPrimitive`. However, none of these variants exist in `ast.ch:enum Expr`. Consequently, the enum variant tag resolves to `0.0`, silently degrading these nodes into `Expr::Integer`.
- **Remediation**: Declare all five variants in `ast.ch:enum Expr` with proper discriminants, and update type checking and codegen.

### `[ISSUE-239]` Unhandled AST Expression Lowering & Missing Runtime for `@attention` (`Expr::Attention`)
- **Component**: `src/cartanc/parser.car:1580`, `src/cartanc/ast.ch:91`, `src/cartanc/type_checker.car:582`, `src/cartanc/llvm_codegen.car`, `src/cartanc/core_runtime.car`
- **Description**: `@attention(target, routing_val)` parses into `Expr::Attention(target, routing_val)`. In `type_checker.car`, it only checks single discriminant `27.0` (missing `91.0`). In `llvm_codegen.car`, it is completely unhandled, falling through to `"0.0"`. `core_runtime.car` lacks an authentic `@attention` runtime kernel.
- **Remediation**: Add dual discriminant checking in `type_checker.car`, implement authentic attention routing in `core_runtime.car:cartan_attention(target, routing)`, and lower calling `@cartan_attention` in `llvm_codegen.car`.

### `[ISSUE-240]` Unhandled AST Expression Lowering for `fused { ... }` (`Expr::FusedKernel`)
- **Component**: `src/cartanc/parser.car:2123`, `src/cartanc/type_checker.car:433`, `src/cartanc/llvm_codegen.car`
- **Description**: `fused { ... }` parses into `Expr::FusedKernel(blk)` (index 26.0 / line 90.0). `type_checker.car` only checks `26.0` (missing `90.0`). In `llvm_codegen.car`, `FusedKernel` is completely unhandled and returns `"0.0"`.
- **Remediation**: Add dual discriminant checking in `type_checker.car`, lower `Expr::FusedKernel` in `llvm_codegen.car` by executing all inner statements and returning the final expression result register.

### `[ISSUE-241]` Argument Dropping in `Expr::MethodCall` Lowering in `src/cartanc/llvm_codegen.car`
- **Component**: `src/cartanc/llvm_codegen.car:3089-3135`
- **Description**: When lowering `Expr::MethodCall` for user-defined methods, `llvm_codegen.car` emits `call float @cartan_method_<name>(ptr clean_obj)` and completely drops the `args` tree, discarding all passed arguments. In addition, it checks `disc == 18.0 || disc == 29.0` instead of canonical line `82.0`.
- **Remediation**: Update discriminant check to `18.0 || 82.0`, evaluate all arguments in `args`, format them into the LLVM IR call parameter list, and pass them to the target method.

---

## 2. Logical Dependency Tree

```
Level 0: Core Specifications & Memory Models
  └── src/cartanc/ast.ch (Enum Expr, Enum Stmt, Enum CartanType, Memory Allocator)
       │
Level 1: Frontend Tokenizer & Runtime Primitives
  ├── src/cartanc/lexer.car (Token Stream Scanner, Keyword Lookup)
  └── src/cartanc/core_runtime.car (Strings, Trees, Tensors, Allocators, Math, Sandboxing)
       │
Level 2: Syntactic Analysis
  └── src/cartanc/parser.car (Recursive Descent Parser, AST Tree Builder)
       │
Level 3: Static Semantics & Type Inference
  └── src/cartanc/type_checker.car (Scope Stack, Symbol Table, Type Propagation)
       │
Level 4: AST Optimization
  └── src/cartanc/optimizer.car (Constant Folding, Variable Identity Reduction)
       │
Level 5: LLVM Machine Code Generation
  └── src/cartanc/llvm_codegen.car (LLVM 15+ IR Emission, Control Flow, C-ABI FFI)
       │
Level 6: Toolchain Driver
  └── src/cartanc/main.car (Compiler CLI, JIT Driver, LSP, Docgen, Bindgen)
       │
Level 7: Standard Library (`src/std/`)
  ├── Math, Geometry, Strings, Collections, File System, IO, Sockets, GPU Runtime
  └── AI Cognitive Substrates (Resonator, Hebbian, Transformer, Sleep, Multimodal)
       │
Level 8: Regression Test Harness
  └── test/compiler_suite/run_tests.car (66 Automated Empirical Snapshot Test Targets)
```

---

## 3. Zero-Mock & Verification Directives Compliance
- Standard library modules (`src/std/`) contain zero mock or stubbed calculations.
- Test suites (`test/compiler_suite/`) perform genuine analytical calculations.
- Rebuilding `cartanc.exe` and verifying through `build/run_tests.exe` (all targets) is required before sprint sign-off.
