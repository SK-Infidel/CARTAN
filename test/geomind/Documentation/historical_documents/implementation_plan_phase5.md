# Goal: Eradicate Deep-Rooted Euclidean Artifacts in C++ Engine

I performed a thorough code review of the C++ `csrc` backend. While the Python generation loop was fixed to use Geodesic Cosine similarity, the core C++ OpenCL kernels still heavily rely on flat Euclidean assumptions that directly violate the non-Euclidean Finsler geometry of the E8 manifold.

Here is what I found:

### 1. `SphericalNorm` Computes Flat L2 Norms
In `csrc/kernels.cl.h`, the `spherical_norm_inplace` kernel normalizes vectors by calculating their magnitude using a standard flat Euclidean dot product (`sum_sq += val * val; scalar_norm = sqrt(sum_sq)`). 
**Why this is incompatible:** In a Riemannian or Finsler manifold, vector magnitude must be computed with respect to the intrinsic metric tensor $G$, i.e., $||x||_G = \sqrt{x^T G x}$. Using a flat L2 norm warps the geometry by forcing the manifold back into a Euclidean hypersphere during every normalization layer.

### 2. `FinslerOptimizer` Uses Euclidean Tangent Projections
In `csrc/kernels.cl.h`, the `finsler_geodesic_update` kernel is responsible for updating the model weights along the manifold. However, it projects the velocity into the tangent space using a flat Euclidean dot product: `V_tan = V - (V \cdot W_{norm}) * W_{norm}`.
**Why this is incompatible:** Projecting velocity into a curved tangent space requires the metric tensor: $V_{tan} = V - \frac{G(V, W)}{G(W, W)} W$. Furthermore, while `csrc/optimizer.h` declares a `g_metric_` tensor to track the metric approximations, it is completely ignored in `optimizer.cpp`. We are mathematically failing to perform a true Riemannian optimization step.

### 3. `E8CosformerAttention` Uses Flat Dot Products
Attention logits are currently computed using standard dot products ($Q K^T$). 
**Why this is incompatible:** In an E8 manifold, if the space is non-Euclidean, computing similarity via a flat dot product ignores the curvature between tokens. There should be a metric tensor inserted into the similarity function ($Q G K^T$), or the attention should incorporate the Finsler distance directly.

## User Review Required

> [!WARNING]
> Implementing a true Finsler/E8 metric tensor $G$ across all normalizations, optimizers, and attention layers is a major architectural overhaul. 
> 
> We have the topological equations defined in `csrc/geomath.h` (e.g., `calculate_static_force_potential`, `Riemann Zeta Spectral Density`). 
> 
> **Question:** Should we implement a global dynamic metric tensor $G(x)$ that is passed into these kernels, or should we directly inject the closed-form E8 topological FRS curvature traces from `geomath.h` into the OpenCL kernel mathematical operations? 

## Proposed Changes

Depending on your feedback, the workflow will be:
1. **[MODIFY] `csrc/kernels.cl.h`**: Rewrite `spherical_norm_inplace` and `finsler_geodesic_update` to accept and utilize a metric tensor $G$ (or inline the E8 geometry equations) when calculating magnitudes and tangent space projections.
2. **[MODIFY] `csrc/optimizer.cpp` & `csrc/optimizer.h`**: Actually initialize and maintain the `g_metric_` tensor, updating it as the manifold curvature evolves, and pass it to the OpenCL kernels.
3. **[MODIFY] `csrc/modules.cpp`**: Update the `E8CosformerAttention` kernels to calculate metric-weighted similarities ($Q G K^T$) rather than flat inner products.

## Verification Plan
1. Recompile the C++ OpenCL engine with the metric-aware mathematical operations.
2. Run a training or forward pass step to ensure the new non-Euclidean constraints do not cause gradient explosion or NaN values, confirming the geometry is properly mapped.
