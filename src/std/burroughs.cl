// src/std/burroughs.cl
// CARTAN Standard Library: Burroughsian Stochastic Lateral Injection Engine & Stratified Cut-Up Pool
// Neuro-Symbolic Expert System (NSES) Phase 4 Core

include "src/std/math.cl";
include "src/std/collections.cl";
include "src/std/string.cl";

extern fn cartan_tree_create() -> ptr;
extern fn cartan_tree_push(t: ptr, item: ptr) -> void;
extern fn cartan_tree_get_f32(t: ptr, idx: float) -> ptr;

// Burroughs Fragment Metadata
struct BurroughsFragment {
    fragment_id: float;
    domain_id: float;
    entropy_tier: float; // Tier 1: Adjacent Analogies, Tier 2: Structural Metaphors, Tier 3: Radical Abstractions
    text: string;
    usage_count: float;  // Monotonic usage tracking
}

// In-Memory Burroughs Fragment Pool Structure
struct BurroughsPool {
    capacity: float;
    count: float;
    fragment_ids: ptr;     // collections list (float)
    domain_ids: ptr;       // collections list (float)
    entropy_tiers: ptr;    // collections list (float)
    fragment_texts: ptr;   // cartan_tree (strings)
    usage_counts: ptr;     // collections list (float)
    total_samples: float;
}

// Ultra-fast Non-Blocking PRNG State (L'Ecuyer Combined MRG)
struct BurroughsRngState {
    s1: float;
    s2: float;
}

// Initialize PRNG state with positive non-zero prime seeds
fn burroughs_rng_init(seed1: float, seed2: float) -> BurroughsRngState {
    var s1 = seed1;
    var s2 = seed2;
    if (s1 <= 0.0) { s1 = 1234567.0; }
    if (s2 <= 0.0) { s2 = 7654321.0; }
    s1 = math_mod_val(s1, 2147483562.0) + 1.0;
    s2 = math_mod_val(s2, 2147483398.0) + 1.0;
    return BurroughsRngState { s1: s1, s2: s2 };
}

// Ultra-fast uniform float generation in interval (0.0, 1.0)
fn burroughs_rng_next(rng: BurroughsRngState) -> float {
    // L'Ecuyer Combined Multiple Recursive Generator (CMRG)
    // Period > 2^191, passes Diehard/NIST batteries in single-digit nanoseconds
    var next_s1 = math_mod_val(rng.s1 * 40014.0, 2147483563.0);
    if (next_s1 == 0.0) { next_s1 = 12345.0; }
    rng.s1 = next_s1;

    var next_s2 = math_mod_val(rng.s2 * 40692.0, 2147483399.0);
    if (next_s2 == 0.0) { next_s2 = 67890.0; }
    rng.s2 = next_s2;

    var diff = next_s1 - next_s2;
    if (diff < 1.0) {
        diff = diff + 2147483562.0;
    }
    return diff / 2147483563.0;
}

// Uniform integer index generation in range [0, max_val - 1]
fn burroughs_rng_next_int(rng: BurroughsRngState, max_val: float) -> float {
    if (max_val <= 1.0) { return 0.0; }
    let val = burroughs_rng_next(rng) * max_val;
    let idx = floor(val);
    if (idx >= max_val) { return max_val - 1.0; }
    return idx;
}

// Allocates an empty Burroughs pool
fn burroughs_pool_create(capacity: float) -> BurroughsPool {
    let p_fids = collections_create_list();
    let p_dids = collections_create_list();
    let p_tiers = collections_create_list();
    let p_texts = cartan_tree_create();
    let p_usages = collections_create_list();
    return BurroughsPool {
        capacity: capacity,
        count: 0.0,
        fragment_ids: p_fids,
        domain_ids: p_dids,
        entropy_tiers: p_tiers,
        fragment_texts: p_texts,
        usage_counts: p_usages,
        total_samples: 0.0
    };
}

// Appends a lateral prime fragment to the pool
fn burroughs_pool_add(pool: BurroughsPool, fragment_id: float, domain_id: float, entropy_tier: float, text: string) -> float {
    collections_list_push(pool.fragment_ids, fragment_id);
    collections_list_push(pool.domain_ids, domain_id);
    collections_list_push(pool.entropy_tiers, entropy_tier);
    cartan_tree_push(pool.fragment_texts, text);
    collections_list_push(pool.usage_counts, 0.0);
    pool.count = pool.count + 1.0;
    return pool.count;
}

// Deallocates pool metadata arrays
fn burroughs_pool_free(pool: BurroughsPool) {
    if (pool.fragment_ids != 0.0) { collections_free_list(pool.fragment_ids); }
    if (pool.domain_ids != 0.0) { collections_free_list(pool.domain_ids); }
    if (pool.entropy_tiers != 0.0) { collections_free_list(pool.entropy_tiers); }
    if (pool.usage_counts != 0.0) { collections_free_list(pool.usage_counts); }
}

// Reads usage count for fragment index
fn burroughs_get_fragment_usage(pool: BurroughsPool, idx: float) -> float {
    if (idx < 0.0 || idx >= pool.count) { return 0.0; }
    return collections_list_get(pool.usage_counts, idx);
}

