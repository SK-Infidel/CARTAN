# Sprint 356 Plan: Non-Euclidean Fusion & SLERP Architecture, Attention Metric Alignment & Clean Checkpoint Purge

## 1. Objectives & Context
- Eliminate all Euclidean math from the model weight merging pipeline (`--merge-slerp`).
- Endow all norm, inner product, and retraction routines in `src/std/fusion.cl` with the Killing-Cartan metric tensor $g_i = \text{geom\_killing\_form\_dynkin\_weight}(\lfloor i / 320 \rfloor \bmod 8)$ across the 8 Lie submanifolds.
- Replace Euclidean linear interpolation in `fusion_tangent_space_slerp` with authentic Riemannian geodesic SLERP.
- Align multi-head sliding window attention dot products in `test/geomind/e8_attention_engine.cl` and CPU backprop fallback in `test/geomind/train.cl` with non-Euclidean Killing form and Finsler-Randers geometry.
- Purge legacy contaminated checkpoints and manifest files.
- Recompile via `cartanc.exe`, synchronize binaries, and execute a fresh non-Euclidean merge.

## 2. Work Breakdown
1. **Fusion Library (`src/std/fusion.cl`)**:
   - `fusion_slerp_tensors`: Riemannian metric dot product, norms, and volume-preserving manifold rescaling.
   - `fusion_tangent_space_slerp`: Delegate to `fusion_slerp_tensors`.
   - `fusion_slerp_arrays`: Metric tensor weighted dot product and norms.
   - `fusion_riemannian_retraction`: Metric tensor weighted base/tangent norms and exponential map.
   - `fusion_knots_orthogonal_merge`: Metric tensor weighted Gram-Schmidt inner products and squared norms.
   - `fusion_riemannian_align`: Metric tensor weighted energy and scaling.
   - `fusion_riemannian_retract_arrays`: Metric tensor weighted norms and unit vectors.
2. **Attention & Geometry Modules**:
   - `test/geomind/e8_attention_engine.cl`: Killing form weights on multi-head attention dot product.
   - `test/geomind/train.cl`: Finsler-Randers geodesic projection on CPU gradient delta.
   - `src/std/geom.cl`: Killing form weights on `geomind_inverse_randers_backward_project`.
3. **Artifact Cleanup & Checkpoint Execution**:
   - Remove legacy contaminated checkpoints (`geomind_steady_state_weights.bin*`, `checkpoint_status.txt`, `cloze_manifest.json`).
   - Run `.\geomind.exe --merge-slerp` to create fresh baseline `geomind_slerp_fused_weights.bin`.
4. **Verification**:
   - Verify self-hosting compilation with 0 errors.
   - Verify binary sync across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
