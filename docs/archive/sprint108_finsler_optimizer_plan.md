# Pre-Sprint Plan: Sprint 108 — Finsler-Randers Non-Euclidean Riemannian Natural Gradient Optimizer

**Sprint Goal:** Implement the non-Euclidean Finsler-Randers Riemannian Natural Gradient Optimizer in `src/std/geom.car` and `test/geomind/sft_train.car`, incorporating Sherman-Morrison dual inverse metric updates, Adaptive Geodesic Gradient Clipping (AGC), and Exponential Map Retractions.  
**Date:** August 11, 2026  
**Archive File:** `docs/archive/sprint108_finsler_optimizer_plan.md`  

---

## I. Architectural Components

1. **Sherman-Morrison Dual Inverse Metric Gradient Update (`geom_frs_riemannian_gradient_step`)**:
   - Evaluates anisotropic Randers dual metric gradient $\mathbf{g}_{\text{randers}} = \mathbf{g} - \left(\frac{\mathbf{g} \cdot \mathbf{b}}{1 + \|\mathbf{b}\|^2}\right) \mathbf{b}$ on Finsler metric spaces $F(x, v) = \sqrt{a_{ij}v^i v^j} + b_i v^i \cdot \lambda$.
2. **Adaptive Geodesic Gradient Clipping (`geom_frs_adaptive_geodesic_clip`)**:
   - Clips tangent gradient norms along non-Euclidean geodesics to prevent manifold curvature divergence.
3. **Exponential Map Retraction (`geom_frs_exp_map_retract`)**:
   - Maps tangent update vectors back onto the hyperspherical manifold norm $\text{Exp}_W(v) = W \cos(\|v\|) + \frac{v}{\|v\|} \sin(\|v\|)$.

---

## II. Execution & Verification Steps
1. Add `geom_frs_riemannian_gradient_step`, `geom_frs_adaptive_geodesic_clip`, and `geom_frs_exp_map_retract` to `src/std/geom.car`.
2. Update `test/geomind/sft_train.car` to execute Finsler-Randers natural gradient backpasses.
3. Rebuild `cartanc.exe` release compiler binary and native `geomind.exe`.
4. Run regression suite (`run_geomind_all_modes.exe` & `geomind.exe --train-sft`) with exit status 0.
