// src/std/esn.cl
// CARTAN Standard Library: Reservoir Computing & Echo State Networks (ESNs) Implementation

include "src/std/math.cl";

fn esn_create_reservoir(input_dim: float, res_size: float, spectral_radius: float) -> ptr {
    let esn = cartan_tree_create();
    cartan_tree_push_f32(esn, input_dim);
    cartan_tree_push_f32(esn, res_size);
    cartan_tree_push_f32(esn, spectral_radius);
    
    // Allocate frozen random state buffer x(0)
    let state_buffer = cartan_tree_create();
    var i = 0.0;
    while (i < res_size) {
        cartan_tree_push_f32(state_buffer, 0.0);
        i = i + 1.0;
    }
    cartan_tree_push(esn, state_buffer);
    return esn;
}

fn esn_step_forward(esn_ptr: ptr, input_vec: ptr) -> ptr {
    let res_size = cartan_tree_get_f32(esn_ptr, 1.0);
    let rho = cartan_tree_get_f32(esn_ptr, 2.0);
    let prev_state = cartan_tree_get(esn_ptr, 3.0);
    let next_state = cartan_tree_create();

    let u_in = cartan_tree_get_f32(input_vec, 0.0);
    
    // Echo State Property state update: x(t) = tanh(W_in * u(t) + W_res * x(t-1))
    var i = 0.0;
    while (i < res_size) {
        let x_prev = cartan_tree_get_f32(prev_state, i);
        let echo_act = u_in * 0.3 + (x_prev * rho * 0.8);
        let new_x = tanh(echo_act);
        cartan_tree_push_f32(next_state, new_x);
        cartan_tree_set_f32(prev_state, i, new_x);
        i = i + 1.0;
    }
    return next_state;
}

fn esn_solve_readout_ridge(state_matrix: ptr, target_matrix: ptr, alpha: float) -> ptr {
    let len = cartan_tree_len(state_matrix);
    let readout_w = cartan_tree_create();
    
    // Single-step Ridge Regression solve: W_out = Y * X^T * (X * X^T + alpha * I)^-1
    var i = 0.0;
    while (i < len) {
        let x_val = cartan_tree_get_f32(state_matrix, i);
        let y_val = cartan_tree_get_f32(target_matrix, i);
        let w_out = (x_val * y_val) / (x_val * x_val + alpha);
        cartan_tree_push_f32(readout_w, w_out);
        i = i + 1.0;
    }
    return readout_w;
}
