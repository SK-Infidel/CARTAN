# Deep Mathematical Implementation of E8 & Finsler-Randers

Now that the high-level structural shell of Aether natively compiles, the goal is to implement the **actual deep mathematical logic** of the manifolds directly inside `geomind.aether`. Because the old C++ `FinslerBackend::compute_e8_forward` was literally just a stub (`out->zero_()`), this will be the first time the theoretical physics are explicitly brought to life in code.

## User Review Required

> [!IMPORTANT]
> **No Existing Code to Port**: Since the C++ repository completely avoided writing the Finsler-Randers math and instead just returned zero arrays, I will be synthesizing the logic directly from your theoretical `.docx` paper. Please review the mathematical approach below before I commit it to Aether.

## Proposed Changes

### 1. `FinslerRandersMetric` Math
I have located the exact OpenCL mathematics inside `csrc/kernels.cl.h` (the Sherman-Morrison $G^{-1}$ inverse metric computation for the `finsler_geodesic_update`). 
Instead of a separate PyTorch optimizer, Aether's `autograd` natively infers the inverse metric of the defined space. We will define the explicit mathematical rules inside `struct FinslerRandersMetric`:
- **Chiral Drift Field ($b_i(x)$)**: We will map the `beta_coords` gradient adjustment $g_i - \frac{g \cdot \beta}{1 + \beta^2} \beta_i$ natively into the metric.
- **Mass Penalty Operator**: Apply the chiral mass penalty so that when the Aether compiler performs `@` geodesic transport, it inherently forces the 36 sequestered roots to remain localized and heavy.

### 2. `E8_Manifold` Lattice Construction
We will translate the core of `csrc/e8_topology.cpp` into a native Aether manifold constraint.
- **`d_E8_M` Tensor Basis**: Declare the 8x8 root lattice generator natively.
- **Gosset Lattice Projection**: Implement `fn project_to_lattice(x: tensor) -> tensor` using Aether primitives. We will enforce the exact topological rules:
  1. The D8 sub-lattice condition: Integer sum must be even.
  2. The half-integer sub-lattice condition: Sum of floors must be even.
  This allows Aether to naturally snap continuous trajectories back to discrete E8 coordinates.
- **Cartan Subalgebra Mapping**: A helper function to expand the 8D root vectors into the full 248-dimensional representation during Bilinear Fusion.

### 3. Modifications to `geomind.aether`
#### [MODIFY] [geomind.aether](file:///c:/Users/rich-/source/repos/GeoMind/aether/geomind.aether)
- Fleshing out `struct FinslerRandersMetric` with `fn evaluate_drift(velocity: tensor) -> tensor` and `fn compute_distance(x: tensor, y: tensor) -> float`.
- Fleshing out `struct E8_Manifold` with `fn project_to_lattice(coords: tensor) -> tensor`.
- Adding the `d_E8_M` matrix generator logic inside the manifold definition.

## Verification Plan

- Compile the math natively using `cargo run -- build-llvm c:\Users\rich-\source\repos\GeoMind\aether\geomind.aether`.
- Ensure the Aether Type Checker natively accepts the tensor matrix evaluations for the D8 constraints and float/int conversions.

---

# Phase 2: 8 Geometric Topologies (Internal Streams)

We are now ready to implement the unique mathematical logic for the 8 parallel geometric streams. The original C++ code relied on distinct `.cl` OpenCL kernels for each stream (e.g. `e8_cosformer_forward`). In Aether, we will construct these purely via geometric tensor structures.

## User Review Required

> [!IMPORTANT]
> Please review the strategy for migrating the 8 distinct streams into native Aether representations. Let me know if you want to focus heavily on a specific stream first (e.g., the SSM or Symplectic Triality).

## Proposed Changes

### Stream Matrix Migrations
We will define the inner mathematical behavior for the following `structs` inside `geomind.aether`:

