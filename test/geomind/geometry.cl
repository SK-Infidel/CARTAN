// test/geomind/geometry.cl
// GeoMind Production-Grade Lie Group E8 & Finsler-Randers-Sasaki (FRS) Geometry Engine

include "../../src/std/geom.cl";
include "../../src/std/math.cl";
include "../../src/std/collections.cl";

// Persistent global table of the 240 canonical E8 roots (240 vectors x 8 dimensions = 1920 floats)
var g_e8_roots_table: ptr = 0.0;
var g_e8_roots_initialized: float = 0.0;

// Initialize the 240 canonical E8 root vectors in R^8
// Length of every root vector is exactly sqrt(2), so ||alpha||^2 = 2.0
fn geomind_init_e8_roots_if_needed() -> float {
    if (g_e8_roots_initialized == 1.0 && g_e8_roots_table != 0.0) {
        return 240.0;
    }

    g_e8_roots_table = cartan_vec_create();
    var total_entries = 240.0 * 8.0;
    var idx = 0.0;
    while (idx < total_entries) {
        cartan_vec_push_f32(g_e8_roots_table, 0.0);
        idx = idx + 1.0;
    }

    var root_count = 0.0;

    // 1. Type A: 112 Integer Roots (+/- e_i +/- e_j for 0 <= i < j < 8)
    // 28 pairs x 4 sign permutations = 112 roots
    var i = 0.0;
    while (i < 8.0) {
        var j = i + 1.0;
        while (j < 8.0) {
            // Sign combination 1: (+1, +1)
            let base0 = root_count * 8.0;
            cartan_vec_set_f32(g_e8_roots_table, base0 + i, 1.0);
            cartan_vec_set_f32(g_e8_roots_table, base0 + j, 1.0);
            root_count = root_count + 1.0;

            // Sign combination 2: (+1, -1)
            let base1 = root_count * 8.0;
            cartan_vec_set_f32(g_e8_roots_table, base1 + i, 1.0);
            cartan_vec_set_f32(g_e8_roots_table, base1 + j, -1.0);
            root_count = root_count + 1.0;

            // Sign combination 3: (-1, +1)
            let base2 = root_count * 8.0;
            cartan_vec_set_f32(g_e8_roots_table, base2 + i, -1.0);
            cartan_vec_set_f32(g_e8_roots_table, base2 + j, 1.0);
            root_count = root_count + 1.0;

            // Sign combination 4: (-1, -1)
            let base3 = root_count * 8.0;
            cartan_vec_set_f32(g_e8_roots_table, base3 + i, -1.0);
            cartan_vec_set_f32(g_e8_roots_table, base3 + j, -1.0);
            root_count = root_count + 1.0;

            j = j + 1.0;
        }
        i = i + 1.0;
    }

    // 2. Type B: 128 Half-Integer Roots ((+/- 1/2)^8 with even number of minus signs)
    // 2^8 / 2 = 128 roots
    var mask = 0.0;
    while (mask < 256.0) {
        var minus_count = 0.0;
        var b = 0.0;
        while (b < 8.0) {
            let p2 = pow(2.0, b);
            let bit = math_mod_val(floor(mask / p2), 2.0);
            if (bit == 1.0) {
                minus_count = minus_count + 1.0;
            }
            b = b + 1.0;
        }

        // Even number of minus signs condition (sum of coordinates is an even integer)
        if (math_mod_val(minus_count, 2.0) == 0.0) {
            let base_b = root_count * 8.0;
            b = 0.0;
            while (b < 8.0) {
                let p2 = pow(2.0, b);
                let bit = math_mod_val(floor(mask / p2), 2.0);
                var val = 0.5;
                if (bit == 1.0) { val = -0.5; }
                cartan_vec_set_f32(g_e8_roots_table, base_b + b, val);
                b = b + 1.0;
            }
            root_count = root_count + 1.0;
        }
        mask = mask + 1.0;
    }

    g_e8_roots_initialized = 1.0;
    return root_count;
}

