# GeoMind v3 Port: Deep Math Execution

- `[x]` **Implement `FinslerRandersMetric`**
  - `[x]` Define native vectorized tensor computation for the Sherman-Morrison gradient update ($g_i - \frac{g \cdot \beta}{1 + \beta^2} \beta_i$).
  - `[x]` Define the distance evaluation $F(x, y) = \alpha(x, y) + \beta(x, y)$.
- `[x]` **Implement `E8_Manifold` Constraints**
  - `[x]` Write vectorized `project_to_lattice` using Aether `math.round` and `sum` primitives instead of C++ loops.
  - `[x]` Add the `d_E8_M` root generator matrix natively.
- `[x]` **Verification**
  - `[x]` Verify semantic parsing against Aether compiler (`cargo run -- build-llvm`).

---

# Phase 2: 8 Geometric Topologies Execution

- `[x]` **Implement `CosformerStream` & `SSMStream`**
  - `[x]` Define $\cos$ and $\sin$ feature mappings for Cosformer.
  - `[x]` Define `A, B, C, D` state-space matrices for Lattice Wave SSM.
- `[x]` **Implement `SpectralStream` & `PoincareStream`**
  - `[x]` Define spectral convolution primitives.
  - `[x]` Define Hyperbolic distance bindings for Poincaré space.
- `[x]` **Implement `HomologyStream` & `EikonalStream`**
  - `[x]` Hook Eikonal Ray-Tracing into the $b_i$ drift vector for topological bending.
- `[x]` **Implement `HeatKernelStream` & `TrialityStream`**
  - `[x]` Define Symplectic Triality mixer transforms.
- `[x]` **Verification**
  - `[x]` Iteratively compile `geomind.aether` down to LLVM IR to ensure syntax and mathematical graphing remains sound.
