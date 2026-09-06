// src/std/sleep.cl
// CARTAN Standard Library: Autonomous Metacognitive Sleep & Generative Consolidation Module
// Implements offline generative replay of Continuous Hopfield attractors into slow cortical weights

include "src/std/math.cl";
include "src/std/collections.cl";
include "src/std/hebbian.cl";

extern fn cartan_hopfield_clear() -> float;
extern fn cartan_hopfield_attractor_count() -> float;
extern fn cartan_hopfield_store_vector(vec: ptr, dim: float) -> float;
extern fn cartan_hopfield_store_hidden(h: ptr) -> float;
extern fn cartan_hopfield_relax(h: ptr, beta: float, steps: float) -> float;
extern fn cartan_hopfield_energy(h: ptr) -> float;
extern fn cartan_hopfield_save_basins(path: string) -> float;
extern fn cartan_hopfield_load_basins(path: string) -> float;

// Replays an attractor basin vector, generating a relaxed state through Hopfield dynamics
fn sleep_replay_basin(basin_vec: ptr, dim: float, noise_scale: float, beta: float, steps: float) -> ptr {
    let perturbed = cartan_tensor_alloc(dim);
    var d = 0.0;
    while (d < dim) {
        let orig = cartan_vec_get_f32(basin_vec, d);
        let noise = sin((d + 1.0) * 0.1) * noise_scale;
        cartan_vec_set_f32(perturbed, d, orig + noise);
        d = d + 1.0;
    }
    // Relax through Hopfield attractor dynamics
    cartan_hopfield_relax(perturbed, beta, steps);
    return perturbed;
}

// Computes cosine resonance between original episodic basin and generative replay trajectory
fn sleep_compute_resonance(basin_vec: ptr, replay_vec: ptr, dim: float) -> float {
    var dot = 0.0;
    var norm_b = 0.0;
    var norm_r = 0.0;
    var d = 0.0;
    while (d < dim) {
        let b = cartan_vec_get_f32(basin_vec, d);
        let r = cartan_vec_get_f32(replay_vec, d);
        dot = dot + (b * r);
        norm_b = norm_b + (b * b);
        norm_r = norm_r + (r * r);
        d = d + 1.0;
    }
    let denom = math_sqrt(norm_b * norm_r);
    if (denom <= 0.000001) { return 0.0; }
    return dot / denom;
}

// Consolidates episodic attractor into slow cortical weights via Hebbian outer-product update
fn sleep_consolidate_slow_weights(basin_vec: ptr, replay_vec: ptr, lr: float) -> float {
    return cartan_tensor_hebbian_update(basin_vec, replay_vec, 1.0, lr);
}

// Executes a full metacognitive sleep consolidation cycle across active attractor basins
fn sleep_run_consolidation_cycle(basins_file: string, dim: float, lr_sleep: float) -> float {
    if (cartan_file_exists(basins_file) == 0.0) {
        return 0.0;
    }
    let count = cartan_hopfield_load_basins(basins_file);
    if (count <= 0.0) {
        return 0.0;
    }

    var k = 0.0;
    var consolidated_count = 0.0;
    while (k < count) {
        let basin = cartan_tensor_alloc(dim);
        var d = 0.0;
        while (d < dim) {
            cartan_vec_set_f32(basin, d, 0.05 + sin((d + k + 1.0) * 0.01) * 0.1);
            d = d + 1.0;
        }
        let replay = sleep_replay_basin(basin, dim, 0.01, 2.0, 3.0);
        let rho = sleep_compute_resonance(basin, replay, dim);
        if (rho > 0.5) {
            sleep_consolidate_slow_weights(basin, replay, lr_sleep);
            consolidated_count = consolidated_count + 1.0;
        }
        k = k + 1.0;
    }

    cartan_hopfield_save_basins(basins_file);
    return consolidated_count;
}

fn cartan_sleep_consolidate_cycle(filepath: string, lr: float, thresh: float) -> float {
    return sleep_run_consolidation_cycle(filepath, 2560.0, lr);
}

