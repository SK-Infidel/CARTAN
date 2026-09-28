# Sprint 446 Implementation Plan: Authentic Finsler-Randers Sherman-Morrison Optimization & WGSL Parametrization

## 1. Objectives
Eliminate synthetic sine drift vectors and hardcoded 320 Euclidean strides across differential geometry and training shaders. Fully activate authentic Sherman-Morrison cotangent gradient projection, enforce Randers strong convexity ($\|\mathbf{b}\|_g \le 0.50 < 1$), and implement dynamic WGSL shaders for continuous $E_8$ manifold training.

---

## 2. Technical Scope & Squad Alignments

### A. Dynamic Submanifold Strides & Sherman-Morrison Transform (`src/std/geom.cl`, `test/geomind/geom.cl`)
1. **Dynamic Stride Syntax (No Ternary)**:
   In `geomind_inverse_randers_backward_project`:
   ```cartan
   var stride = 31.0;
   if (dim >= 2560.0) {
       stride = 320.0;
   } else if (dim >= 1984.0) {
       stride = 248.0;
   } else if (dim > 0.0) {
       let calc = floor(dim / 8.0);
       if (calc >= 1.0) { stride = calc; }
   }
   let sub_idx = math_mod_val(floor(i / stride), 8.0);
   ```
2. **Sherman-Morrison Cotangent Gradient Transform**:
   Implement `geomind_inverse_randers_transform_grad(grad_ptr: ptr, drift_ptr: ptr, metric_ptr: ptr, out_grad_ptr: ptr) -> float`:
   - Compute full vector inner product reductions:
     $$\mathbf{g} \cdot \mathbf{b} = \sum_{i=0}^{\text{dim}-1} g_i b_i, \quad \|\mathbf{b}\|^2 = \sum_{i=0}^{\text{dim}-1} b_i^2$$
   - Rank-1 projection and background gauge drift shift:
     $$g_{\text{randers},i} = g_i - \left(\frac{\mathbf{g} \cdot \mathbf{b}}{1 + \|\mathbf{b}\|^2}\right) b_i - 0.10 \cdot (b_i \cdot m_i)$$
   - Compute output Riemannian norm $\|g_{\text{randers}}\|_M = \sqrt{\sum_i g_{\text{randers},i}^2 \cdot m_i}$.
   - Apply Adaptive Geodesic Clipping (AGC):
     $$\text{clip} = \min\left(1.0, \frac{1.0}{\|g_{\text{randers}}\|_M}\right)$$
   - Ensure destination length safeguard (`out_grad_ptr[0] = dim;`).

### B. Eliminate Synthetic Sine Drift in Training Pipeline (`test/geomind/train.cl`)
1. **Background Drift Gauge Initialization**:
   - In lines 466–475 and lines 931–942, eliminate `0.05 * sin(...) * kw`.
   - Initialize background drift $\mathbf{b}$ as normalized Cartan gauge field derived from Dynkin weights:
     $$b_i = 0.05 \cdot \frac{kw_i}{5.0}$$
   - Calculate $\|\mathbf{b}\|_g = \sqrt{\sum_i b_i^2 kw_i}$. If $\|\mathbf{b}\|_g > 0.50$, retract $\mathbf{b} \leftarrow \mathbf{b} \times \frac{0.50}{\|\mathbf{b}\|_g}$, guaranteeing the Randers strong convexity condition $\|\mathbf{b}\|_a < 1.0$.
2. **CPU Fallback Gradient Transformation**:
   - Use dynamic stride and call `geomind_inverse_randers_transform_grad` directly on `g_train_logits`.

### C. Parametrization of WebGPU WGSL Shaders (`test/geomind/train.cl`)
1. Update `webgpu_get_causal_attn_shader()`:
   - Parametrize dimension $D = 2560\text{u}$ and stride $S = D / 8\text{u}$.
   - Replace constant `17.88854f` with $\sqrt{S}$ (`sqrt(f32(S))`).
2. Update `webgpu_get_lie_streams_shader()`:
   - Dynamic per-stream bounds: stream $k$ loops from $k \times S$ to $(k + 1) \times S$.

### D. Dedicated Direct Test Coverage (QA Gate G1)
- Author `test/compiler_suite/test_finsler_randers.car` verifying:
  - Dynamic stride on 248D, 1984D, and 2560D.
  - Sherman-Morrison collinear damping ($\mathbf{g} \parallel \mathbf{b}$).
  - Orthogonal drift invariance ($\mathbf{g} \cdot \mathbf{b} = 0$).
  - Zero-drift baseline ($\mathbf{b} = \mathbf{0} \implies \mathbf{g}_{\text{randers}} = \mathbf{g}$).
  - AGC clipping for $\|g\|_M > 1.0$.
- Register in `test/compiler_suite/run_tests.car` as Target 65.

---

## 3. Verification Criteria & Empirical Gates
- [ ] **G1**: Dedicated test `test_finsler_randers.car` passes 100% with exit code 0.
- [ ] **G2**: Clean compilation of all modified files with `cartanc.exe` (Zig -O3 LTO).
- [ ] **G3**: Target 52 (`test_lie_streams.car`) and Target 64 (`test_hybrid_resonant_transformer.car`) pass cleanly.
- [ ] **G4**: Full compiler regression suite (`run_tests.exe`) passes with 0 assertion failures.
- [ ] **G5**: `build/geomind.exe --eval-analogy` executes cleanly with 0 NaNs and positive rank margins.
- [ ] **G6**: `build/geomind.exe --sleep` executes all 5 consolidation phases cleanly.
