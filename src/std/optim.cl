// src/std/optim.cl
// CARTAN Standard Library: Finsler-Randers Non-Euclidean Riemannian Natural Gradient Implementation

include "src/std/math.cl";
include "src/std/geom.cl";

fn optim_frs_gradient_step(weight: float, g_val: float, drift_b: float, lr: float) -> float {
    return geom_frs_riemannian_gradient_step(weight, g_val, drift_b, lr);
}

fn optim_frs_exp_map_retract(weight: float, update: float) -> float {
    return geom_frs_exp_map_retract(weight, update);
}

fn optim_frs_adaptive_geodesic_clip(g_val: float, max_norm: float) -> float {
    return geom_frs_adaptive_geodesic_clip(g_val, max_norm);
}

fn optim_adamw_step(w: float, grad: float, m: float, v: float, beta1: float, beta2: float, eps: float, lr: float, weight_decay: float) -> float {
    let decay_w = w * (1.0 - lr * weight_decay);
    let next_m = beta1 * m + (1.0 - beta1) * grad;
    let next_v = beta2 * v + (1.0 - beta2) * grad * grad;
    let denom = sqrt(next_v) + eps;
    let step = (lr * next_m) / denom;
    return decay_w - step;
}

fn optim_riemannian_momentum_step(w: float, grad: float, vel: float, beta: float, lr: float, drift_b: float) -> float {
    let next_vel = beta * vel + (1.0 - beta) * grad;
    return geom_frs_riemannian_gradient_step(w, next_vel, drift_b, lr);
}

fn optim_learning_rate_cosine_decay(initial_lr: float, min_lr: float, current_step: float, total_steps: float) -> float {
    if (total_steps <= 0.0) { return initial_lr; }
    if (current_step >= total_steps) { return min_lr; }
    let progress = current_step / total_steps;
    let cos_val = cos(progress * 3.141592653589793);
    return min_lr + 0.5 * (initial_lr - min_lr) * (1.0 + cos_val);
}

fn optim_learning_rate_linear_warmup(target_lr: float, warmup_steps: float, current_step: float) -> float {
    if (warmup_steps <= 0.0 || current_step >= warmup_steps) { return target_lr; }
    return target_lr * (current_step / warmup_steps);
}

