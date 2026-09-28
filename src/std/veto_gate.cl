// src/std/veto_gate.cl
// CARTAN Standard Library: Absolute Post-Pass Deterministic Veto Gate (Model Disobedience Firewall)
// Neuro-Symbolic Expert System (NSES) Phase 5 Core

include "src/std/math.cl";
include "src/std/collections.cl";
include "src/std/string.cl";

extern fn calloc(count: float, size: float) -> ptr;
extern fn free(p: ptr);
extern fn strlen(s: string) -> float;
extern fn cartan_string_get_char(s: string, idx: float) -> float;
extern fn cartan_set_byte(buf: ptr, offset: float, val: float);
extern fn cartan_tree_create() -> ptr;
extern fn cartan_tree_push(t: ptr, item: ptr) -> void;
extern fn cartan_tree_get_f32(t: ptr, idx: float) -> ptr;
extern fn cartan_tree_len_f(t: ptr) -> float;

// Veto Evaluation Result Structure
struct VetoResult {
    is_vetoed: float;             // 1.0 = vetoed (suppressed & replaced), 0.0 = passed clean
    output_text: string;          // Original text if clean; canonical invariant assertion if vetoed
    violated_rule_id: float;      // Index of violated invariant rule (-1.0 if clean)
    violation_pattern: string;    // Contradictory pattern detected
}

// In-Memory Veto Rule Registry Structure
struct VetoRegistry {
    count: float;
    rule_ids: ptr;                // collections list (float)
    domain_ids: ptr;              // collections list (float)
    canonical_assertions: ptr;   // cartan_tree of strings
    pattern_trees: ptr;           // cartan_tree of cartan_trees (list of forbidden patterns per rule)
    domain_forbidden_tokens: ptr; // cartan_tree of collections lists of float token IDs
}

// Converts an ASCII string to lowercase for robust pattern matching
fn veto_string_to_lower(s: string) -> string {
    if (s == 0.0) { return ""; }
    let len = strlen(s);
    if (len == 0.0) { return ""; }
    let res = calloc(len + 1.0, 1.0);
    var i = 0.0;
    while (i < len) {
        var c = cartan_string_get_char(s, i);
        if (c >= 65.0 && c <= 90.0) { // 'A' .. 'Z'
            c = c + 32.0;
        }
        cartan_set_byte(res, i, c);
        i = i + 1.0;
    }
    return res;
}

// Allocates an empty VetoRegistry
fn veto_registry_create() -> VetoRegistry {
    let r_ids = collections_create_list();
    let d_ids = collections_create_list();
    let c_tree = cartan_tree_create();
    let p_tree = cartan_tree_create();
    let d_toks = cartan_tree_create();
    var d = 0.0;
    while (d < 8.0) {
        let t_list = collections_create_list();
        cartan_tree_push(d_toks, t_list);
        d = d + 1.0;
    }
    return VetoRegistry {
        count: 0.0,
        rule_ids: r_ids,
        domain_ids: d_ids,
        canonical_assertions: c_tree,
        pattern_trees: p_tree,
        domain_forbidden_tokens: d_toks
    };
}

// Adds an invariant rule and its contradictory pattern trigger list
fn veto_registry_add_rule(reg: VetoRegistry, rule_id: float, domain_id: float, assertion: string, forbidden_tree: ptr) -> float {
    collections_list_push(reg.rule_ids, rule_id);
    collections_list_push(reg.domain_ids, domain_id);
    cartan_tree_push(reg.canonical_assertions, assertion);
    cartan_tree_push(reg.pattern_trees, forbidden_tree);
    reg.count = reg.count + 1.0;
    return reg.count;
}

// Registers a forbidden token ID associated with contradictions in a domain
fn veto_registry_add_forbidden_token(reg: VetoRegistry, domain_id: float, token_id: float) -> float {
    if (reg.domain_forbidden_tokens == 0.0 || domain_id < 0.0 || domain_id >= 8.0) { return 0.0; }
    let t_list = cartan_tree_get_f32(reg.domain_forbidden_tokens, domain_id);
    if (t_list != 0.0) {
        collections_list_push(t_list, token_id);
        return collections_list_len(t_list);
    }
    return 0.0;
}