1. **`CosformerStream`**:
   Replace the OpenCL tile-based linear attention kernel with a continuous Aether operation. We'll map the $\cos$ and $\sin$ feature mappings explicitly inside the Aether `tensor` evaluation to yield linear-time complexity natively.

2. **`SSMStream` (Lattice Wave Propagation)**:
   In C++, this required `e8_ssm.cpp`. In Aether, we will define the `A, B, C, D` state-space matrices bound directly to the E8 manifold to compute wave-fronts as a continuous difference equation.

3. **`SpectralStream` & `PoincareStream`**:
   We will define the spectral convolution logic and the Hyperbolic distance computations. For Poincaré space, the distance computation will utilize the Finsler-Randers metric with a negative curvature bound instead of flat Euclidean inner products.

4. **`HomologyStream` & `EikonalStream`**:
   The Eikonal Ray-Tracing will utilize the drift vector $b_i$ from our `FinslerRandersMetric` to "bend" the attention rays geometrically around the chiral mass penalties.

5. **`HeatKernelStream` & `TrialityStream`**:
   Define the Symplectic Triality transformations natively.

### Modifications to `geomind.aether`
#### [MODIFY] [geomind.aether](file:///c:/Users/rich-/source/repos/GeoMind/aether/geomind.aether)
- We will inject the specialized tensor math into the `fn forward()` blocks of all 8 stream structs.

## Verification Plan
- We will iteratively inject the mathematics for each stream and continuously compile the file using `cargo run -- build-llvm` to ensure Aether successfully digests the complex math down into valid LLVM IR without semantic type faults.

---

# Phase 3: E8 Magic Square MoE & Sasaki Brainstem

We will now implement the native Aether variants of the $4 \times 4$ Freudenthal Magic Square Experts and the `SasakiRouter`. In C++, this relied on OpenCL kernels `magic_square_moe_forward` and `sasaki_router_forward`. We will bring this into the native geometry.

## User Review Required

> [!IMPORTANT]
> The C++ implementation of `E8MagicSquareMoE` manually instantiated 16 distinct `MLP` objects. In Aether, I plan to declare these 16 algebraic sectors natively using a structural 2D array or explicitly declaring the $\mathbb{R, C, H, O}$ Cartesian products to enforce strict algebraic isolation. Does this approach align with your vision?

## Proposed Changes

### 1. `MagicSquareExpert` Array
We will expand the current single `expert_rr` (Reals x Reals) into the full 16-expert grid representing the Freudenthal Magic Square:
- `expert_rr, expert_rc, expert_rh, expert_ro`
- `expert_cr, expert_cc, expert_ch, expert_co`
- `expert_hr, expert_hc, expert_hh, expert_ho`
- `expert_or, expert_oc, expert_oh, expert_oo`

Each will be an isolated `MagicSquareExpert` struct anchored to the `E8_Manifold`.

### 2. `SasakiRouter` (Phase-Space Routing)
Instead of a standard softmax router over flat embeddings, the `SasakiRouter` must evaluate probabilities in the lifted Sasaki tangent bundle. 
- We will construct the mathematical evaluation `route(position, momentum)` to output a 16-dimensional continuous probability distribution mapped to the 16 experts.
- Aether's `@` metric evaluation will inherently calculate the geometric distances in phase-space to select the closest matching algebraic sector.

### Modifications to `geomind.aether`
#### [MODIFY] [geomind.aether](file:///c:/Users/rich-/source/repos/GeoMind/aether/geomind.aether)
- Instantiate the 16 `MagicSquareExpert` variants inside `E8MagicSquareMoE`.
- Implement `fn route` inside `SasakiRouter`.
- Update `fn execute_routing` to dynamically route the `fused_trajectory` (position) and `m_coupling` (momentum) into the appropriate expert mix.

## Verification Plan
- Compile `geomind.aether` using `cargo run -- build-llvm` to ensure the topological routing mathematics are safely parsed by Aether.
