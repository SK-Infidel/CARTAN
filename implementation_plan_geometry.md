
# Goal: Advanced Geometric and Algebraic Constructs

Introduce native syntax and compiler support for defining arbitrary manifolds (like Finsler-Randers-Sasaki) and Lie algebras (like E8) directly within CARTAN, allowing tensors to operate natively on these custom spaces without external C++/Rust extensions.

## User Review Required
> [!IMPORTANT]
> To support arbitrary geometric and algebraic spaces, we must extend the grammar. Does the proposed syntax below accurately represent how you would prefer to declare custom geometries (Manifolds) and symmetries (Lie Groups)?

## Open Questions
1. When defining lie_group E8, should we natively support abstract algebraic representations (e.g., lattice generation), or should it strictly focus on the Lie bracket [x, y] and exponential mappings for tensor operations?
2. How should operations on tensors located in two *different* custom manifolds interact? (Should we enforce strict separation, or require a transition map?)

## Proposed Changes

### 1. Lexer & Tokens
- **Keywords**: Add lie_group, lgebra, inverse_metric, geodesic, racket, exp.

### 2. AST Extensions
- **st.rs**: 
  - Extend ManifoldSpace enum to include Custom(String).
  - Add Stmt::ManifoldDecl to define custom metrics, geodesics, and inverse metrics.
  - Add Stmt::LieGroupDecl to define Lie bracket operations and exponential maps.

### 3. Parser & Grammar
#### Proposed Syntax for Manifold:
`cartan
manifold FinslerRandersSasaki {
    dim 4;

    // Define the inverse metric tensor g^{ij} applied to gradients during backprop
    inverse_metric(grad, x) {
        var alpha = sqrt(x * a * x);
        var beta = b * x;
        return grad / (alpha + beta); // Simplified Randers example
    }
}
`

#### Proposed Syntax for Lie Group:
`cartan
lie_group E8 {
    dim 248;

    // Lie Bracket [A, B]
    bracket(a, b) {
        return (a * b) - (b * a);
    }

    // Exponential map from Lie algebra to Lie group
    exp(v) {
        // ...
    }
}
`

### 4. Compiler CodeGen & Runtime
- **llvm_codegen.rs**: 
  - Parse ManifoldDecl and emit LLVM IR functions corresponding to the inverse_metric and racket.
  - When a Stmt::Backward happens on a tensor in a Custom(String) manifold, inject a call to the custom inverse metric hook to map gradients correctly.
- **	ensor_runtime/src/lib.rs**:
  - Expose function pointers dynamically so custom manifolds defined in CARTAN script can hook into the global cartan_tensor_backward C loop.

## Verification Plan
### Automated Tests
- Create 	ests/geometry.ctn to define a custom manifold, allocate a tensor within it, and perform a forward and backward pass to verify the custom metric affects the gradients.

