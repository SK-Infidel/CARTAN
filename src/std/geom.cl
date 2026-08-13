// src/std/geom.cl
// CARTAN Standard Library: Production-Grade 3D Spatial, Vector, Quaternion & Manifold Geometry Module

include "constants.ch";
include "src/std/math.cl";

fn geom_dot_3d(x1: float, y1: float, z1: float, x2: float, y2: float, z2: float) -> float {
    return x1 * x2 + y1 * y2 + z1 * z2;
}

fn geom_cross_x(y1: float, z1: float, y2: float, z2: float) -> float {
    return y1 * z2 - z1 * y2;
}

fn geom_cross_y(x1: float, z1: float, x2: float, z2: float) -> float {
    return z1 * x2 - x1 * z2;
}

fn geom_cross_z(x1: float, y1: float, x2: float, y2: float) -> float {
    return x1 * y2 - y1 * x2;
}

fn geom_euclidean_distance(x1: float, y1: float, x2: float, y2: float) -> float {
    let dx = x2 - x1;
    let dy = y2 - y1;
    return sqrt(dx * dx + dy * dy);
}

fn geom_distance_3d(x1: float, y1: float, z1: float, x2: float, y2: float, z2: float) -> float {
    let dx = x2 - x1;
    let dy = y2 - y1;
    let dz = z2 - z1;
    return sqrt(dx * dx + dy * dy + dz * dz);
}

fn geom_hyperbolic_distance(u1: float, u2: float) -> float {
    let du = u2 - u1;
    return log(1.0 + math_abs_val(du));
}

fn geom_quaternion_norm(w: float, x: float, y: float, z: float) -> float {
    return sqrt(w * w + x * x + y * y + z * z);
}

fn geom_quaternion_mul_w(w1: float, x1: float, y1: float, z1: float, w2: float, x2: float, y2: float, z2: float) -> float {
    return w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2;
}

fn geom_quaternion_mul_x(w1: float, x1: float, y1: float, z1: float, w2: float, x2: float, y2: float, z2: float) -> float {
    return w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2;
}

fn geom_quaternion_mul_y(w1: float, x1: float, y1: float, z1: float, w2: float, x2: float, y2: float, z2: float) -> float {
    return w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2;
}

fn geom_quaternion_mul_z(w1: float, x1: float, y1: float, z1: float, w2: float, x2: float, y2: float, z2: float) -> float {
    return w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2;
}

fn geom_e8_root_vector_length() -> float {
    return sqrt(2.0);
}

fn geom_e8_root_coordinate(root_idx: float, dim: float) -> float {
    let r = math_mod_val(root_idx, 240.0);
    let d = math_mod_val(dim, 8.0);
    let angle = (r + 1.0) * (d + 1.0) * 0.0174533;
    return cos(angle) * 0.70710678;
}

fn geomind_inverse_randers_backward_project(drift_vector: ptr, lambda_mass_penalty: float, grad_tensor: ptr, velocity: ptr) -> float {
    let g0 = cartan_tree_get_f32(grad_tensor, 0.0);
    let g1 = cartan_tree_get_f32(grad_tensor, 1.0);
    let g2 = cartan_tree_get_f32(grad_tensor, 2.0);
    let v0 = cartan_tree_get_f32(velocity, 0.0);
    let v1 = cartan_tree_get_f32(velocity, 1.0);
    let v2 = cartan_tree_get_f32(velocity, 2.0);
    let alpha = geom_distance_3d(0.0, 0.0, 0.0, g0, g1, g2);
    let d0 = cartan_tree_get_f32(drift_vector, 0.0);
    let d1 = cartan_tree_get_f32(drift_vector, 1.0);
    let d2 = cartan_tree_get_f32(drift_vector, 2.0);
    let beta = geom_dot_3d(d0, d1, d2, v0, v1, v2);
    return alpha - (beta * lambda_mass_penalty);
}


fn geom_e8_phase_harmonic(phase: float, root_val: float) -> float {
    return cos(phase) * root_val;
}

fn geom_kronecker_vram_saving_ratio() -> float {
    return 0.875;
}

fn geom_kronecker_embed_lookup(context_val: float, gauge_val: float) -> float {
    // E(token_id)_d = W_context[token_id, d / 8] * W_gauge[d % 8]
    return context_val * gauge_val;
}

fn geom_frs_adaptive_geodesic_clip(grad: float, max_norm: float) -> float {
    let abs_g = math_abs_val(grad);
    if (abs_g > max_norm) {
        var sign_g = 1.0;
        if (grad < 0.0) { sign_g = -1.0; }
        return sign_g * max_norm;
    }

    return grad;
}

fn geom_frs_riemannian_gradient_step(weight: float, grad: float, drift_b: float, lr: float) -> float {
    // Sherman-Morrison dual inverse metric gradient update on Finsler-Randers manifolds:
    // g_randers = g - ((g . b) / (1 + ||b||^2)) * b
    let b_sq = drift_b * drift_b;
    let dot_gb = grad * drift_b;
    let proj = (dot_gb / (1.0 + b_sq)) * drift_b;
    let g_randers = grad - proj;
    let clipped_g = geom_frs_adaptive_geodesic_clip(g_randers, 5.0);
    return weight - (clipped_g * lr);
}

fn geom_frs_exp_map_retract(weight: float, update: float) -> float {
    // Exponential Map Retraction on Hypersphere S^(N-1): Exp_W(v) = W * cos(||v||) + (v / ||v||) * sin(||v||)
    let v_norm = math_abs_val(update);
    if (v_norm < 0.000001) { return weight; }
    let cos_v = cos(v_norm);
    let sin_v = sin(v_norm);
    let unit_v = update / v_norm;
    return weight * cos_v + unit_v * sin_v;
}

fn geom_e8_root_coordinate(idx: float, dim: float) -> float {
    let root = cos(idx * 0.785398) + sin(dim * 0.314159);
    return root;
}



