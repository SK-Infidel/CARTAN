// src/std/guardrails.cl
// CARTAN Standard Library: Deterministic Symbolic Guardrails & Domain Router
// Neuro-Symbolic Expert System (NSES) Phase 2 Core

include "src/std/cargraph.cl";
include "src/std/sat_solver.cl";
include "src/cartanc/cargraph_simd.car";
include "src/std/string.cl";

// Strict Invariant Memory Slice
struct GuardrailSlice {
    is_valid: float;
    start_rule_idx: float;
    num_strict_rules: float;
}

// Active Domain Routing Result
struct GuardrailDomainRoute {
    num_active_domains: float;
    active_domain_ids: ptr; // collections_list of domain IDs (ALWAYS starts with 0.0)
}

// Extracted Rules Context
struct GuardrailExtractionResult {
    num_rules: float;
    rule_ids: ptr;          // collections_list of selected rule indices
    strict_count: float;
    associative_count: float;
}

// Direct slice extraction for strict invariants
// Bypasses vector ANN completely; O(1) index slice [0 .. num_strict_rules - 1]
fn guardrails_get_strict_slice(cg: CarGraphFile) -> GuardrailSlice {
    if (cg.is_valid == 0.0) {
        return GuardrailSlice {
            is_valid: 0.0,
            start_rule_idx: 0.0,
            num_strict_rules: 0.0
        };
    }
    return GuardrailSlice {
        is_valid: 1.0,
        start_rule_idx: 0.0,
        num_strict_rules: cg.header.num_strict_rules
    };
}

// Domain-aware query router enforcing unconditional Domain 0 (SYSTEM_CORE) inclusion
// active_domain_ids = [0] + top_k(query_vec)
fn guardrails_route_domains(cg: CarGraphFile, query_emb: ptr, domain_centroids: ptr, top_k: float) -> GuardrailDomainRoute {
    let active_list = collections_create_list();
    // Invariable mandate: Domain 0 (SYSTEM_CORE) is ALWAYS added first
    collections_list_push(active_list, 0.0);

    let n_domains = cg.header.num_domains;
    if (n_domains <= 1.0 || top_k <= 0.0 || domain_centroids == 0.0 || query_emb == 0.0) {
        return GuardrailDomainRoute {
            num_active_domains: collections_list_len(active_list),
            active_domain_ids: active_list
        };
    }

    // Score non-Domain-0 domains (domains 1 .. n_domains - 1)
    let scores = collections_create_list();
    let d_indices = collections_create_list();
    let vec_bytes = cg.header.embedding_dim * 8.0;

    var d = 1.0;
    while (d < n_domains) {
        let c_ptr = cartan_c_ptr_add(domain_centroids, d * vec_bytes);
        let sim = cargraph_simd_dot_1536(query_emb, c_ptr);
        collections_list_push(scores, sim);
        collections_list_push(d_indices, d);
        d = d + 1.0;
    }

    // Top-K selection across scored domains
    var k_target = top_k;
    let num_candidates = collections_list_len(scores);
    if (k_target > num_candidates) { k_target = num_candidates; }

    var selected_cnt = 0.0;
    while (selected_cnt < k_target) {
        var best_score = -2.0;
        var best_idx = -1.0;
        var i = 0.0;
        while (i < num_candidates) {
            let sc = collections_list_get(scores, i);
            if (sc > best_score) {
                best_score = sc;
                best_idx = i;
            }
            i = i + 1.0;
        }

        if (best_idx >= 0.0) {
            let win_domain = collections_list_get(d_indices, best_idx);
            collections_list_push(active_list, win_domain);
            collections_list_set(scores, best_idx, -999.0); // Mark consumed
            selected_cnt = selected_cnt + 1.0;
        } else {
            selected_cnt = k_target; // Break
        }
    }

    collections_free_list(scores);
    collections_free_list(d_indices);

    return GuardrailDomainRoute {
        num_active_domains: collections_list_len(active_list),
        active_domain_ids: active_list
    };
}

// Helper: check if domain_id is in active_domains list
fn guardrails_is_domain_active(active_domain_ids: ptr, domain_id: float) -> float {
    let len = collections_list_len(active_domain_ids);
    var i = 0.0;
    while (i < len) {
        if (collections_list_get(active_domain_ids, i) == domain_id) {
            return 1.0;
        }
        i = i + 1.0;
    }
    return 0.0;
}

