# Phase 2 Complete: Shape-Safe Typing & Layout Modifiers

We have successfully finished the second major milestone on our roadmap. Cartan now natively protects against matrix dimension mismatches at compile-time and can accept hardware memory layouts directly in the syntax.

## What Changed

### 1. The `parameter` Keyword
We introduced the `parameter` type to the AST, separating pinned model weights from ephemeral intermediate calculation `tensor`s. 

### 2. The `layout` Modifier
We implemented the `layout` keyword in the parser and AST, giving users the ability to manually swizzle memory alignments to maximize L1 Cache hit rates or match Tensor Core grids.
- `layout(SoA)`: Structure-of-Arrays
- `layout(Tiled(x, y))`: Explicit grid layouts

### 3. Strict Compile-Time Shape Checking
We completely rewrote the Type Checker's logic for the `@` operator. Instead of blindly accepting any tensor, it now cracks open the AST metadata and mathematically verifies the inner and outer dimensions of both matrices. 

If you attempt to compile mathematically invalid dimensions, the compilation aborts *before* LLVM is ever invoked, completely neutralizing runtime shape mismatch errors.

```rust
// tests/shapes.ctn
fn main() {
    let A = tensor[2, 3];
    let W = parameter[4, 5];
    let mismatch = A @ W; // COMPILER ERROR: 3 != 4
}
```

## Verification

We wrote a test suite in [shapes.ctn](file:///C:/Users/rich-/source/repos/CARTAN/tests/shapes.ctn) containing valid and invalid matrix multiplications. The compiler successfully verified the valid 2D @ 2D and 1D @ 2D multiplications, and threw a fatal `Diagnostic` error on the invalid dimension mismatch exactly as requested.
