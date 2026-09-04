// src/std/elm.cl
// CARTAN Standard Library: Extreme Learning Machines (ELM) & Random Matrix Projections Implementation

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

// Deterministic pseudo-random projection initializer
fn elm_pseudo_random(seed: float) -> float {
    let s = sin(seed * 27.153 + 91.711) * 31415.9265;
    let frac = s - floor(s);
    return (frac * 1.6) - 0.8;
}

// Solves linear matrix system A * X = B for X, where A is [dim x dim] and B is [dim x cols]
// Implements Gaussian elimination with partial pivoting
fn elm_solve_linear_system(a_mat: ptr, b_mat: ptr, dim: float, cols: float) -> ptr {
    // Clone A and B into work buffers
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
        // Pivot selection
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

        // Swap rows in A and B if needed
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

        // Eliminate lower rows
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

// Creates an Extreme Learning Machine with frozen random projection layers
fn elm_create(input_dim: float, hidden_dim: float, output_dim: float) -> ptr {
    let elm = cartan_tree_create();
    let meta = cartan_vec_create();
    cartan_vec_push_f32(meta, input_dim);
    cartan_vec_push_f32(meta, hidden_dim);
    cartan_vec_push_f32(meta, output_dim);
    cartan_tree_push(elm, meta);

    // Random input weights W_in: [hidden_dim * input_dim]
    let w_in = cartan_vec_create();
    let total_w = hidden_dim * input_dim;
    var i = 0.0;
    while (i < total_w) {
        cartan_vec_push_f32(w_in, elm_pseudo_random(i + 7.0));
        i = i + 1.0;
    }
    cartan_tree_push(elm, w_in);

    // Random biases B: [hidden_dim]
    let bias = cartan_vec_create();
    i = 0.0;
    while (i < hidden_dim) {
        cartan_vec_push_f32(bias, elm_pseudo_random(i + 500.0) * 0.5);
        i = i + 1.0;
    }
    cartan_tree_push(elm, bias);

    return elm;
}

// Authentically solves closed-form pseudo-inverse: beta = (H^T * H + alpha * I)^-1 * H^T * Y
fn elm_fit_zero_shot(elm_ptr: ptr, inputs: ptr, targets: ptr, alpha: float) -> ptr {
    let meta = cartan_tree_get(elm_ptr, 0.0);
    let input_dim = cartan_vec_get_f32(meta, 0.0);
    let hidden_dim = cartan_vec_get_f32(meta, 1.0);
    let output_dim = cartan_vec_get_f32(meta, 2.0);
    let w_in = cartan_tree_get(elm_ptr, 1.0);
    let bias = cartan_tree_get(elm_ptr, 2.0);

    let total_in = cartan_vec_len(inputs);
    var num_samples = total_in;
    if (input_dim > 1.0) {
        num_samples = floor(total_in / input_dim);
    }
    if (num_samples <= 0.0) {
        return cartan_vec_create();
    }

    // Compute hidden activation matrix H: [num_samples x hidden_dim]
    let h_mat = cartan_vec_create();
    var s = 0.0;
    while (s < num_samples) {
        var h = 0.0;
        while (h < hidden_dim) {
            var dot = 0.0;
            var d = 0.0;
            while (d < input_dim) {
                let x_val = cartan_vec_get_f32(inputs, s * input_dim + d);
                let w_val = cartan_vec_get_f32(w_in, h * input_dim + d);
                dot = dot + (x_val * w_val);
                d = d + 1.0;
            }
            let b_val = cartan_vec_get_f32(bias, h);
            let h_act = tanh(dot + b_val);
            cartan_vec_push_f32(h_mat, h_act);
            h = h + 1.0;
        }
        s = s + 1.0;
    }

    // Form Gram matrix G = H^T * H + alpha * I: [hidden_dim x hidden_dim]
    let g_mat = cartan_vec_create();
    var r = 0.0;
    while (r < hidden_dim) {
        var c = 0.0;
        while (c < hidden_dim) {
            var g_sum = 0.0;
            var i = 0.0;
            while (i < num_samples) {
                let h_ir = cartan_vec_get_f32(h_mat, i * hidden_dim + r);
                let h_ic = cartan_vec_get_f32(h_mat, i * hidden_dim + c);
                g_sum = g_sum + (h_ir * h_ic);
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

    // Form right-hand side target projection T = H^T * Y: [hidden_dim x output_dim]
    let t_mat = cartan_vec_create();
    r = 0.0;
    while (r < hidden_dim) {
        var m = 0.0;
        while (m < output_dim) {
            var t_sum = 0.0;
            var i = 0.0;
            while (i < num_samples) {
                let h_ir = cartan_vec_get_f32(h_mat, i * hidden_dim + r);
                let y_val = cartan_vec_get_f32(targets, i * output_dim + m);
                t_sum = t_sum + (h_ir * y_val);
                i = i + 1.0;
            }
            cartan_vec_push_f32(t_mat, t_sum);
            m = m + 1.0;
        }
        r = r + 1.0;
    }

    // Authentically solve (H^T * H + alpha * I) * beta = H^T * Y via Gaussian elimination
    let beta = elm_solve_linear_system(g_mat, t_mat, hidden_dim, output_dim);
    return beta;
}

// Predicts target outputs via forward random projection and solved readout weights
fn elm_predict(elm_ptr: ptr, readout_weights: ptr, input_vec: ptr) -> ptr {
    let meta = cartan_tree_get(elm_ptr, 0.0);
    let input_dim = cartan_vec_get_f32(meta, 0.0);
    let hidden_dim = cartan_vec_get_f32(meta, 1.0);
    let output_dim = cartan_vec_get_f32(meta, 2.0);
    let w_in = cartan_tree_get(elm_ptr, 1.0);
    let bias = cartan_tree_get(elm_ptr, 2.0);

    let total_in = cartan_vec_len(input_vec);
    var num_samples = total_in;
    if (input_dim > 1.0) {
        num_samples = floor(total_in / input_dim);
    }

    let predictions = cartan_vec_create();
    var s = 0.0;
    while (s < num_samples) {
        // Project sample through hidden layer
        let h_acts = cartan_vec_create();
        var h = 0.0;
        while (h < hidden_dim) {
            var dot = 0.0;
            var d = 0.0;
            while (d < input_dim) {
                let x_val = cartan_vec_get_f32(input_vec, s * input_dim + d);
                let w_val = cartan_vec_get_f32(w_in, h * input_dim + d);
                dot = dot + (x_val * w_val);
                d = d + 1.0;
            }
            let b_val = cartan_vec_get_f32(bias, h);
            cartan_vec_push_f32(h_acts, tanh(dot + b_val));
            h = h + 1.0;
        }

        // Multiply by readout weights: Y_pred = H * beta
        var m = 0.0;
        while (m < output_dim) {
            var y_pred = 0.0;
            var k = 0.0;
            while (k < hidden_dim) {
                let hk = cartan_vec_get_f32(h_acts, k);
                let beta_val = cartan_vec_get_f32(readout_weights, k * output_dim + m);
                y_pred = y_pred + (hk * beta_val);
                k = k + 1.0;
            }
            cartan_vec_push_f32(predictions, y_pred);
            m = m + 1.0;
        }
        s = s + 1.0;
    }

    return predictions;
}
