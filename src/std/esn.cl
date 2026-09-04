// src/std/esn.cl
// CARTAN Standard Library: Reservoir Computing & Echo State Networks (ESNs) Implementation

include "src/std/math.cl";

extern fn cartan_vec_create() -> ptr;
extern fn cartan_vec_push_f32(v: ptr, val: float) -> float;
extern fn cartan_vec_get_f32(v: ptr, idx: float) -> float;
extern fn cartan_vec_set_f32(v: ptr, idx: float, val: float) -> float;
extern fn cartan_vec_len(v: ptr) -> float;

extern fn cartan_tree_create() -> ptr;
extern fn cartan_tree_push(t: ptr, item: ptr) -> void;
extern fn cartan_tree_get(t: ptr, idx: float) -> ptr;
extern fn cartan_tree_len_f(t: ptr) -> float;

// Deterministic pseudo-random generator for reservoir weight initialization
fn esn_pseudo_random(seed: float) -> float {
    let s = sin(seed * 37.119 + 63.472) * 54321.9876;
    let frac = s - floor(s);
    return (frac * 1.0) - 0.5;
}

// Solves linear matrix system A * X = B for X via Gaussian elimination with partial pivoting
fn esn_solve_linear_system(a_mat: ptr, b_mat: ptr, dim: float, cols: float) -> ptr {
    let n2 = dim * dim;
    let a = cartan_vec_create();
    var i = 0.0;
    while (i < n2) {
        cartan_vec_push_f32(a, cartan_vec_get_f32(a_mat, i));
        i = i + 1.0;
    }

    let b_total = dim * cols;
    let b = cartan_vec_create();
    i = 0.0;
    while (i < b_total) {
        cartan_vec_push_f32(b, cartan_vec_get_f32(b_mat, i));
        i = i + 1.0;
    }

    // Forward elimination with partial pivoting
    var p = 0.0;
    while (p < dim) {
        var max_row = p;
        var max_val = fabs(cartan_vec_get_f32(a, p * dim + p));
        var r = p + 1.0;
        while (r < dim) {
            let val = fabs(cartan_vec_get_f32(a, r * dim + p));
            if (val > max_val) {
                max_val = val;
                max_row = r;
            }
            r = r + 1.0;
        }

        if (max_row != p) {
            var c = 0.0;
            while (c < dim) {
                let idx1 = p * dim + c;
                let idx2 = max_row * dim + c;
                let tmp = cartan_vec_get_f32(a, idx1);
                cartan_vec_set_f32(a, idx1, cartan_vec_get_f32(a, idx2));
                cartan_vec_set_f32(a, idx2, tmp);
                c = c + 1.0;
            }
            c = 0.0;
            while (c < cols) {
                let idx1 = p * cols + c;
                let idx2 = max_row * cols + c;
                let tmp = cartan_vec_get_f32(b, idx1);
                cartan_vec_set_f32(b, idx1, cartan_vec_get_f32(b, idx2));
                cartan_vec_set_f32(b, idx2, tmp);
                c = c + 1.0;
            }
        }

        let pivot = cartan_vec_get_f32(a, p * dim + p);
        var safe_pivot = pivot;
        if (fabs(safe_pivot) < 0.000001) {
            if (safe_pivot >= 0.0) { safe_pivot = 0.000001; }
            else { safe_pivot = -0.000001; }
        }

        var row = p + 1.0;
        while (row < dim) {
            let factor = cartan_vec_get_f32(a, row * dim + p) / safe_pivot;
            var col = p;
            while (col < dim) {
                let cur = cartan_vec_get_f32(a, row * dim + col);
                let p_val = cartan_vec_get_f32(a, p * dim + col);
                cartan_vec_set_f32(a, row * dim + col, cur - (factor * p_val));
                col = col + 1.0;
            }
            col = 0.0;
            while (col < cols) {
                let cur_b = cartan_vec_get_f32(b, row * cols + col);
                let p_b = cartan_vec_get_f32(b, p * cols + col);
                cartan_vec_set_f32(b, row * cols + col, cur_b - (factor * p_b));
                col = col + 1.0;
            }
            row = row + 1.0;
        }

        p = p + 1.0;
    }

    // Back substitution
    let x = cartan_vec_create();
    i = 0.0;
    while (i < b_total) { cartan_vec_push_f32(x, 0.0); i = i + 1.0; }

    var back_row = dim - 1.0;
    while (back_row >= 0.0) {
        let diag = cartan_vec_get_f32(a, back_row * dim + back_row);
        var safe_diag = diag;
        if (fabs(safe_diag) < 0.000001) {
            if (safe_diag >= 0.0) { safe_diag = 0.000001; }
            else { safe_diag = -0.000001; }
        }

        var col_idx = 0.0;
        while (col_idx < cols) {
            var sum = cartan_vec_get_f32(b, back_row * cols + col_idx);
            var next_c = back_row + 1.0;
            while (next_c < dim) {
                let a_coef = cartan_vec_get_f32(a, back_row * dim + next_c);
                let x_val = cartan_vec_get_f32(x, next_c * cols + col_idx);
                sum = sum - (a_coef * x_val);
                next_c = next_c + 1.0;
            }
            cartan_vec_set_f32(x, back_row * cols + col_idx, sum / safe_diag);
            col_idx = col_idx + 1.0;
        }
        back_row = back_row - 1.0;
    }

    return x;
}

