// src/std/domain_genesis.cl
// CARTAN Standard Library: Autonomous Domain Genesis & Online Centroid Clustering Engine
// Neuro-Symbolic Expert System (NSES) Phase 6 Core

include "src/std/math.cl";
include "src/std/collections.cl";
include "src/std/string.cl";
include "src/cartanc/cargraph_simd.car";

extern fn malloc(size: float) -> ptr;
extern fn free(p: ptr);

// Master Domain Genesis & Online Centroid Tracker
// Uses parallel collection lists to avoid untyped struct GEP overhead
struct DomainGenesisTracker {
    max_domains: float;
    num_domains: float;
    domain_names: ptr;           // cartan_tree of string names
    domain_centroids: ptr;       // cartan_tree of 1536-D centroid ptrs
    domain_counts: ptr;          // collections list of note counts
    domain_active: ptr;          // collections list of active flags (1.0 or 0.0)
    novelty_threshold: float;    // default 0.35 (1 - max_cos > 0.35)
    dim: float;                  // 1536.0
}

// Allocates and initializes domain genesis tracker
fn domain_genesis_create(max_domains: float, dim: float, novelty_threshold: float) -> DomainGenesisTracker {
    var max_d = max_domains;
    if (max_d < 8.0) { max_d = 64.0; }
    var d_dim = dim;
    if (d_dim < 64.0) { d_dim = 1536.0; }
    var thresh = novelty_threshold;
    if (thresh <= 0.0) { thresh = 0.35; }

    return DomainGenesisTracker {
        max_domains: max_d,
        num_domains: 0.0,
        domain_names: cartan_tree_create(),
        domain_centroids: cartan_tree_create(),
        domain_counts: collections_create_list(),
        domain_active: collections_create_list(),
        novelty_threshold: thresh,
        dim: d_dim
    };
}

// Frees all domain cluster resources
fn domain_genesis_free(tracker: DomainGenesisTracker) {
    if (tracker.domain_counts != 0.0) { collections_free_list(tracker.domain_counts); }
    if (tracker.domain_active != 0.0) { collections_free_list(tracker.domain_active); }
    var i = 0.0;
    while (i < tracker.num_domains) {
        let c_vec = cartan_tree_get_f32(tracker.domain_centroids, i);
        if (c_vec != 0.0) { free(c_vec); }
        i = i + 1.0;
    }
}

// Registers an initial domain with unit-normalized centroid
fn domain_genesis_add_domain(tracker: DomainGenesisTracker, name: string, initial_centroid: ptr) -> float {
    if (tracker.num_domains >= tracker.max_domains) { return -1.0; }

    let d_id = tracker.num_domains;
    let c_vec = malloc(tracker.dim * 8.0);
    var k = 0.0;
    while (k < tracker.dim) {
        c_vec[k] = initial_centroid[k];
        k = k + 1.0;
    }
    cargraph_simd_normalize_1536(c_vec);

    cartan_tree_push(tracker.domain_names, name);
    cartan_tree_push(tracker.domain_centroids, c_vec);
    collections_list_push(tracker.domain_counts, 1.0);
    collections_list_push(tracker.domain_active, 1.0);
    tracker.num_domains = tracker.num_domains + 1.0;

    return d_id;
}

// Retrieves centroid vector for a given domain partition ID
fn domain_genesis_get_centroid(tracker: DomainGenesisTracker, domain_id: float) -> ptr {
    if (domain_id < 0.0 || domain_id >= tracker.num_domains) { return 0.0; }
    return cartan_tree_get_f32(tracker.domain_centroids, domain_id);
}

// Retrieves note count for a given domain partition ID
fn domain_genesis_get_count(tracker: DomainGenesisTracker, domain_id: float) -> float {
    if (domain_id < 0.0 || domain_id >= tracker.num_domains) { return 0.0; }
    return collections_list_get(tracker.domain_counts, domain_id);
}

// Scans all active domains and returns the maximum cosine similarity
fn domain_genesis_max_similarity(tracker: DomainGenesisTracker, candidate_vec: ptr) -> float {
    if (tracker.num_domains <= 0.0 || candidate_vec == 0.0) { return 0.0; }

    var max_sim = -2.0;
    var i = 0.0;
    while (i < tracker.num_domains) {
        let active = collections_list_get(tracker.domain_active, i);
        if (active != 0.0) {
            let c_vec = cartan_tree_get_f32(tracker.domain_centroids, i);
            let sim = cargraph_simd_cosine_sim_1536(candidate_vec, c_vec);
            if (sim > max_sim) {
                max_sim = sim;
            }
        }
        i = i + 1.0;
    }
    return max_sim;
}

// Finds the closest domain ID for a candidate vector
fn domain_genesis_find_closest_domain(tracker: DomainGenesisTracker, candidate_vec: ptr) -> float {
    if (tracker.num_domains <= 0.0 || candidate_vec == 0.0) { return -1.0; }

    var best_sim = -2.0;
    var best_d = -1.0;
    var i = 0.0;
    while (i < tracker.num_domains) {
        let active = collections_list_get(tracker.domain_active, i);
        if (active != 0.0) {
            let c_vec = cartan_tree_get_f32(tracker.domain_centroids, i);
            let sim = cargraph_simd_cosine_sim_1536(candidate_vec, c_vec);
            if (sim > best_sim) {
                best_sim = sim;
                best_d = i;
            }
        }
        i = i + 1.0;
    }
    return best_d;
}

// Ingests a candidate note: Either attaches to existing domain or mints novel domain partition
// Novelty condition: 1.0 - max_sim > novelty_threshold (0.35)
fn domain_genesis_ingest_note(tracker: DomainGenesisTracker, candidate_vec: ptr, name_hint: string) -> float {
    let max_sim = domain_genesis_max_similarity(tracker, candidate_vec);
    let novelty = 1.0 - max_sim;

    if (tracker.num_domains > 0.0 && novelty <= tracker.novelty_threshold) {
        // Intra-domain attachment: Update existing domain centroid
        let target_id = domain_genesis_find_closest_domain(tracker, candidate_vec);
        let curr_count = collections_list_get(tracker.domain_counts, target_id);
        let new_count = curr_count + 1.0;
        collections_list_set(tracker.domain_counts, target_id, new_count);

        // Asymptotic velocity decay update: c_d <- normalize(c_d + (1 / N) * (e - c_d))
        let lr = 1.0 / new_count;
        var k = 0.0;
        let c_vec = cartan_tree_get_f32(tracker.domain_centroids, target_id);
        while (k < tracker.dim) {
            let delta = candidate_vec[k] - c_vec[k];
            c_vec[k] = c_vec[k] + (lr * delta);
            k = k + 1.0;
        }
        cargraph_simd_normalize_1536(c_vec);
        return target_id;
    }

    // Novelty threshold exceeded (novelty > 0.35): Autonomous Domain Genesis!
    return domain_genesis_add_domain(tracker, name_hint, candidate_vec);
}
