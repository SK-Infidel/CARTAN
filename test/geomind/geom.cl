// src/std/geom.cl
// CARTAN Standard Library: Production-Grade 3D Spatial, Vector, Quaternion & Manifold Geometry Module

include "src/std/constants.ch";
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
    if (grad_tensor == 0.0 || velocity == 0.0 || drift_vector == 0.0) { return 0.0; }
    let dim = cartan_vec_len(grad_tensor);
    var norm_g_sq = 0.0;
    var dot_bv = 0.0;
    var i = 0.0;
    while (i < dim) {
        let g_val = cartan_vec_get_f32(grad_tensor, i);
        let v_val = cartan_vec_get_f32(velocity, i);
        let b_val = cartan_vec_get_f32(drift_vector, i);
        let sub_idx = math_mod_val(floor(i / 320.0), 8.0);
        let g_i = geom_killing_form_dynkin_weight(sub_idx);
        norm_g_sq = norm_g_sq + (g_val * g_val) * g_i;
        dot_bv = dot_bv + (b_val * v_val);
        i = i + 1.0;
    }
    let alpha = sqrt(norm_g_sq);
    return alpha - (dot_bv * lambda_mass_penalty);
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

fn geom_frs_adaptive_geodesic_clip(g_val: float, max_norm: float) -> float {
    let abs_g = math_abs_val(g_val);
    if (abs_g > max_norm) {
        var sign_g = 1.0;
        if (g_val < 0.0) { sign_g = -1.0; }
        return sign_g * max_norm;
    }

    return g_val;
}

fn geom_frs_riemannian_gradient_step(weight: float, g_val: float, drift_b: float, lr: float) -> float {
    // Sherman-Morrison dual inverse metric gradient update on Finsler-Randers manifolds:
    // g_randers = g - ((g . b) / (1 + ||b||^2)) * b
    let b_sq = drift_b * drift_b;
    let dot_gb = g_val * drift_b;
    let proj = (dot_gb / (1.0 + b_sq)) * drift_b;
    let g_randers = g_val - proj;
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

fn geom_cartan_parallel_transport(v_x: float, v_y: float, gamma_x: float, gamma_y: float, dt: float) -> float {
    // dv^i / dt = - \Gamma^i_{jk} v^j dx^k / dt
    let dv_x = (0.0 - gamma_x * v_x) * dt;
    return v_x + dv_x;
}

fn geom_riemannian_geodesic_distance(p1: ptr, p2: ptr, dim: float, metric_diag: ptr) -> float {
    if (p1 == 0.0 || p2 == 0.0 || dim <= 0.0) { return 0.0; }
    var sum_sq = 0.0;
    var i = 0.0;
    while (i < dim) {
        let diff = p2[i] - p1[i];
        var g_ii = 1.0;
        if (metric_diag != 0.0) {
            g_ii = metric_diag[i];
        }
        sum_sq = sum_sq + g_ii * diff * diff;
        i = i + 1.0;
    }
    return sqrt(sum_sq);
}

fn geom_christoffel_connection_step(v: ptr, gamma_diag: ptr, dim: float, dt: float) {
    if (v == 0.0 || gamma_diag == 0.0 || dim <= 0.0) { return; }
    var i = 0.0;
    while (i < dim) {
        let dv = (0.0 - gamma_diag[i] * v[i]) * dt;
        v[i] = v[i] + dv;
        i = i + 1.0;
    }
}

fn geom_riemannian_dot(v1: ptr, v2: ptr, metric_diag: ptr, dim: float) -> float {
    if (v1 == 0.0 || v2 == 0.0 || dim <= 0.0) { return 0.0; }
    var sum = 0.0;
    var i = 0.0;
    while (i < dim) {
        var g_i = 1.0;
        if (metric_diag != 0.0) { g_i = metric_diag[i]; }
        sum = sum + v1[i] * v2[i] * g_i;
        i = i + 1.0;
    }
    return sum;
}

fn geom_riemannian_norm(v: ptr, metric_diag: ptr, dim: float) -> float {
    return sqrt(geom_riemannian_dot(v, v, metric_diag, dim));
}

fn geom_finsler_randers_distance(x: ptr, y: ptr, drift_b: ptr, metric_diag: ptr, dim: float) -> float {
    if (x == 0.0 || y == 0.0 || dim <= 0.0) { return 0.0; }
    var norm_sq = 0.0;
    var drift_dot = 0.0;
    var i = 0.0;
    while (i < dim) {
        let diff = x[i] - y[i];
        var g_i = 1.0;
        if (metric_diag != 0.0) { g_i = metric_diag[i]; }
        norm_sq = norm_sq + diff * diff * g_i;
        if (drift_b != 0.0) {
            drift_dot = drift_dot + drift_b[i] * diff;
        }
        i = i + 1.0;
    }
    return sqrt(norm_sq) + drift_dot;
}

fn geom_sasaki_phase_space_distance(pos1: ptr, mom1: ptr, pos2: ptr, mom2: ptr, metric_diag: ptr, dim: float) -> float {
    if (pos1 == 0.0 || pos2 == 0.0 || dim <= 0.0) { return 0.0; }
    var sum_p = 0.0;
    var sum_m = 0.0;
    var cross_term = 0.0;
    var i = 0.0;
    while (i < dim) {
        let dp = pos2[i] - pos1[i];
        var dm = 0.0;
        if (mom1 != 0.0 && mom2 != 0.0) {
            dm = mom2[i] - mom1[i];
        }
        var g_i = 1.0;
        if (metric_diag != 0.0) { g_i = metric_diag[i]; }
        sum_p = sum_p + dp * dp * g_i;
        sum_m = sum_m + dm * dm * g_i;
        cross_term = cross_term + dp * dm * g_i;
        i = i + 1.0;
    }
    // Sasaki metric on TM with Christoffel coupling
    return sum_p + sum_m + 0.10 * cross_term;
}

fn geom_killing_form_dynkin_weight(submanifold_idx: float) -> float {
    // Dynkin index scaling across the 8 Lie submanifolds
    if (submanifold_idx == 0.0) { return 2.0; } // SO(16)
    if (submanifold_idx == 1.0) { return 3.0; } // E7 x SU(2)
    if (submanifold_idx == 2.0) { return 4.0; } // E6 x SU(3)
    if (submanifold_idx == 3.0) { return 1.0; } // SU(9)
    if (submanifold_idx == 4.0) { return 5.0; } // F4 x G2
    if (submanifold_idx == 5.0) { return 2.5; } // SO(10) x SU(4)
    if (submanifold_idx == 6.0) { return 1.5; } // SU(5) x SU(5)
    return 2.0;                                // SU(3)^3
}