// Creates an authentic Echo State Network with input projection and recurrent reservoir matrix
fn esn_create_reservoir(input_dim: float, res_size: float, spectral_radius: float) -> ptr {
    let esn = cartan_tree_create();
    let meta = cartan_vec_create();
    cartan_vec_push_f32(meta, input_dim);
    cartan_vec_push_f32(meta, res_size);
    cartan_vec_push_f32(meta, spectral_radius);
    cartan_tree_push(esn, meta);

    // Initial reservoir state vector x(0): [res_size]
    let state_buffer = cartan_vec_create();
    var i = 0.0;
    while (i < res_size) {
        cartan_vec_push_f32(state_buffer, 0.0);
        i = i + 1.0;
    }
    cartan_tree_push(esn, state_buffer);

    // Input weight matrix W_in: [res_size * input_dim]
    let w_in = cartan_vec_create();
    let total_win = res_size * input_dim;
    i = 0.0;
    while (i < total_win) {
        cartan_vec_push_f32(w_in, esn_pseudo_random(i + 13.0));
        i = i + 1.0;
    }
    cartan_tree_push(esn, w_in);

    // Recurrent reservoir matrix W_res: [res_size * res_size] scaled to spectral_radius
    let w_res = cartan_vec_create();
    let total_wres = res_size * res_size;
    let norm_scale = spectral_radius / sqrt(res_size);
    i = 0.0;
    while (i < total_wres) {
        let r = esn_pseudo_random(i + 777.0);
        // Sparsity filter: keep ~50% non-zero connections
        var w_val = 0.0;
        if (fabs(r) > 0.15) {
            w_val = r * norm_scale;
        }
        cartan_vec_push_f32(w_res, w_val);
        i = i + 1.0;
    }
    cartan_tree_push(esn, w_res);

    return esn;
}

// Authentically updates reservoir state via x(t) = tanh(W_in * u(t) + W_res * x(t-1))
fn esn_step_forward(esn_ptr: ptr, input_vec: ptr) -> ptr {
    let meta = cartan_tree_get(esn_ptr, 0.0);
    let input_dim = cartan_vec_get_f32(meta, 0.0);
    let res_size = cartan_vec_get_f32(meta, 1.0);
    let prev_state = cartan_tree_get(esn_ptr, 1.0);
    let w_in = cartan_tree_get(esn_ptr, 2.0);
    let w_res = cartan_tree_get(esn_ptr, 3.0);

    let next_state = cartan_vec_create();

    var i = 0.0;
    while (i < res_size) {
        // Compute input excitation: sum_j W_in[i, j] * u_j
        var in_sum = 0.0;
        var j = 0.0;
        while (j < input_dim) {
            let u_val = cartan_vec_get_f32(input_vec, j);
            let w_val = cartan_vec_get_f32(w_in, i * input_dim + j);
            in_sum = in_sum + (u_val * w_val);
            j = j + 1.0;
        }

        // Compute recurrent reservoir excitation: sum_k W_res[i, k] * x_prev[k]
        var res_sum = 0.0;
        var k = 0.0;
        while (k < res_size) {
            let x_k = cartan_vec_get_f32(prev_state, k);
            let w_rk = cartan_vec_get_f32(w_res, i * res_size + k);
            res_sum = res_sum + (x_k * w_rk);
            k = k + 1.0;
        }

        // Update state with non-linear saturation
        let new_x = tanh(in_sum + res_sum);
        cartan_vec_push_f32(next_state, new_x);
        cartan_vec_set_f32(prev_state, i, new_x);
        i = i + 1.0;
    }

    return next_state;
}

// Authentically solves Ridge regression readout weights: W_out = (S^T * S + alpha * I)^-1 * S^T * Y
fn esn_solve_readout_ridge(state_matrix: ptr, target_matrix: ptr, alpha: float) -> ptr {
    let total_states = cartan_vec_len(state_matrix);
    let total_targets = cartan_vec_len(target_matrix);
    if (total_states <= 0.0 || total_targets <= 0.0) {
        return cartan_vec_create();
    }

    // Determine dimensionality: if scalar signals
    var num_samples = total_targets;
    var state_dim = total_states / num_samples;
    if (state_dim < 1.0) {
        state_dim = 1.0;
        num_samples = total_states;
    }
    let target_dim = total_targets / num_samples;

    // Form Gram matrix G = S^T * S + alpha * I: [state_dim x state_dim]
    let g_mat = cartan_vec_create();
    var r = 0.0;
    while (r < state_dim) {
        var c = 0.0;
        while (c < state_dim) {
            var g_sum = 0.0;
            var i = 0.0;
            while (i < num_samples) {
                let s_ir = cartan_vec_get_f32(state_matrix, i * state_dim + r);
                let s_ic = cartan_vec_get_f32(state_matrix, i * state_dim + c);
                g_sum = g_sum + (s_ir * s_ic);
                i = i + 1.0;
            }
            if (r == c) {
                g_sum = g_sum + alpha;
            }
            cartan_vec_push_f32(g_mat, g_sum);
            c = c + 1.0;
        }
        r = r + 1.0;
    }

    // Form right-hand side target projection T = S^T * Y: [state_dim x target_dim]
    let t_mat = cartan_vec_create();
    r = 0.0;
    while (r < state_dim) {
        var m = 0.0;
        while (m < target_dim) {
            var t_sum = 0.0;
            var i = 0.0;
            while (i < num_samples) {
                let s_ir = cartan_vec_get_f32(state_matrix, i * state_dim + r);
                let y_val = cartan_vec_get_f32(target_matrix, i * target_dim + m);
                t_sum = t_sum + (s_ir * y_val);
                i = i + 1.0;
            }
            cartan_vec_push_f32(t_mat, t_sum);
            m = m + 1.0;
        }
        r = r + 1.0;
    }

    // Solve (S^T * S + alpha * I) * W_out = S^T * Y
    let readout_w = esn_solve_linear_system(g_mat, t_mat, state_dim, target_dim);
    return readout_w;
}