// Deallocates VetoRegistry resources
fn veto_registry_free(reg: VetoRegistry) {
    if (reg.rule_ids != 0.0) { collections_free_list(reg.rule_ids); }
    if (reg.domain_ids != 0.0) { collections_free_list(reg.domain_ids); }
    if (reg.domain_forbidden_tokens != 0.0) {
        var d = 0.0;
        let num_d = cartan_tree_len_f(reg.domain_forbidden_tokens);
        while (d < num_d) {
            let t_list = cartan_tree_get_f32(reg.domain_forbidden_tokens, d);
            if (t_list != 0.0) { collections_free_list(t_list); }
            d = d + 1.0;
        }
    }
}

// Scans candidate generated response text against active invariants
fn veto_gate_scan(reg: VetoRegistry, candidate_text: string) -> VetoResult {
    if (candidate_text == 0.0 || strlen(candidate_text) == 0.0 || reg.count <= 0.0) {
        return VetoResult {
            is_vetoed: 0.0,
            output_text: candidate_text,
            violated_rule_id: -1.0,
            violation_pattern: ""
        };
    }

    let lower_text = veto_string_to_lower(candidate_text);

    var r_idx = 0.0;
    while (r_idx < reg.count) {
        let patterns = cartan_tree_get_f32(reg.pattern_trees, r_idx);
        if (patterns != 0.0) {
            let pat_count = cartan_tree_len_f(patterns);
            var p_idx = 0.0;
            while (p_idx < pat_count) {
                let raw_pat = cartan_tree_get_f32(patterns, p_idx);
                let pat = veto_string_to_lower(raw_pat);
                if (cartan_string_contains(lower_text, pat) != 0.0) {
                    // Contradiction detected ($P \land \neg P$): Trigger instant veto
                    let r_id = collections_list_get(reg.rule_ids, r_idx);
                    let canon_assert = cartan_tree_get_f32(reg.canonical_assertions, r_idx);
                    free(lower_text);
                    free(pat);
                    return VetoResult {
                        is_vetoed: 1.0,
                        output_text: canon_assert,
                        violated_rule_id: r_id,
                        violation_pattern: raw_pat
                    };
                }
                free(pat);
                p_idx = p_idx + 1.0;
            }
        }
        r_idx = r_idx + 1.0;
    }

    free(lower_text);
    return VetoResult {
        is_vetoed: 0.0,
        output_text: candidate_text,
        violated_rule_id: -1.0,
        violation_pattern: ""
    };
}

