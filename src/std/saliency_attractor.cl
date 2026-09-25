// src/std/saliency_attractor.cl
// CARTAN Standard Library: Saliency-Based Attractor Selection & Dynamic Domain Cache
// Neuro-Symbolic Expert System (NSES) Phase 6 Core

include "src/std/math.cl";
include "src/std/collections.cl";
include "src/std/cargraph.cl";
include "src/std/resonator.cl";

extern fn cartan_set_f32(p: ptr, offset: float, val: float) -> void;

// Selects the most salient rule indices from a CarGraphFile for a given active domain:
// Tier 1: Universal Domain 0 Strict Invariants (Energy, Entropy, Causality, Non-Contradiction)
// Tier 2: Active Domain Strict Invariants (e.g. Halting problem, Central dogma, Conservation laws)
// Tier 3: Active Domain Factual / Grounded Rules
// Tier 4: Adjacent Domain Invariants for remaining slots
fn saliency_select_domain_attractor_indices(
    cg: CarGraphFile,
    target_domain: float,
    max_attractors: float
) -> ptr {
    let selected = collections_create_list();
    if (cg.is_valid == 0.0) { return selected; }

    var max_cap = max_attractors;
    if (max_cap <= 0.0) { max_cap = 8.0; }

    let num_rules = cg.header.num_rules;

    // Pass 1: Domain 0 Universal Strict Invariants (Always anchored)
    var r = 0.0;
    while (r < num_rules && collections_list_len(selected) < max_cap) {
        let meta = cargraph_get_rule(cg, r);
        if (meta.domain_idx == 0.0 && meta.is_strict == 1.0) {
            collections_list_push(selected, r);
        }
        r = r + 1.0;
    }

    // Pass 2: Target Domain Strict Invariants
    if (target_domain > 0.0) {
        r = 0.0;
        while (r < num_rules && collections_list_len(selected) < max_cap) {
            let meta = cargraph_get_rule(cg, r);
            if (meta.domain_idx == target_domain && meta.is_strict == 1.0) {
                collections_list_push(selected, r);
            }
            r = r + 1.0;
        }
    }

    // Pass 3: Target Domain Grounded / Factual Rules
    if (target_domain > 0.0) {
        r = 0.0;
        while (r < num_rules && collections_list_len(selected) < max_cap) {
            let meta = cargraph_get_rule(cg, r);
            if (meta.domain_idx == target_domain && meta.is_strict == 0.0) {
                collections_list_push(selected, r);
            }
            r = r + 1.0;
        }
    }

    // Pass 4: Fill remaining slots with other strict invariants if capacity permits
    r = 0.0;
    while (r < num_rules && collections_list_len(selected) < max_cap) {
        let meta = cargraph_get_rule(cg, r);
        if (meta.is_strict == 1.0 && meta.domain_idx != target_domain && meta.domain_idx != 0.0) {
            collections_list_push(selected, r);
        }
        r = r + 1.0;
    }

    return selected;
}

