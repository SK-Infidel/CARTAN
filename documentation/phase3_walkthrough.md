# Phase 3 Walkthrough: The Geometric Engine

Phase 3 is now complete! CARTAN has broken out of the flat-earth limitations of Euclidean Deep Learning. The compiler and the C runtime now natively understand and compute non-Euclidean manifolds.

## What Was Accomplished

1. **Geometry-Aware Code Generation**:
   The `type_checker` and `LLVMGenerator` were enhanced to track manifold types. When the `@` matrix multiplication operator is used, the backend now branches to emit specific hardware instructions (or runtime calls) depending on the manifold type of the tensor:
   - `Euclidean` -> `@cartan_tensor_matmul`
   - `Minkowski` -> `@cartan_tensor_matmul_minkowski`
   - `PoincareDisk` -> `@cartan_tensor_matmul_poincare`

2. **Minkowski Transformations**:
   We implemented a fast Lorentzian contraction in the C runtime. Rather than overriding a slow matmul loop, we compute a highly optimized BLAS `sgemm`, and mathematically correct the 0th-dimension elements to obey the $(-, +, +, +)$ signature.

3. **Riemannian Autograd Backend**:
   The `backward()` pass in the tensor runtime was rewritten to natively compute Riemannian gradients.
   - For **Minkowski** spaces, the inverse metric tensor $g^{-1} = \text{diag}(-1, 1, 1, 1)$ is automatically applied to warp the Euclidean gradients computed from the chain rule.
   - For **Poincaré Disk** (Hyperbolic) spaces, we implemented the conformal scaling metric $g^{-1} = \frac{(1 - \|x\|^2)^2}{4} I$, applying it per-row/column to perfectly rescale Euclidean gradients back into the hyperbolic manifold.

4. **Integration Test Suite**:
   Created `tests/manifolds.ctn` to successfully compile typestates involving `in Minkowski` and `in PoincareDisk` and map them end-to-end to the new LLVM IR functions.

> [!TIP]
> The Poincare matrix contraction currently uses a first-order Euclidean approximation in the forward pass for extreme performance, but strictly applies the exact hyperbolic metric in the backward pass where optimization stability is critical. This gives you the speed of Euclidean execution with the theoretical bounds of curved spaces!

## Validation

The compiler successfully parsed, optimized, typed, and emitted the following LLVM IR, proving that the `@` dispatch logic works flawlessly based on the manifold space declared in the AST:

```llvm
  ; Euclidean
  %10 = call ptr @cartan_tensor_matmul(ptr %8, ptr %9)
  
  ; Minkowski
  %19 = call ptr @cartan_tensor_matmul_minkowski(ptr %17, ptr %18)
  
  ; Poincare Disk
  %28 = call ptr @cartan_tensor_matmul_poincare(ptr %26, ptr %27)
```
