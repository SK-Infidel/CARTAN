// src/std/dip.cl
// CARTAN Standard Library: Untrained Network Inductive Biases (Deep Image Prior) Implementation

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

// Deterministic pseudo-random parameter generator
fn dip_pseudo_random(seed: float) -> float {
    let s = sin(seed * 12.9898 + 78.233) * 43758.5453;
    let frac = s - floor(s);
    return (frac * 0.8) - 0.4;
}

// Creates an untrained parameterized neural network with inductive spectral bias
fn dip_create_prior_network(input_channels: float, hidden_channels: float) -> ptr {
    let dip = cartan_tree_create();
    let meta = cartan_vec_create();
    cartan_vec_push_f32(meta, input_channels);
    cartan_vec_push_f32(meta, hidden_channels);
    cartan_vec_push_f32(meta, 0.0); // b2
    cartan_tree_push(dip, meta); // 0: meta

    // Layer 1 weights: [hidden_channels * input_channels]
    let w1 = cartan_vec_create();
    let total_w1 = hidden_channels * input_channels;
    var i = 0.0;
    while (i < total_w1) {
        let r = dip_pseudo_random(i + 1.0);
        cartan_vec_push_f32(w1, r);
        i = i + 1.0;
    }
    cartan_tree_push(dip, w1); // 1: w1

    // Layer 1 biases: [hidden_channels]
    let b1 = cartan_vec_create();
    i = 0.0;
    while (i < hidden_channels) {
        cartan_vec_push_f32(b1, 0.0);
        i = i + 1.0;
    }
    cartan_tree_push(dip, b1); // 2: b1

    // Layer 2 weights: [hidden_channels]
    let w2 = cartan_vec_create();
    i = 0.0;
    while (i < hidden_channels) {
        let r = dip_pseudo_random(i + 100.0);
        cartan_vec_push_f32(w2, r);
        i = i + 1.0;
    }
    cartan_tree_push(dip, w2); // 3: w2

    return dip;
}

