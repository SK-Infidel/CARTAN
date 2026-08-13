// src/std/optim.cl
// CARTAN Standard Library: Finsler-Randers Non-Euclidean Riemannian Natural Gradient Implementation

include "src/std/math.cl";
include "src/std/geom.cl";

fn optim_frs_gradient_step(weight: float, grad: float, drift_b: float, lr: float) -> float {
    return geom_frs_riemannian_gradient_step(weight, grad, drift_b, lr);
}

fn optim_frs_exp_map_retract(weight: float, update: float) -> float {
    return geom_frs_exp_map_retract(weight, update);
}

fn optim_frs_adaptive_geodesic_clip(grad: float, max_norm: float) -> float {
    return geom_frs_adaptive_geodesic_clip(grad, max_norm);
}
