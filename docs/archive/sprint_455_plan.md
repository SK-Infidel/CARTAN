# Sprint 455 Plan: Tensor Transposition, Graph Hot-Swap, Pointer Ops & Authentic GEMM

## Mission & Objectives
Resolve technical debt issues `[ISSUE-229]`, `[ISSUE-230]`, `[ISSUE-231]`, and `[ISSUE-232]`:
1. Fix `Expr::Transpose` (38.0 / 102.0) lowering in `llvm_codegen.car` and eliminate dummy `return t;` in `src/std/tensor.cl`.
2. Fix `Cartan.hot_swap` parser discriminant check, type check `Expr::HotSwap` (39.0 / 103.0), and lower to `@cartan_rt_atomic_swap_graph`.
3. Add `Expr::AddressOf` (42.0 / 106.0) and `Expr::Dereference` (43.0 / 107.0) to `type_checker.car` and fix outdated line discriminants in `llvm_codegen.car`.
4. Implement authentic GEMM matrix multiplication `cartan_tensor_matmul(A, B, M, K, N)` in `core_runtime.car` and replace mock element-wise multiplication in `src/std/tensor.cl:tensor_matmul`.
5. Author regression Target 65 (`test/compiler_suite/test_tensor_and_pointer_ops.car`) and verify 100% clean compilation and execution across all 65 targets.

---

## Logical Dependency Tree
```
  [ast.ch] (Expr::Transpose, HotSwap, AddressOf, Dereference)
     │
     ├──> [parser.car] (Allow 6.0/70.0 for Identifier in Cartan.hot_swap)
     │
     ├──> [type_checker.car] (Dual discriminants for Transpose, HotSwap, AddressOf, Dereference)
     │
     ├──> [llvm_codegen.car] (Lower Transpose to @cartan_tensor_transpose, HotSwap to @cartan_rt_atomic_swap_graph, fix AddressOf/Dereference)
     │
     ├──> [core_runtime.car] (Authentic cartan_tensor_matmul GEMM algorithm)
     │
     ├──> [src/std/tensor.cl] (tensor_matmul -> authentic GEMM, tensor_transpose -> cartan_tensor_transpose)
     │
     └──> [test/compiler_suite/test_tensor_and_pointer_ops.car] (Target 65 verification)
```

---

## Technical Specifications & Architecture

### 1. `Expr::Transpose` (`[ISSUE-229]`)
- In `type_checker.car:470`, check `disc == 38.0 || disc == 102.0`.
- In `llvm_codegen.car:llvm_visit_expr`:
  - Match `disc == 38.0 || disc == 102.0`.
  - Emit call to `@cartan_tensor_transpose(arg)`.
- In `src/std/tensor.cl:254`:
  - Replace `return t;` with `return cartan_tensor_transpose(t);`.

### 2. `Expr::HotSwap` (`[ISSUE-230]`)
- In `parser.car:1702`:
  - Check `expr[0] == 6.0 || expr[0] == 70.0`.
- In `type_checker.car:493`:
  - Check `disc == 39.0 || disc == 103.0`, returning `CartanType::Ptr`.
- In `llvm_codegen.car:llvm_visit_expr`:
  - Match `disc == 39.0 || disc == 103.0`.
  - Emit call to `@cartan_rt_atomic_swap_graph(target, new_graph)`.

### 3. Pointer Operations (`[ISSUE-231]`)
- In `type_checker.car:tc_visit_expr`:
  - Handle `disc == 42.0 || disc == 106.0` (`AddressOf`) -> Return `CartanType::Ptr`.
  - Handle `disc == 43.0 || disc == 107.0` (`Dereference`) -> Return `CartanType::Float` / dereferenced type.
- In `llvm_codegen.car:3290` & `3302`:
  - Update `AddressOf` check to `disc == 42.0 || disc == 106.0`.
  - Update `Dereference` check to `disc == 43.0 || disc == 107.0`.

### 4. Authentic GEMM Matrix Multiplication (`[ISSUE-232]`)
- In `src/cartanc/core_runtime.car`:
  - Implement `cartan_tensor_matmul(A: ptr, B: ptr, M: float, K: float, N: float) -> ptr` executing authentic 3-loop tiled/standard blocked matrix multiplication $C_{i,j} = \sum_k A_{i,k} \cdot B_{k,j}$.
  - Expose top-level `matmul(A, B, M, K, N)`.
- In `src/std/tensor.cl:240`:
  - Replace mock loop with authentic GEMM logic or direct delegation.