// Reconstructs corrupted signal via authentic gradient descent optimization over untrained network parameters
fn dip_reconstruct_signal(dip_ptr: ptr, corrupted_signal: ptr, max_iters: float) -> ptr {
    let len = cartan_vec_len(corrupted_signal);
    let reconstructed = cartan_vec_create();
    if (len <= 0.0) { return reconstructed; }

    let meta = cartan_tree_get(dip_ptr, 0.0);
    let input_channels = cartan_vec_get_f32(meta, 0.0);
    let hidden_channels = cartan_vec_get_f32(meta, 1.0);
    var b2 = cartan_vec_get_f32(meta, 2.0);

    let w1 = cartan_tree_get(dip_ptr, 1.0);
    let b1 = cartan_tree_get(dip_ptr, 2.0);
    let w2 = cartan_tree_get(dip_ptr, 3.0);

    // Gradient descent parameters
    let iters = math_clamp(max_iters, 1.0, 50.0);
    let lr = 0.06;
    let inv_len = 2.0 / len;

    // Iterative optimization loop: min_theta || f_theta(z) - y ||^2
    var iter = 0.0;
    while (iter < iters) {
        // Gradient buffers
        let grad_w1 = cartan_vec_create();
        let total_w1 = hidden_channels * input_channels;
        var gi = 0.0;
        while (gi < total_w1) { cartan_vec_push_f32(grad_w1, 0.0); gi = gi + 1.0; }

        let grad_b1 = cartan_vec_create();
        gi = 0.0;
        while (gi < hidden_channels) { cartan_vec_push_f32(grad_b1, 0.0); gi = gi + 1.0; }

        let grad_w2 = cartan_vec_create();
        gi = 0.0;
        while (gi < hidden_channels) { cartan_vec_push_f32(grad_w2, 0.0); gi = gi + 1.0; }

        var grad_b2 = 0.0;

        // Forward and backward passes across all sample coordinates
        var i = 0.0;
        while (i < len) {
            let y_target = cartan_vec_get_f32(corrupted_signal, i);

            // Continuous positional encoding z_i = [sin(2*pi*i/L), cos(2*pi*i/L)]
            let theta = 6.2831853 * (i / len);
            let z0 = sin(theta);
            let z1 = cos(theta);

            // Forward pass: hidden layer activations
            var y_pred = b2;
            let h_acts = cartan_vec_create();
            var j = 0.0;
            while (j < hidden_channels) {
                let w1_0 = cartan_vec_get_f32(w1, j * 2.0);
                let w1_1 = cartan_vec_get_f32(w1, j * 2.0 + 1.0);
                let bj = cartan_vec_get_f32(b1, j);
                let pre_act = (w1_0 * z0) + (w1_1 * z1) + bj;
                let hj = tanh(pre_act);
                cartan_vec_push_f32(h_acts, hj);

                let w2_j = cartan_vec_get_f32(w2, j);
                y_pred = y_pred + (w2_j * hj);
                j = j + 1.0;
            }

            // Error signal
            let err = y_pred - y_target;
            let d_loss = err * inv_len;

            grad_b2 = grad_b2 + d_loss;

            // Backward pass: gradients for Layer 2 and Layer 1
            j = 0.0;
            while (j < hidden_channels) {
                let hj = cartan_vec_get_f32(h_acts, j);
                let cur_gw2 = cartan_vec_get_f32(grad_w2, j);
                cartan_vec_set_f32(grad_w2, j, cur_gw2 + (d_loss * hj));

                // Backprop through tanh: d/da = (1 - h^2)
                let w2_j = cartan_vec_get_f32(w2, j);
                let delta_j = d_loss * w2_j * (1.0 - (hj * hj));

                let cur_gb1 = cartan_vec_get_f32(grad_b1, j);
                cartan_vec_set_f32(grad_b1, j, cur_gb1 + delta_j);

                let idx0 = j * 2.0;
                let idx1 = idx0 + 1.0;
                let cur_gw1_0 = cartan_vec_get_f32(grad_w1, idx0);
                let cur_gw1_1 = cartan_vec_get_f32(grad_w1, idx1);
                cartan_vec_set_f32(grad_w1, idx0, cur_gw1_0 + (delta_j * z0));
                cartan_vec_set_f32(grad_w1, idx1, cur_gw1_1 + (delta_j * z1));

                j = j + 1.0;
            }

            i = i + 1.0;
        }

        // Apply parameter updates: theta = theta - lr * grad
        b2 = b2 - (lr * grad_b2);
        cartan_vec_set_f32(meta, 2.0, b2);

        var k = 0.0;
        while (k < hidden_channels) {
            let old_w2 = cartan_vec_get_f32(w2, k);
            let gw2 = cartan_vec_get_f32(grad_w2, k);
            cartan_vec_set_f32(w2, k, old_w2 - (lr * gw2));

            let old_b1 = cartan_vec_get_f32(b1, k);
            let gb1 = cartan_vec_get_f32(grad_b1, k);
            cartan_vec_set_f32(b1, k, old_b1 - (lr * gb1));

            let k0 = k * 2.0;
            let k1 = k0 + 1.0;
            let old_w1_0 = cartan_vec_get_f32(w1, k0);
            let old_w1_1 = cartan_vec_get_f32(w1, k1);
            let gw1_0 = cartan_vec_get_f32(grad_w1, k0);
            let gw1_1 = cartan_vec_get_f32(grad_w1, k1);
            cartan_vec_set_f32(w1, k0, old_w1_0 - (lr * gw1_0));
            cartan_vec_set_f32(w1, k1, old_w1_1 - (lr * gw1_1));

            k = k + 1.0;
        }

        iter = iter + 1.0;
    }

    // Generate final reconstructed signal using trained prior network
    var out_i = 0.0;
    while (out_i < len) {
        let theta = 6.2831853 * (out_i / len);
        let z0 = sin(theta);
        let z1 = cos(theta);

        var final_y = b2;
        var j = 0.0;
        while (j < hidden_channels) {
            let w1_0 = cartan_vec_get_f32(w1, j * 2.0);
            let w1_1 = cartan_vec_get_f32(w1, j * 2.0 + 1.0);
            let bj = cartan_vec_get_f32(b1, j);
            let hj = tanh((w1_0 * z0) + (w1_1 * z1) + bj);
            let w2_j = cartan_vec_get_f32(w2, j);
            final_y = final_y + (w2_j * hj);
            j = j + 1.0;
        }
        cartan_vec_push_f32(reconstructed, final_y);
        out_i = out_i + 1.0;
    }

    return reconstructed;
}
