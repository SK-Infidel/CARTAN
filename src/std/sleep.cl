// src/std/sleep.cl
// CARTAN Standard Library: Autonomous Metacognitive Sleep & Generative Consolidation Module
// Implements offline generative replay of Continuous Hopfield attractors into slow cortical weights

include "src/std/math.cl";
include "src/std/collections.cl";
include "src/std/hebbian.cl";
include "src/std/cargraph.cl";
include "src/std/resonator.cl";

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
fn sleep_run_consolidation_cycle(basins_file: string, dim: float, lr_sleep: float, thresh: float) -> float {
    if (cartan_file_exists(basins_file) == 0.0) {
        return 0.0;
    }
    let count = cartan_hopfield_load_basins(basins_file);
    if (count <= 0.0) {
        return 0.0;
    }

    var prune_thresh = thresh;
    if (prune_thresh <= 0.0) { prune_thresh = 0.98; }

    // Deduplicate and compact active attractor basins
    let compacted_count = cartan_hopfield_compact(prune_thresh);

    var k = 0.0;
    var consolidated_count = 0.0;
    // Bounded micro-nap replay cap: Replay at most 64 salient attractors to keep sleep latency under 100ms
    var replay_limit = compacted_count;
    if (replay_limit > 64.0) { replay_limit = 64.0; }

    while (k < replay_limit) {
        let basin = cartan_hopfield_get_basin(k);
        if (basin != 0.0) {
            let replay = sleep_replay_basin(basin, dim, 0.01, 2.0, 3.0);
            let rho = sleep_compute_resonance(basin, replay, dim);
            if (rho > 0.5) {
                sleep_consolidate_slow_weights(basin, replay, lr_sleep);
                consolidated_count = consolidated_count + 1.0;
            }
            cartan_vec_free(replay);
        }
        k = k + 1.0;
    }

    cartan_hopfield_save_basins(basins_file);
    return consolidated_count;
}

// Executes an in-memory metacognitive sleep consolidation cycle across active attractor basins
// Bypasses disk reads when basins are already active in RAM, and skips writing disk on micro-naps
fn sleep_run_consolidation_cycle_memory(basins_file: string, dim: float, lr_sleep: float, thresh: float) -> float {
    var count = cartan_hopfield_attractor_count();
    if (count <= 0.0 && basins_file != 0.0 && cartan_file_exists(basins_file) == 1.0) {
        count = cartan_hopfield_load_basins(basins_file);
    }
    if (count <= 0.0) {
        return 0.0;
    }

    var prune_thresh = thresh;
    if (prune_thresh <= 0.0) { prune_thresh = 0.98; }

    // Deduplicate and compact active attractor basins
    let compacted_count = cartan_hopfield_compact(prune_thresh);

    var k = 0.0;
    var consolidated_count = 0.0;
    // Bounded micro-nap replay cap: Replay at most 64 salient attractors to keep sleep latency under 100ms
    var replay_limit = compacted_count;
    if (replay_limit > 64.0) { replay_limit = 64.0; }

    while (k < replay_limit) {
        let basin = cartan_hopfield_get_basin(k);
        if (basin != 0.0) {
            let replay = sleep_replay_basin(basin, dim, 0.01, 2.0, 3.0);
            let rho = sleep_compute_resonance(basin, replay, dim);
            if (rho > 0.5) {
                sleep_consolidate_slow_weights(basin, replay, lr_sleep);
                consolidated_count = consolidated_count + 1.0;
            }
            cartan_vec_free(replay);
        }
        k = k + 1.0;
    }

    return consolidated_count;
}

// Replays verified NSES axiomatic rules directly from an in-memory CarGraphFile into slow cortical weights
fn sleep_run_axiomatic_consolidation_graph(cg: CarGraphFile, basins_file: string, dim: float, lr_sleep: float) -> float {
    if (cg.is_valid == 0.0) {
        return 0.0;
    }

    let num_rules = cg.header.num_rules;
    if (num_rules <= 0.0) {
        return 0.0;
    }

    cartan_hopfield_init_if_needed();
    var consolidated_rules = 0.0;
    var has_new_attractors = 0.0;
    var r = 0.0;

    while (r < num_rules) {
        let r_meta = cargraph_get_rule(cg, r);
        let emb_ptr = cargraph_get_rule_embedding(cg, r);

        if (emb_ptr != 0.0) {
            // Allocate 2560-D attractor vector and populate from 1536-D rule embedding
            let basin = cartan_tensor_alloc(dim);
            var d = 0.0;
            var emb_dim = cg.header.embedding_dim;
            if (emb_dim > dim) { emb_dim = dim; }

            var dot_self = 0.0;
            while (d < emb_dim) {
                let val = emb_ptr[d];
                cartan_vec_set_f32(basin, d, val);
                dot_self = dot_self + (val * val);
                d = d + 1.0;
            }
            while (d < dim) {
                cartan_vec_set_f32(basin, d, 0.0);
                d = d + 1.0;
            }

            // Unit normalize basin vector
            if (dot_self > 0.000001) {
                let inv_norm = 1.0 / sqrt(dot_self);
                var nd = 0.0;
                while (nd < emb_dim) {
                    cartan_vec_set_f32(basin, nd, cartan_vec_get_f32(basin, nd) * inv_norm);
                    nd = nd + 1.0;
                }
            }

            // Store clean axiomatic attractor into Hopfield memory bank ONLY if novel
            let prev_cnt = cartan_hopfield_attractor_count();
            let new_cnt = cartan_hopfield_store_vector(basin, dim);
            if (new_cnt > prev_cnt) {
                has_new_attractors = 1.0;
            }

            // Replay through Hopfield dynamics and compute resonance
            let replay = sleep_replay_basin(basin, dim, 0.01, 2.0, 3.0);
            let rho = sleep_compute_resonance(basin, replay, dim);

            // Strict physical/logical invariants receive higher Hebbian reinforcement
            var effective_lr = lr_sleep;
            if (r_meta.is_strict == 1.0) {
                effective_lr = lr_sleep * 1.5;
            }

            if (rho > 0.40) {
                sleep_consolidate_slow_weights(basin, replay, effective_lr);
                consolidated_rules = consolidated_rules + 1.0;
            }
            cartan_vec_free(replay);
            cartan_vec_free(basin);
        }
        r = r + 1.0;
    }

    if (has_new_attractors == 1.0 && basins_file != 0.0 && cartan_string_length(basins_file) > 0.0) {
        cartan_hopfield_save_basins(basins_file);
    }
    return consolidated_rules;
}

// Replays verified NSES axiomatic rules into slow cortical weights with Hopfield relaxation (loads from disk if needed)
fn sleep_run_axiomatic_consolidation(nses_graph_path: string, basins_file: string, dim: float, lr_sleep: float) -> float {
    if (cartan_file_exists(nses_graph_path) == 0.0) {
        return 0.0;
    }
    let cg = cargraph_load_binary(nses_graph_path);
    if (cg.is_valid == 0.0) {
        return 0.0;
    }
    let res = sleep_run_axiomatic_consolidation_graph(cg, basins_file, dim, lr_sleep);
    cargraph_free(cg);
    return res;
}

fn cartan_sleep_consolidate_cycle(filepath: string, lr: float, thresh: float) -> float {
    return sleep_run_consolidation_cycle(filepath, 2560.0, lr, thresh);
}

fn cartan_sleep_consolidate_cycle_memory(filepath: string, lr: float, thresh: float) -> float {
    return sleep_run_consolidation_cycle_memory(filepath, 2560.0, lr, thresh);
}


