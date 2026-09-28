# Sprint 457 Implementation Plan: AST Variant Hardening, Statement Collision Rectification, Attention & Fused Kernel Codegen

## 1. Objectives & Scope
- **Objective**: Harden compiler AST integrity and codegen reliability by eliminating statement discriminant collisions (`[ISSUE-237]`), declaring missing AST variants (`[ISSUE-238]`), implementing full lowering and runtime for `@attention` (`[ISSUE-239]`), implementing `fused { ... }` kernel lowering (`[ISSUE-240]`), and resolving argument dropping in `MethodCall` lowering (`[ISSUE-241]`).
- **Target Regression**: Author Target 67 (`test/compiler_suite/test_attention_fused_methods.car`) verifying `@attention`, `fused {}`, method argument dispatch, and statement decl collision-free execution.
- **Verification Criterion**: 100% empirical pass on Target 67 and all 67 compiler suite targets via `build/run_tests.exe`.

---

## 2. Technical Architectural Plan

### Step 1: Statement Discriminant Collision Rectification (`[ISSUE-237]`)
- In `src/cartanc/llvm_codegen.car`:
  - `SequenceDecl`: replace `9.0 || 32.0` with `9.0 || 127.0` (unblocks `EvolveBlock` 32.0).
  - `BlockDecl`: replace `10.0 || 34.0` with `10.0 || 128.0` (unblocks `ImplDecl` 34.0).
  - `LatticeDecl`: replace `11.0 || 36.0` with `11.0 || 129.0` (unblocks `Spawn` 36.0).
  - `TreeDecl`: replace `12.0 || 39.0` with `12.0 || 130.0` (unblocks `JitBlock` 39.0).
  - `ExternFunctionDecl`: replace `15.0 || 48.0` with `15.0 || 133.0` (unblocks `MultimodalBlock` 48.0).
  - `Block`: replace `36.0 || 99.0` with `40.0 || 158.0` (unblocks `Spawn` 36.0).

### Step 2: AST Variant Declarations (`[ISSUE-238]`)
- In `src/cartanc/ast.ch:enum Expr`:
  - Append `SievingCacheInit`, `FractalAttentionInit`, `ElasticVocabularyInit`, `SpikePrimitive`, `NeuronPrimitive` with explicit discriminants.
  - In `src/cartanc/type_checker.car`: map them to `CartanType::Ptr` / `CartanType::Tensor`.
  - In `src/cartanc/llvm_codegen.car`: lower them cleanly or delegate to appropriate allocator/initializers.

### Step 3: Authentic `@attention` Primitives & Codegen (`[ISSUE-239]`)
- In `src/cartanc/core_runtime.car`:
  - Implement `cartan_attention(target: ptr, routing: ptr) -> ptr` computing routing-weighted attention projection across tensor dimension vectors.
  - Export top-level `attention(target: ptr, routing: ptr) -> ptr`.
- In `src/cartanc/type_checker.car`:
  - Add dual discriminant check for `Expr::Attention` (`27.0 || 91.0`) returning `CartanType::Tensor`.
- In `src/cartanc/llvm_codegen.car`:
  - Register `@cartan_attention` extern prototype and return type `ptr`.
  - Lower `Expr::Attention` calling `@cartan_attention(ptr clean_target, ptr clean_routing)`.

### Step 4: `fused { ... }` Kernel Codegen (`[ISSUE-240]`)
- In `src/cartanc/type_checker.car`:
  - Add dual discriminant check (`26.0 || 90.0`) for `Expr::FusedKernel`.
- In `src/cartanc/llvm_codegen.car`:
  - Lower `Expr::FusedKernel` by traversing inner block statements sequentially and returning the evaluation result of the final statement or expression.

### Step 5: `MethodCall` Full Parameter Dispatch (`[ISSUE-241]`)
- In `src/cartanc/llvm_codegen.car`:
  - Update `MethodCall` check to `18.0 || 82.0`.
  - Iterate through `args`, evaluate each expression, and format arguments into `call float @cartan_method_<name>(ptr clean_obj, ...)`.

---

## 3. Verification & DoD
- [ ] Self-hosted `cartanc.exe` builds cleanly with 0 errors.
- [ ] Target 67 (`test/compiler_suite/test_attention_fused_methods.car`) created and passing 100%.
- [ ] All 67 regression targets pass via `build/run_tests.exe`.
- [ ] `ISSUES.md` updated with `[FIXED]`.
- [ ] `CHANGELOG.md` updated for Release 8.415.0.