// Formats selected rule embeddings into a flat contiguous float buffer for GPU DMA upload:
// Copies 1536-D embedding, pads to dim (2560-D), unit-normalizes with L2 norm, and zero-fills unused slots
fn saliency_format_attractor_buffer(
    cg: CarGraphFile,
    rule_indices: ptr,
    out_buf: ptr,
    dim: float,
    max_attractors: float
) -> float {
    if (cg.is_valid == 0.0 || out_buf == 0.0 || rule_indices == 0.0) { return 0.0; }
    let n_rules = collections_list_len(rule_indices);
    var count = n_rules;
    if (count > max_attractors) { count = max_attractors; }

    var emb_dim = cg.header.embedding_dim;
    if (emb_dim > dim) { emb_dim = dim; }

    var s = 0.0;
    while (s < count) {
        let r_idx = collections_list_get(rule_indices, s);
        let emb = cargraph_get_rule_embedding(cg, r_idx);

        var sum_sq = 0.0;
        var d = 0.0;
        while (d < emb_dim) {
            let val = emb[d];
            sum_sq = sum_sq + (val * val);
            d = d + 1.0;
        }

        if (sum_sq > 0.000001) {
            let inv_norm = 1.0 / sqrt(sum_sq);
            d = 0.0;
            let base_off = s * dim;
            while (d < emb_dim) {
                let v = emb[d] * inv_norm;
                cartan_set_f32(out_buf, base_off + d, v);
                d = d + 1.0;
            }
            while (d < dim) {
                cartan_set_f32(out_buf, base_off + d, 0.0);
                d = d + 1.0;
            }
        } else {
            // Harmonic fallback when raw rule embedding slot in binary file was unpopulated
            var harm_sum_sq = 0.0;
            d = 0.0;
            while (d < emb_dim) {
                let hv = sin((d + 1.0) * 0.041 + (r_idx + 1.0) * 0.731 + (s * 1.618));
                harm_sum_sq = harm_sum_sq + (hv * hv);
                d = d + 1.0;
            }
            var h_inv = 1.0;
            if (harm_sum_sq > 0.000001) {
                h_inv = 1.0 / sqrt(harm_sum_sq);
            }
            d = 0.0;
            let base_off = s * dim;
            while (d < emb_dim) {
                let hv = sin((d + 1.0) * 0.041 + (r_idx + 1.0) * 0.731 + (s * 1.618)) * h_inv;
                cartan_set_f32(out_buf, base_off + d, hv);
                d = d + 1.0;
            }
            while (d < dim) {
                cartan_set_f32(out_buf, base_off + d, 0.0);
                d = d + 1.0;
            }
        }
        s = s + 1.0;
    }

    // Zero-fill unused attractor slots up to max_attractors
    while (s < max_attractors) {
        let base_off = s * dim;
        var d = 0.0;
        while (d < dim) {
            cartan_set_f32(out_buf, base_off + d, 0.0);
            d = d + 1.0;
        }
        s = s + 1.0;
    }

    return count;
}

// Selects Top-K most resonant attractors from an attractor bank against an active query/state vector
fn saliency_select_resonant_attractors(
    bank: ptr,
    query_vec: ptr,
    dim: float,
    max_attractors: float
) -> ptr {
    let result = cartan_tree_create();
    if (bank == 0.0 || query_vec == 0.0 || dim <= 0.0) { return result; }
    let num_basins = cartan_tree_len_f(bank);
    if (num_basins <= 0.0) { return result; }

    var max_k = max_attractors;
    if (max_k <= 0.0) { max_k = 8.0; }
    if (max_k > num_basins) { max_k = num_basins; }

    var q_sq = 0.0;
    var d = 0.0;
    while (d < dim) {
        let q = cartan_vec_get_f32(query_vec, d);
        q_sq = q_sq + (q * q);
        d = d + 1.0;
    }
    var inv_q = 1.0;
    if (q_sq > 0.000001) { inv_q = 1.0 / sqrt(q_sq); }

    // Track chosen indices to avoid duplicates
    let chosen = collections_create_list();
    var sel = 0.0;
    while (sel < max_k) {
        var best_idx = -1.0;
        var best_cos = -999999.0;
        var k = 0.0;
        while (k < num_basins) {
            // Check if already chosen
            var already = 0.0;
            var c = 0.0;
            let n_ch = collections_list_len(chosen);
            while (c < n_ch) {
                if (collections_list_get(chosen, c) == k) {
                    already = 1.0;
                    break;
                }
                c = c + 1.0;
            }

            if (already == 0.0) {
                let basin_k = cartan_tree_get(bank, k);
                var dot = 0.0;
                d = 0.0;
                while (d < dim) {
                    let v = cartan_vec_get_f32(basin_k, d);
                    let q_val = cartan_vec_get_f32(query_vec, d) * inv_q;
                    dot = dot + (v * q_val);
                    d = d + 1.0;
                }
                if (dot > best_cos) {
                    best_cos = dot;
                    best_idx = k;
                }
            }
            k = k + 1.0;
        }

        if (best_idx >= 0.0) {
            collections_list_push(chosen, best_idx);
            let chosen_vec = cartan_tree_get(bank, best_idx);
            cartan_tree_push(result, chosen_vec);
        } else {
            break;
        }
        sel = sel + 1.0;
    }

    collections_free_list(chosen);
    return result;
}