// Get coordinate d of root index r (r in 0..239, d in 0..7)
fn geomind_e8_get_root_coord(root_idx: float, dim: float) -> float {
    geomind_init_e8_roots_if_needed();
    let r = math_mod_val(root_idx, 240.0);
    let d = math_mod_val(dim, 8.0);
    return cartan_vec_get_f32(g_e8_roots_table, r * 8.0 + d);
}

// Inner product between two E8 roots: <alpha, beta> in {-2, -1, 0, 1, 2}
fn geomind_e8_root_dot(root_a: float, root_b: float) -> float {
    geomind_init_e8_roots_if_needed();
    let r_a = math_mod_val(root_a, 240.0) * 8.0;
    let r_b = math_mod_val(root_b, 240.0) * 8.0;
    var dot = 0.0;
    var d = 0.0;
    while (d < 8.0) {
        let va = cartan_vec_get_f32(g_e8_roots_table, r_a + d);
        let vb = cartan_vec_get_f32(g_e8_roots_table, r_b + d);
        dot = dot + va * vb;
        d = d + 1.0;
    }
    return dot;
}

// Squared norm of E8 root: strictly 2.0
fn geomind_e8_root_norm_sq(root_idx: float) -> float {
    return geomind_e8_root_dot(root_idx, root_idx);
}

// Weyl Group Reflection Operator: s_alpha(v) = v - <v, alpha> * alpha
// Transforms vector v in R^8 by reflection across root hyperplane orthogonal to root_idx
fn geomind_weyl_reflect(v_in: ptr, root_idx: float, v_out: ptr) -> float {
    if (v_in == 0.0 || v_out == 0.0) { return 0.0; }
    geomind_init_e8_roots_if_needed();
    let r_base = math_mod_val(root_idx, 240.0) * 8.0;

    // Compute inner product <v, alpha>
    var dot_va = 0.0;
    var d = 0.0;
    while (d < 8.0) {
        let v_d = cartan_vec_get_f32(v_in, d);
        let alpha_d = cartan_vec_get_f32(g_e8_roots_table, r_base + d);
        dot_va = dot_va + v_d * alpha_d;
        d = d + 1.0;
    }

    // Apply reflection: s_alpha(v)_d = v_d - <v, alpha> * alpha_d
    d = 0.0;
    while (d < 8.0) {
        let v_d = cartan_vec_get_f32(v_in, d);
        let alpha_d = cartan_vec_get_f32(g_e8_roots_table, r_base + d);
        cartan_vec_set_f32(v_out, d, v_d - dot_va * alpha_d);
        d = d + 1.0;
    }
    return dot_va;
}

// Full 248D E8 Weyl Group Root Reflection Operator: s_alpha(v) = v - <v, alpha> * alpha
// Transforms vector v across all 31 Cartan octaves in-place; exactly norm-preserving on S^247
fn geomind_weyl_reflect_vector_248(v: ptr, root_idx: float) -> ptr {
    if (v == 0.0) { return v; }
    geomind_init_e8_roots_if_needed();
    let r_base = math_mod_val(root_idx, 240.0) * 8.0;
    let v_len = cartan_vec_len(v);
    let octaves = floor(v_len / 8.0);
    
    var oct = 0.0;
    while (oct < octaves) {
        let base = oct * 8.0;
        var dot = 0.0;
        var d = 0.0;
        while (d < 8.0) {
            let vd = cartan_vec_get_f32(v, base + d);
            let ad = cartan_vec_get_f32(g_e8_roots_table, r_base + d);
            dot = dot + vd * ad;
            d = d + 1.0;
        }
        d = 0.0;
        while (d < 8.0) {
            let vd = cartan_vec_get_f32(v, base + d);
            let ad = cartan_vec_get_f32(g_e8_roots_table, r_base + d);
            cartan_vec_set_f32(v, base + d, vd - dot * ad);
            d = d + 1.0;
        }
        oct = oct + 1.0;
    }
    return v;
}