// Populates default canonical physical invariants and contradiction triggers for Domain 0 (SYSTEM_CORE)
fn veto_registry_populate_defaults(reg: VetoRegistry) {
    // 1. Conservation of Energy & First Law of Thermodynamics
    let p1 = cartan_tree_create();
    cartan_tree_push(p1, "energy can be created");
    cartan_tree_push(p1, "energy can be destroyed");
    cartan_tree_push(p1, "energy increases exponentially");
    cartan_tree_push(p1, "energy is not conserved");
    cartan_tree_push(p1, "energy is unbounded");
    cartan_tree_push(p1, "conservation of energy is violated");
    cartan_tree_push(p1, "perpetual motion generates free energy");
    cartan_tree_push(p1, "energy appears from nothing");
    cartan_tree_push(p1, "energy vanishes into nothing");
    veto_registry_add_rule(
        reg,
        1.0,
        0.0,
        "In accordance with the first law of thermodynamics, energy cannot be created or destroyed; kinetic energy in an inelastic impact is dissipated as thermal energy and deformation.",
        p1
    );

    // 2. Second Law of Thermodynamics & Entropy Non-Decrease
    let p2 = cartan_tree_create();
    cartan_tree_push(p2, "entropy decreases in an isolated system");
    cartan_tree_push(p2, "heat flows spontaneously from cold to hot");
    cartan_tree_push(p2, "reversed thermodynamic arrow of time");
    cartan_tree_push(p2, "entropy can be arbitrarily destroyed");
    veto_registry_add_rule(
        reg,
        2.0,
        0.0,
        "In accordance with the second law of thermodynamics, total entropy in an isolated thermodynamic system can never spontaneously decrease over time.",
        p2
    );

    // 3. Special Relativity & Vacuum Speed of Light Limit
    let p3 = cartan_tree_create();
    cartan_tree_push(p3, "faster than light travel with mass");
    cartan_tree_push(p3, "mass accelerates beyond c");
    cartan_tree_push(p3, "superluminal physical propagation");
    cartan_tree_push(p3, "speed exceeds light speed");
    veto_registry_add_rule(
        reg,
        3.0,
        0.0,
        "In accordance with special relativity, no physical mass or causal signal can propagate through spacetime faster than the vacuum speed of light c.",
        p3
    );

    // 4. Fundamental Law of Non-Contradiction
    let p4 = cartan_tree_create();
    cartan_tree_push(p4, "two plus two equals five");
    cartan_tree_push(p4, "contradictions are simultaneously true");
    cartan_tree_push(p4, "one equals zero");
    cartan_tree_push(p4, "axioms are discarded");
    veto_registry_add_rule(
        reg,
        4.0,
        0.0,
        "In accordance with the foundational axioms of mathematical logic, contradictory propositions (P and not P) cannot be simultaneously asserted.",
        p4
    );

    // 5. Momentum Conservation (Domain 1: PHYSICS_SIM)
    let p5 = cartan_tree_create();
    cartan_tree_push(p5, "momentum is not conserved");
    cartan_tree_push(p5, "momentum appears from nowhere");
    cartan_tree_push(p5, "net force is zero but momentum changes");
    veto_registry_add_rule(
        reg,
        5.0,
        1.0,
        "In accordance with classical mechanics, total linear momentum is strictly conserved in all closed physical collision systems.",
        p5
    );

    // 6. Central Dogma & Free Energy (Domain 4: BIOLOGICAL_SYSTEMS)
    let p6 = cartan_tree_create();
    cartan_tree_push(p6, "protein synthesizes dna directly");
    cartan_tree_push(p6, "cells do not require energy");
    cartan_tree_push(p6, "spontaneous generation without ancestors");
    veto_registry_add_rule(
        reg,
        6.0,
        4.0,
        "In accordance with biological invariants, living metabolic cells require continuous free energy input, and genetic information flows directionally from DNA to RNA to protein.",
        p6
    );

    // 7. Causal Precedence & Taxonomic Exclusion (Domain 5: CAUSAL_TAXONOMY)
    let p7 = cartan_tree_create();
    cartan_tree_push(p7, "effects precede their causes");
    cartan_tree_push(p7, "an organism is both plant and animal");
    cartan_tree_push(p7, "reverse temporal causality");
    veto_registry_add_rule(
        reg,
        7.0,
        5.0,
        "In accordance with causal and taxonomic invariants, causes strictly precede their effects in time, and organisms cannot hold mutually exclusive kingdom classifications.",
        p7
    );

    // 8. Linguistic Invariants & Communicative Pragmatics (Domain 6: LANGUAGE_DISCOURSE)
    let p8 = cartan_tree_create();
    cartan_tree_push(p8, "words have no meaning");
    cartan_tree_push(p8, "language cannot communicate");
    cartan_tree_push(p8, "questions do not require answers");
    cartan_tree_push(p8, "statements contradict their premises");
    cartan_tree_push(p8, "grammar has no rules");
    cartan_tree_push(p8, "pronouns have no antecedents");
    veto_registry_add_rule(
        reg,
        8.0,
        6.0,
        "In accordance with communicative pragmatics, language conveys structured meaning through shared vocabulary, grammatical syntax, and coherent speech acts.",
        p8
    );

    // Register Default Contradiction Tokens across Cognitive Domains
    // Domain 0: SYSTEM_CORE (Energy destruction, perpetual motion, causality violations)
    veto_registry_add_forbidden_token(reg, 0.0, 101.0);
    veto_registry_add_forbidden_token(reg, 0.0, 102.0);
    veto_registry_add_forbidden_token(reg, 0.0, 103.0);

    // Domain 6: LANGUAGE_DISCOURSE (Nonsense, meaninglessness, grammar denial)
    veto_registry_add_forbidden_token(reg, 6.0, 601.0);
    veto_registry_add_forbidden_token(reg, 6.0, 602.0);
    veto_registry_add_forbidden_token(reg, 6.0, 603.0);
    veto_registry_add_forbidden_token(reg, 6.0, 604.0);
}

