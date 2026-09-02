// src/std/optim.ch
// CARTAN Standard Library: Finsler-Randers Non-Euclidean Riemannian Natural Gradient Header

extern fn geom_frs_adaptive_geodesic_clip(g_val: float, max_norm: float) -> float;
extern fn geom_frs_riemannian_gradient_step(weight: float, g_val: float, drift_b: float, lr: float) -> float;
extern fn geom_frs_exp_map_retract(weight: float, update: float) -> float;
