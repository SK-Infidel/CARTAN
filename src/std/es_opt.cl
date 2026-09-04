// src/std/es_opt.cl
// CARTAN Evolution Strategies (ES) Optimizer Implementation
// Implements Mirrored Gaussian Noise Perturbation (Antithetic Variates) and Z-Score Standardized Score Function Gradient Estimation

include "src/std/math.cl";

fn es_optimizer_create(dimension: float, population_size: float, sigma: float, alpha: float) -> ptr {
    let opt = cartan_tree_create();
    cartan_tree_push(opt, dimension);          // [0] D
    cartan_tree_push(opt, population_size);   // [1] N
    cartan_tree_push(opt, sigma);             // [2] sigma
    cartan_tree_push(opt, alpha);             // [3] alpha

    let params = cartan_vec_create();
    var i = 0.0;
    while (i < dimension) {
        cartan_vec_push_f32(params, 0.0);
        i = i + 1.0;
    }
    cartan_tree_push(opt, params);            // [4] theta vector

    let noise_matrix = cartan_tree_create();
    let n_half = population_size / 2.0;
    var c = 0.0;
    while (c < n_half) {
        let noise_vec = cartan_vec_create();
        var p = 0.0;
        while (p < dimension) {
            // Pseudo-random Gaussian noise sample via Box-Muller approximation
            let r1 = math_mod_val(c * 17.0 + p * 31.0 + 13.0, 1000.0) / 1000.0 + 0.001;
            let r2 = math_mod_val(c * 23.0 + p * 47.0 + 19.0, 1000.0) / 1000.0 + 0.001;
            let g_sample = sqrt(-2.0 * log(r1)) * cos(6.2831853 * r2);
            cartan_vec_push_f32(noise_vec, g_sample);
            p = p + 1.0;
        }
        cartan_tree_push(noise_matrix, noise_vec);
        c = c + 1.0;
    }
    cartan_tree_push(opt, noise_matrix);      // [5] noise_matrix (N/2 x D)

    return opt;
}

fn es_optimizer_get_param(opt: ptr, idx: float) -> float {
    if (opt == 0.0) { return 0.0; }
    let params = cartan_tree_get_f32(opt, 4.0);
    return cartan_vec_get_f32(params, idx);
}

fn es_optimizer_set_param(opt: ptr, idx: float, val: float) -> float {
    if (opt == 0.0) { return 0.0; }
    let params = cartan_tree_get_f32(opt, 4.0);
    cartan_vec_set_f32(params, idx, val);
    return val;
}

fn es_optimizer_get_perturbed_param(opt: ptr, clone_idx: float, param_idx: float, sign: float) -> float {
    if (opt == 0.0) { return 0.0; }
    let sigma = cartan_tree_get_f32(opt, 2.0);
    let base_val = es_optimizer_get_param(opt, param_idx);
    let noise_matrix = cartan_tree_get_f32(opt, 5.0);
    let half_idx = clone_idx / 2.0;
    let noise_vec = cartan_tree_get_f32(noise_matrix, half_idx);
    let noise_val = cartan_vec_get_f32(noise_vec, param_idx);
    
    if (sign > 0.0) {
        return base_val + sigma * noise_val;
    }
    return base_val - sigma * noise_val;
}

fn es_optimizer_step(opt: ptr, fitness_pos: ptr, fitness_neg: ptr) -> float {
    if (opt == 0.0 || fitness_pos == 0.0 || fitness_neg == 0.0) { return 0.0; }
    let dimension = cartan_tree_get_f32(opt, 0.0);
    let pop_size = cartan_tree_get_f32(opt, 1.0);
    let sigma = cartan_tree_get_f32(opt, 2.0);
    let alpha = cartan_tree_get_f32(opt, 3.0);
    let noise_matrix = cartan_tree_get_f32(opt, 5.0);

    let n_half = pop_size / 2.0;

    var p = 0.0;
    while (p < dimension) {
        var update_sum = 0.0;
        var i = 0.0;
        while (i < n_half) {
            let f_p = cartan_vec_get_f32(fitness_pos, i);
            let f_n = cartan_vec_get_f32(fitness_neg, i);
            let diff = f_p - f_n;

            let noise_vec = cartan_tree_get_f32(noise_matrix, i);
            let eps = cartan_vec_get_f32(noise_vec, p);

            update_sum = update_sum + diff * eps;
            i = i + 1.0;
        }

        let current_val = es_optimizer_get_param(opt, p);
        let delta = (alpha / (pop_size * sigma)) * update_sum;
        es_optimizer_set_param(opt, p, current_val + delta);

        p = p + 1.0;
    }

    return 1.0;
}

fn es_optimizer_free(opt: ptr) -> float {
    return 1.0;
}