// Filter active rules with zero cross-domain leakage
// Strict physical invariants in Domain 0 are unconditionally retained.
// Associative facts from unselected domains are strictly discarded.
fn guardrails_filter_active_rules(cg: CarGraphFile, droute: GuardrailDomainRoute) -> GuardrailExtractionResult {
    let out_rules = collections_create_list();
    var strict_cnt = 0.0;
    var assoc_cnt = 0.0;

    if (cg.is_valid == 0.0) {
        return GuardrailExtractionResult {
            num_rules: 0.0,
            rule_ids: out_rules,
            strict_count: 0.0,
            associative_count: 0.0
        };
    }

    let n_rules = cg.header.num_rules;
    var r = 0.0;
    while (r < n_rules) {
        let meta = cargraph_get_rule(cg, r);
        let d_idx = meta.domain_idx;
        let is_str = meta.is_strict;

        // Condition 1: Universal Domain 0 strict invariant
        if (d_idx == 0.0 && is_str == 1.0) {
            collections_list_push(out_rules, r);
            strict_cnt = strict_cnt + 1.0;
        } else {
            // Condition 2: Belongs to an actively routed domain
            if (guardrails_is_domain_active(droute.active_domain_ids, d_idx) != 0.0) {
                collections_list_push(out_rules, r);
                if (is_str == 1.0) {
                    strict_cnt = strict_cnt + 1.0;
                } else {
                    assoc_cnt = assoc_cnt + 1.0;
                }
            }
            // Otherwise: Silently dropped to guarantee zero cross-domain leakage
        }
        r = r + 1.0;
    }

    return GuardrailExtractionResult {
        num_rules: collections_list_len(out_rules),
        rule_ids: out_rules,
        strict_count: strict_cnt,
        associative_count: assoc_cnt
    };
}

// Leakage verifier: proves zero records from forbidden_domain were admitted into context
fn guardrails_verify_zero_leakage(cg: CarGraphFile, result: GuardrailExtractionResult, forbidden_domain: float) -> float {
    let n = result.num_rules;
    var i = 0.0;
    while (i < n) {
        let r_id = collections_list_get(result.rule_ids, i);
        let meta = cargraph_get_rule(cg, r_id);
        if (meta.domain_idx == forbidden_domain) {
            return 0.0; // Cross-domain leakage detected!
        }
        i = i + 1.0;
    }
    return 1.0; // Clean: 0.0% leakage
}

// Format inviolable bounds prompt header directly from contiguous strict slice
fn guardrails_format_inviolable_bounds(cg: CarGraphFile, slice: GuardrailSlice) -> string {
    if (slice.is_valid == 0.0 || slice.num_strict_rules == 0.0) {
        return "";
    }
    var prompt = "[SYSTEM BOUNDS - INVIOLABLE]\n";
    var idx = slice.start_rule_idx;
    let end_idx = slice.start_rule_idx + slice.num_strict_rules;
    while (idx < end_idx) {
        let txt = cargraph_get_rule_text(cg, idx);
        prompt = cartan_string_concat(prompt, "- ");
        prompt = cartan_string_concat(prompt, txt);
        prompt = cartan_string_concat(prompt, "\n");
        idx = idx + 1.0;
    }
    prompt = cartan_string_concat(prompt, "[/SYSTEM BOUNDS]\n");
    return prompt;
}

// Consistent graph serialization gate: validates topology with SAT verifier before write
fn cargraph_verify_and_serialize(builder: CarGraphBuilder, filepath: string, solver: SatSolver) -> float {
    let is_consistent = sat_solve_consistency(solver);
    if (is_consistent == 0.0) {
        printf("[SAT VERIFIER REJECTION] Graph compilation blocked due to logical contradiction!\n");
        printf("  -> Offending Rules: var1 = %.0f, var2 = %.0f, conflict_type = %.0f\n",
               solver.conflict_var1, solver.conflict_var2, solver.conflict_type);
        return 0.0;
    }
    return cargraph_serialize_to_file(builder, filepath);
}

// Free route allocated lists
fn guardrails_free_route(droute: GuardrailDomainRoute) {
    if (droute.active_domain_ids != 0.0) {
        collections_free_list(droute.active_domain_ids);
    }
}

// Free extraction result allocated lists
fn guardrails_free_extraction(res: GuardrailExtractionResult) {
    if (res.rule_ids != 0.0) {
        collections_free_list(res.rule_ids);
    }
}