// Project 8D Cartan subalgebra coordinate state into complete 248D E8 Lie algebra space:
// Dims 0..7: Cartan subalgebra coordinates h
// Dims 8..247: Adjoint root space projection amplitudes <h, alpha_r> for r in 0..239
fn geomind_project_cartan_to_e8_248(cartan_8d: ptr, out_248d: ptr) -> float {
    if (cartan_8d == 0.0 || out_248d == 0.0) { return 0.0; }
    geomind_init_e8_roots_if_needed();

    // 1. Copy 8 Cartan subalgebra coordinates
    var d = 0.0;
    while (d < 8.0) {
        let val = cartan_vec_get_f32(cartan_8d, d);
        cartan_vec_set_f32(out_248d, d, val);
        d = d + 1.0;
    }

    // 2. Compute 240 root space projection amplitudes
    var r = 0.0;
    while (r < 240.0) {
        let r_base = r * 8.0;
        var dot = 0.0;
        d = 0.0;
        while (d < 8.0) {
            let h_d = cartan_vec_get_f32(cartan_8d, d);
            let alpha_d = cartan_vec_get_f32(g_e8_roots_table, r_base + d);
            dot = dot + h_d * alpha_d;
            d = d + 1.0;
        }
        // Amplitude in root space g_alpha
        cartan_vec_set_f32(out_248d, 8.0 + r, dot);
        r = r + 1.0;
    }
    return 248.0;
}

// Backward compatibility bridge for lattice root coordinate projection
fn geomind_project_to_e8_lattice(idx: float, dim: float) -> float {
    return geomind_e8_get_root_coord(idx, dim);
}

// ============================================================================
// FINSLER-RANDERS-SASAKI (FRS) BRAINSTEM ROUTER ENGINE
// ============================================================================
// Computes asymmetric Finsler-Randers phase-space geodesic distance on TM:
// F_FRS((x, x_dot), (y, y_dot)) = sqrt(g_Sasaki((x, x_dot), (y, y_dot))) + beta_drift(x - y)
// where:
// g_Sasaki = sum_d g_d * (x_d - y_d)^2 + sum_d g_d * (x_dot_d - y_dot_d)^2 + 2 * sum_d Gamma_d * (x_d - y_d)*(x_dot_d - y_dot_d)
// beta_drift = sum_d b_d * (x_d - y_d)
fn geomind_frs_brainstem_distance(
    pos1: ptr, mom1: ptr,
    pos2: ptr, mom2: ptr,
    drift_b: ptr,
    dim: float
) -> float {
    if (pos1 == 0.0 || pos2 == 0.0 || dim <= 0.0) { return 0.0; }

    var sum_pos_sq = 0.0;
    var sum_mom_sq = 0.0;
    var sum_cross = 0.0;
    var sum_drift = 0.0;

    var d = 0.0;
    while (d < dim) {
        let p1 = cartan_vec_get_f32(pos1, d);
        let p2 = cartan_vec_get_f32(pos2, d);
        let dp = p1 - p2;

        var dm = 0.0;
        if (mom1 != 0.0 && mom2 != 0.0) {
            let m1 = cartan_vec_get_f32(mom1, d);
            let m2 = cartan_vec_get_f32(mom2, d);
            dm = m1 - m2;
        }

        // Submanifold Killing-Cartan Dynkin weight g_d across dynamic Lie sectors
        var stride = 31.0;
        if (dim >= 2560.0) { stride = 320.0; }
        else if (dim >= 1984.0) { stride = 248.0; }
        let sub_idx = math_mod_val(floor(d / stride), 8.0);
        let g_d = geom_killing_form_dynkin_weight(sub_idx);

        sum_pos_sq = sum_pos_sq + g_d * dp * dp;
        sum_mom_sq = sum_mom_sq + g_d * dm * dm;
        sum_cross = sum_cross + 0.10 * g_d * dp * dm;

        if (drift_b != 0.0) {
            let b_d = cartan_vec_get_f32(drift_b, d);
            sum_drift = sum_drift + b_d * dp;
        }

        d = d + 1.0;
    }

    let sasaki_sq = sum_pos_sq + sum_mom_sq + sum_cross;
    var alpha = 0.0;
    if (sasaki_sq > 0.0) {
        alpha = sqrt(sasaki_sq);
    }

    // FRS asymmetric metric: alpha (Riemannian-Sasaki norm) + beta (Randers drift 1-form)
    let frs_dist = alpha + sum_drift;
    if (frs_dist < 0.0) { return 0.0; }
    return frs_dist;
}