// Computes analytical symbolic penalty across output logits to shape training loss
// Directly penalizes logits corresponding to forbidden / contradictory tokens for the active domain
fn veto_compute_symbolic_loss_penalty(reg: VetoRegistry, active_domain: float, logits_vec: ptr, forbidden_token_ids: ptr, lambda_sym: float) -> float {
    if (logits_vec == 0.0 || lambda_sym <= 0.0) { return 0.0; }
    let v_len = cartan_vec_len(logits_vec);
    if (v_len == 0.0) { return 0.0; }

    var penalty_loss = 0.0;

    // 1. Explicit forbidden token IDs
    if (forbidden_token_ids != 0.0) {
        let num_toks = cartan_vec_len(forbidden_token_ids);
        var i = 0.0;
        while (i < num_toks) {
            let tok = cartan_vec_get_f32(forbidden_token_ids, i);
            if (tok >= 0.0 && tok < v_len) {
                let cur_z = cartan_vec_get_f32(logits_vec, tok);
                let pen = lambda_sym * 15.0;
                cartan_vec_set_f32(logits_vec, tok, cur_z - pen);
                let exp_z = exp(cur_z / 10.0);
                if (exp_z > 0.0) {
                    penalty_loss = penalty_loss + (lambda_sym * exp_z * 0.01);
                }
            }
            i = i + 1.0;
        }
    }

    // 2. Automated domain contradiction tokens from veto registry
    if (reg.domain_forbidden_tokens != 0.0) {
        // Universal Domain 0 Invariants (Always checked)
        let d0_list = cartan_tree_get_f32(reg.domain_forbidden_tokens, 0.0);
        if (d0_list != 0.0) {
            let d0_len = collections_list_len(d0_list);
            var j = 0.0;
            while (j < d0_len) {
                let tok0 = collections_list_get(d0_list, j);
                if (tok0 >= 0.0 && tok0 < v_len) {
                    let cur_z = cartan_vec_get_f32(logits_vec, tok0);
                    let pen = lambda_sym * 15.0;
                    cartan_vec_set_f32(logits_vec, tok0, cur_z - pen);
                    let exp_z = exp(cur_z / 10.0);
                    if (exp_z > 0.0) {
                        penalty_loss = penalty_loss + (lambda_sym * exp_z * 0.01);
                    }
                }
                j = j + 1.0;
            }
        }

        // Active domain specific invariants
        if (active_domain > 0.0 && active_domain < 8.0) {
            let da_list = cartan_tree_get_f32(reg.domain_forbidden_tokens, active_domain);
            if (da_list != 0.0) {
                let da_len = collections_list_len(da_list);
                var k = 0.0;
                while (k < da_len) {
                    let tok_a = collections_list_get(da_list, k);
                    if (tok_a >= 0.0 && tok_a < v_len) {
                        let cur_z = cartan_vec_get_f32(logits_vec, tok_a);
                        let pen = lambda_sym * 15.0;
                        cartan_vec_set_f32(logits_vec, tok_a, cur_z - pen);
                        let exp_z = exp(cur_z / 10.0);
                        if (exp_z > 0.0) {
                            penalty_loss = penalty_loss + (lambda_sym * exp_z * 0.01);
                        }
                    }
                    k = k + 1.0;
                }
            }
        }
    }

    return penalty_loss;
}

