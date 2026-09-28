# Sprint 452 Implementation Plan: Transform, Weight Decay, Satisfy/Backtrack, & Freestanding ONNX

## 1. Objectives
- Implement `@cartan_internal_import_onnx` in freestanding `src/cartanc/core_runtime.car` (`[ISSUE-217]`).
- Enable higher-order tensor transforms `vmap(target)` and `grad(target)` via `Expr::Transform` across type checking, LLVM codegen, and `core_runtime.car` (`[ISSUE-218]`).
- Implement $L_2$ weight regularization `weight_decay(target, amount)` via `Expr::WeightDecay` across type checking, LLVM codegen, and `core_runtime.car` (`[ISSUE-219]`).
- Restore declarative constraint solving by wiring `satisfy <cond> { ... } otherwise { ... }` and `backtrack;` in AST, parser, type checker, and runtime (`[ISSUE-220]`).
- Author regression Target 62 (`test/compiler_suite/test_transforms_and_logic.car`) and verify 62/62 targets pass with 0 failures.

---

## 2. Technical Design & Architecture

### A. Runtime Extensions (`src/cartanc/core_runtime.car`)
1. **`cartan_internal_import_onnx(uri: string) -> ptr`**:
   Allocates a model graph node containing URI string, tensor weight hash dictionary, and boolean file presence flag.
2. **`cartan_rt_transform(op: string, target: ptr) -> ptr`**:
   Dispatches based on `op`:
   - `"grad"`: Allocates gradient adjoint tensor scaled with genuine sensitivity coefficients.
   - `"vmap"`: Expands batch dimension across the input tensor.
   - Default: Duplicates tensor elements.
3. **`cartan_tensor_apply_weight_decay(t: ptr, amount: float) -> ptr`**:
   In-place regularizer multiplying each tensor float by $(1.0 - \text{amount})$.

### B. AST & Parser Integration (`src/cartanc/ast.ch`, `src/cartanc/parser.car`)
1. In `ast.ch`: Update `Satisfy(ptr)` to `Satisfy(ptr, ptr, ptr)` (condition, body, otherwise_block).
2. In `parser.car:1289`: Return `Stmt::Satisfy(condition, body, otherwise_node)` instead of `Stmt::Placeholder`.

### C. Type Checker Integration (`src/cartanc/type_checker.car`)
1. In `tc_visit_stmt`: Handle `disc == 56.0 || disc == 119.0` (`Satisfy`) with scoped traversal of body and otherwise blocks, and `disc == 57.0 || disc == 120.0` (`Backtrack`).
2. In `tc_visit_expr`: Handle `disc == 40.0 || disc == 104.0` (`Transform`) and `disc == 49.0 || disc == 113.0` (`WeightDecay`) returning target type.

### D. LLVM Codegen Lowering (`src/cartanc/llvm_codegen.car`)
1. Register `cartan_rt_transform`, `cartan_tensor_apply_weight_decay`, and `cartan_internal_import_onnx` in `func_return_types`.
2. Add prototype for `cartan_tensor_apply_weight_decay(ptr, double)`.
3. In `llvm_visit_expr`:
   - Lower `Transform` (`disc == 40.0 || disc == 104.0`) to `@cartan_rt_transform(ptr op, ptr target)`.
   - Lower `WeightDecay` (`disc == 49.0 || disc == 113.0`) to `@cartan_tensor_apply_weight_decay(ptr target, double amount)`.
4. Note that `Satisfy` (`disc == 56.0 || disc == 119.0`) and `Backtrack` (`disc == 57.0 || disc == 120.0`) are already fully implemented in `llvm_codegen.car:1894-1949`.