// Persistent static scratch buffers for FRS Brainstem Router
var g_frs_stream_weights: ptr = 0.0;
var g_frs_stream_logits: ptr = 0.0;

// FRS Brainstem 8-Stream Routing: Dispatches incoming phase-space packet (x, x_dot)
// across the 8 Lie stream submanifolds with continuous velocity and drift steering
fn geomind_frs_stream_routing(position: ptr, momentum: ptr, temp: float) -> ptr {
    if (g_frs_stream_weights == 0.0) {
        g_frs_stream_weights = cartan_vec_create();
        g_frs_stream_logits = cartan_vec_create();
        var init_s = 0.0;
        while (init_s < 8.0) {
            cartan_vec_push_f32(g_frs_stream_weights, 0.125);
            cartan_vec_push_f32(g_frs_stream_logits, 0.0);
            init_s = init_s + 1.0;
        }
    }
    if (position == 0.0) {
        var s = 0.0;
        while (s < 8.0) {
            cartan_vec_set_f32(g_frs_stream_weights, s, 0.125);
            s = s + 1.0;
        }
        return g_frs_stream_weights;
    }

    var t = 0.70;
    if (temp > 0.05) { t = temp; }
    let plen = cartan_vec_len(position);
    var max_logit = -1000000.0;

    var stride = 31.0;
    if (plen >= 2560.0) { stride = 320.0; }
    else if (plen >= 1984.0) { stride = 248.0; }

    var s = 0.0;
    while (s < 8.0) {
        let start_d = s * stride;
        let kw = geom_killing_form_dynkin_weight(s);
        var pos_sq = 0.0;
        var mom_sq = 0.0;
        var dot_prod = 0.0;
        var drift_val = 0.0;

        var d = 0.0;
        while (d < stride && (start_d + d) < plen) {
            let p = cartan_vec_get_f32(position, start_d + d);
            var m = 0.0;
            if (momentum != 0.0 && (start_d + d) < cartan_vec_len(momentum)) {
                m = cartan_vec_get_f32(momentum, start_d + d);
            }
            pos_sq = pos_sq + (p * p) * kw;
            mom_sq = mom_sq + (m * m) * kw;
            dot_prod = dot_prod + (p * m) * kw;
            // Randers causal drift: asymmetric preference along active velocity gradient
            drift_val = drift_val + 0.05 * m;
            d = d + 1.0;
        }

        let sasaki_energy = (pos_sq + mom_sq) / stride;
        let norm_prod = sqrt(pos_sq * mom_sq);
        var alignment = 0.0;
        if (norm_prod > 0.0000001) {
            alignment = dot_prod / norm_prod;
        }

        // FRS routing logit: Sasaki kinetic energy + velocity alignment + Randers directional drift
        let logit = sqrt(sasaki_energy) + alignment + drift_val;
        cartan_vec_set_f32(g_frs_stream_logits, s, logit);
        if (logit > max_logit) { max_logit = logit; }
        s = s + 1.0;
    }

    // Numerically stable softmax with temperature t
    var sum_exp = 0.0;
    s = 0.0;
    while (s < 8.0) {
        let l_val = cartan_vec_get_f32(g_frs_stream_logits, s);
        let exp_val = exp((l_val - max_logit) / t);
        cartan_vec_set_f32(g_frs_stream_weights, s, exp_val);
        sum_exp = sum_exp + exp_val;
        s = s + 1.0;
    }
    if (sum_exp > 0.0) {
        let inv_sum = 1.0 / sum_exp;
        s = 0.0;
        while (s < 8.0) {
            let cur = cartan_vec_get_f32(g_frs_stream_weights, s);
            cartan_vec_set_f32(g_frs_stream_weights, s, cur * inv_sum);
            s = s + 1.0;
        }
    }
    return g_frs_stream_weights;
}