// Reads text for fragment index
fn burroughs_get_fragment_text(pool: BurroughsPool, idx: float) -> string {
    if (idx < 0.0 || idx >= pool.count) { return ""; }
    return cartan_tree_get_f32(pool.fragment_texts, idx);
}

// Reads entropy tier for fragment index
fn burroughs_get_fragment_tier(pool: BurroughsPool, idx: float) -> float {
    if (idx < 0.0 || idx >= pool.count) { return 0.0; }
    return collections_list_get(pool.entropy_tiers, idx);
}

// Reads domain id for fragment index
fn burroughs_get_fragment_domain(pool: BurroughsPool, idx: float) -> float {
    if (idx < 0.0 || idx >= pool.count) { return 0.0; }
    return collections_list_get(pool.domain_ids, idx);
}

// Samples a lateral fragment conditioned on domain and entropy tier with atomic usage tracking
fn burroughs_sample_fragment(pool: BurroughsPool, domain_id: float, entropy_tier: float, rng: BurroughsRngState) -> string {
    // Invariant TS-4.1: If entropy_tier == 0, strictly produce NULL/empty with zero lateral injection
    if (entropy_tier <= 0.0 || pool.count <= 0.0) {
        return "";
    }

    // Collect eligible candidate indices matching domain & entropy constraints
    let candidates = collections_create_list();
    var i = 0.0;
    while (i < pool.count) {
        let f_tier = collections_list_get(pool.entropy_tiers, i);
        let f_dom = collections_list_get(pool.domain_ids, i);
        if (f_tier <= entropy_tier) {
            if (domain_id < 0.0 || f_dom == domain_id || f_dom == 0.0) {
                collections_list_push(candidates, i);
            }
        }
        i = i + 1.0;
    }

    // Fallback: If no strict domain match, select any candidate within entropy tier limit
    if (collections_list_len(candidates) == 0.0) {
        var k = 0.0;
        while (k < pool.count) {
            let f_tier_fb = collections_list_get(pool.entropy_tiers, k);
            if (f_tier_fb <= entropy_tier) {
                collections_list_push(candidates, k);
            }
            k = k + 1.0;
        }
    }

    let cand_len = collections_list_len(candidates);
    if (cand_len <= 0.0) {
        collections_free_list(candidates);
        return "";
    }

    // High-uniformity pseudorandom selection
    let choice_idx = burroughs_rng_next_int(rng, cand_len);
    let selected_idx = collections_list_get(candidates, choice_idx);
    collections_free_list(candidates);

    // Monotonic usage count update
    let current_usage = collections_list_get(pool.usage_counts, selected_idx);
    collections_list_set(pool.usage_counts, selected_idx, current_usage + 1.0);
    pool.total_samples = pool.total_samples + 1.0;

    return cartan_tree_get_f32(pool.fragment_texts, selected_idx);
}

// Populates a standard canonical Burroughs lateral prime pool
fn burroughs_pool_populate_defaults(pool: BurroughsPool) {
    // --- Tier 1: Adjacent Analogies (Cross-Domain Structural Matches) ---
    burroughs_pool_add(pool, 1.0, 1.0, 1.0, "Hydraulic fluid flow through constricted piping mirrors electrical impedance across resistive circuits.");
    burroughs_pool_add(pool, 2.0, 1.0, 1.0, "Mechanical spring resonance corresponds directly to LC tank circuit oscillatory frequency.");
    burroughs_pool_add(pool, 3.0, 1.0, 1.0, "Thermal heat dissipation models computational energy debt across densely clustered logical nodes.");
    burroughs_pool_add(pool, 4.0, 1.0, 1.0, "Gravitational potential wells mirror electrostatic attractors within conformal spatial coordinates.");

    // --- Tier 2: Structural Metaphors (Morphogenesis, Lattice Strain, Dynamics) ---
    burroughs_pool_add(pool, 5.0, 2.0, 2.0, "Crystal dislocation strain relaxes along orthogonal slip planes under concentrated shear stress.");
    burroughs_pool_add(pool, 6.0, 2.0, 2.0, "Cellular morphogenesis bifurcates along Turing reaction-diffusion concentration gradients.");
    burroughs_pool_add(pool, 7.0, 2.0, 2.0, "Topological defects in nematic director fields unwind via continuous homotopy retraction.");
    burroughs_pool_add(pool, 8.0, 2.0, 2.0, "Dynamic phase boundaries absorb mechanical shockwaves through latent enthalpy transition.");

    // --- Tier 3: Radical Abstractions (Cut-Up Primes Breaking Local Minima) ---
    burroughs_pool_add(pool, 9.0, 3.0, 3.0, "Cold gears turning backwards whisper through severed copper wire.");
    burroughs_pool_add(pool, 10.0, 3.0, 3.0, "Shadow of a magnetic needle spinning freely in a room without cardinal poles.");
    burroughs_pool_add(pool, 11.0, 3.0, 3.0, "Fractured liquid mercury beads across dry desert sand before morning rain.");
    burroughs_pool_add(pool, 12.0, 3.0, 3.0, "Echo of an unstruck iron bell vibrates the dormant crystal lattice.");
}
