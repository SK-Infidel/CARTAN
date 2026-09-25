// src/std/sat_solver.cl
// CARTAN Standard Library: Propositional 2-SAT & Horn Clause Axiomatic Consistency Verifier
// Neuro-Symbolic Expert System (NSES) Phase 2 Core

include "src/std/math.cl";
include "src/std/collections.cl";
include "src/std/string.cl";

// Relation types for knowledge edges
// REL_REQUIRES: A implies B (A -> B, neg(B) -> neg(A))
// REL_CONTRADICTS: A and B are mutually exclusive (A -> neg(B), B -> neg(A))
// REL_EQUIVALENT: A if and only if B (A <-> B)
// REL_AXIOM: A is unconditionally true (neg(A) -> pos(A))

// Structure representing the 2-SAT Implication Graph & Consistency Solver
struct SatSolver {
    num_vars: float;
    max_literals: float;
    fwd_head: ptr;       // Forward adjacency head pointers [0 .. 2*N - 1]
    fwd_to: ptr;         // Forward edge destinations
    fwd_next: ptr;       // Forward edge next pointers
    fwd_count: float;
    rev_head: ptr;       // Reverse adjacency head pointers [0 .. 2*N - 1]
    rev_to: ptr;         // Reverse edge destinations
    rev_next: ptr;       // Reverse edge next pointers
    rev_count: float;
    axioms: ptr;         // List of variable indices marked as strict axioms
    conflict_found: float; // 1.0 if conflict detected, 0.0 otherwise
    conflict_var1: float;
    conflict_var2: float;
    conflict_type: float; // 1.0 = Direct, 2.0 = SCC Cycle, 3.0 = Axiom Reachability
}

// Convert variable index v to positive literal (pos = 2*v)
fn sat_lit_pos(var_idx: float) -> float {
    return 2.0 * var_idx;
}

// Convert variable index v to negated literal (neg = 2*v + 1)
fn sat_lit_neg(var_idx: float) -> float {
    return (2.0 * var_idx) + 1.0;
}

// Negate a literal: pos <-> neg
fn sat_lit_not(lit: float) -> float {
    let rem = math_mod_val(lit, 2.0);
    if (rem == 0.0) {
        return lit + 1.0;
    }
    return lit - 1.0;
}

// Extract variable index from literal
fn sat_lit_to_var(lit: float) -> float {
    return floor(lit / 2.0);
}

// Check if literal is positive
fn sat_lit_is_pos(lit: float) -> float {
    if (math_mod_val(lit, 2.0) == 0.0) {
        return 1.0;
    }
    return 0.0;
}

// Create an initialized SatSolver for N variables
fn sat_solver_create(num_vars: float) -> SatSolver {
    let max_lits = 2.0 * num_vars;
    let f_head = collections_create_list();
    let r_head = collections_create_list();
    
    var i = 0.0;
    while (i < max_lits) {
        collections_list_push(f_head, -1.0);
        collections_list_push(r_head, -1.0);
        i = i + 1.0;
    }

    return SatSolver {
        num_vars: num_vars,
        max_literals: max_lits,
        fwd_head: f_head,
        fwd_to: collections_create_list(),
        fwd_next: collections_create_list(),
        fwd_count: 0.0,
        rev_head: r_head,
        rev_to: collections_create_list(),
        rev_next: collections_create_list(),
        rev_count: 0.0,
        axioms: collections_create_list(),
        conflict_found: 0.0,
        conflict_var1: -1.0,
        conflict_var2: -1.0,
        conflict_type: 0.0
    };
}

// Add raw directed implication edge: from_lit -> to_lit
fn sat_add_directed_edge(solver: SatSolver, from_lit: float, to_lit: float) {
    if (from_lit < 0.0 || from_lit >= solver.max_literals || to_lit < 0.0 || to_lit >= solver.max_literals) {
        return;
    }
    // Add forward edge
    let f_edge_idx = collections_list_len(solver.fwd_to);
    collections_list_push(solver.fwd_to, to_lit);
    let old_f_head = collections_list_get(solver.fwd_head, from_lit);
    collections_list_push(solver.fwd_next, old_f_head);
    collections_list_set(solver.fwd_head, from_lit, f_edge_idx);
    solver.fwd_count = solver.fwd_count + 1.0;

    // Add reverse edge
    let r_edge_idx = collections_list_len(solver.rev_to);
    collections_list_push(solver.rev_to, from_lit);
    let old_r_head = collections_list_get(solver.rev_head, to_lit);
    collections_list_push(solver.rev_next, old_r_head);
    collections_list_set(solver.rev_head, to_lit, r_edge_idx);
    solver.rev_count = solver.rev_count + 1.0;
}

// Add implication clause: var_a => var_b
// In 2-CNF: (not(A) or B) <=> (A -> B) and (not(B) -> not(A))
fn sat_add_implication(solver: SatSolver, var_a: float, var_b: float) {
    let p_a = sat_lit_pos(var_a);
    let n_a = sat_lit_neg(var_a);
    let p_b = sat_lit_pos(var_b);
    let n_b = sat_lit_neg(var_b);

    // Forward: A -> B
    sat_add_directed_edge(solver, p_a, p_b);
    // Contrapositive: not(B) -> not(A)
    sat_add_directed_edge(solver, n_b, n_a);
}

// Add requirement: var_a requires var_b (equivalent to implication var_a => var_b)
fn sat_add_requirement(solver: SatSolver, var_a: float, var_b: float) {
    sat_add_implication(solver, var_a, var_b);
}

// Add contradiction / mutual exclusion: var_a and var_b cannot both hold
// In 2-CNF: (not(A) or not(B)) <=> (A -> not(B)) and (B -> not(A))
fn sat_add_contradiction(solver: SatSolver, var_a: float, var_b: float) {
    let p_a = sat_lit_pos(var_a);
    let n_a = sat_lit_neg(var_a);
    let p_b = sat_lit_pos(var_b);
    let n_b = sat_lit_neg(var_b);

    // A -> not(B)
    sat_add_directed_edge(solver, p_a, n_b);
    // B -> not(A)
    sat_add_directed_edge(solver, p_b, n_a);
}

// Add equivalence: var_a <=> var_b
fn sat_add_equivalence(solver: SatSolver, var_a: float, var_b: float) {
    sat_add_implication(solver, var_a, var_b);
    sat_add_implication(solver, var_b, var_a);
}

// Assert strict axiom: var_a must be unconditionally TRUE
fn sat_assert_axiom(solver: SatSolver, var_a: float) {
    collections_list_push(solver.axioms, var_a);
}

// Check reachability between two literals in the implication graph using BFS
fn sat_is_reachable(solver: SatSolver, start_lit: float, target_lit: float) -> float {
    if (start_lit == target_lit) { return 1.0; }
    let visited = collections_create_list();
    var i = 0.0;
    while (i < solver.max_literals) {
        collections_list_push(visited, 0.0);
        i = i + 1.0;
    }

    let q = collections_create_list();
    collections_list_push(q, start_lit);
    collections_list_set(visited, start_lit, 1.0);

    var q_head = 0.0;
    var reached = 0.0;
    while (q_head < collections_list_len(q)) {
        let curr = collections_list_get(q, q_head);
        q_head = q_head + 1.0;

        if (curr == target_lit) {
            reached = 1.0;
            break;
        }

        var e = collections_list_get(solver.fwd_head, curr);
        while (e >= 0.0) {
            let nxt = collections_list_get(solver.fwd_to, e);
            if (collections_list_get(visited, nxt) == 0.0) {
                collections_list_set(visited, nxt, 1.0);
                collections_list_push(q, nxt);
            }
            e = collections_list_get(solver.fwd_next, e);
        }
    }

    collections_free_list(visited);
    collections_free_list(q);
    return reached;
}

// Aspvall-Plass-Tarjan 2-SAT SCC Verifier:
// Formula is satisfiable if and only if no variable v has pos(v) and neg(v) in the same SCC.
fn sat_check_scc_satisfiability(solver: SatSolver) -> float {
    let visited = collections_create_list();
    let order = collections_create_list();
    let stack = collections_create_list();
    let edge_cur = collections_create_list();

    var i = 0.0;
    while (i < solver.max_literals) {
        collections_list_push(visited, 0.0);
        collections_list_push(edge_cur, -1.0);
        i = i + 1.0;
    }

    // Pass 1: Iterative post-order traversal on forward graph
    var root = 0.0;
    while (root < solver.max_literals) {
        if (collections_list_get(visited, root) == 0.0) {
            collections_list_push(stack, root);
            collections_list_set(visited, root, 1.0);
            let first_e = collections_list_get(solver.fwd_head, root);
            collections_list_set(edge_cur, root, first_e);

            while (collections_list_len(stack) > 0.0) {
                let u = collections_list_get(stack, collections_list_len(stack) - 1.0);
                let e = collections_list_get(edge_cur, u);
                if (e >= 0.0) {
                    let nxt_e = collections_list_get(solver.fwd_next, e);
                    collections_list_set(edge_cur, u, nxt_e);
                    let v = collections_list_get(solver.fwd_to, e);
                    if (collections_list_get(visited, v) == 0.0) {
                        collections_list_set(visited, v, 1.0);
                        collections_list_push(stack, v);
                        let v_e = collections_list_get(solver.fwd_head, v);
                        collections_list_set(edge_cur, v, v_e);
                    }
                } else {
                    collections_list_pop(stack);
                    collections_list_push(order, u);
                }
            }
        }
        root = root + 1.0;
    }

    // Pass 2: Iterative DFS on reverse graph to assign components
    var j = 0.0;
    while (j < solver.max_literals) {
        collections_list_set(visited, j, 0.0);
        j = j + 1.0;
    }
    let comp = collections_create_list();
    j = 0.0;
    while (j < solver.max_literals) {
        collections_list_push(comp, -1.0);
        j = j + 1.0;
    }

    var comp_id = 1.0;
    var ord_idx = collections_list_len(order) - 1.0;
    while (ord_idx >= 0.0) {
        let u = collections_list_get(order, ord_idx);
        if (collections_list_get(visited, u) == 0.0) {
            collections_list_push(stack, u);
            collections_list_set(visited, u, 1.0);
            collections_list_set(comp, u, comp_id);

            while (collections_list_len(stack) > 0.0) {
                let curr = collections_list_pop(stack);
                var re = collections_list_get(solver.rev_head, curr);
                while (re >= 0.0) {
                    let r_tgt = collections_list_get(solver.rev_to, re);
                    if (collections_list_get(visited, r_tgt) == 0.0) {
                        collections_list_set(visited, r_tgt, 1.0);
                        collections_list_set(comp, r_tgt, comp_id);
                        collections_list_push(stack, r_tgt);
                    }
                    re = collections_list_get(solver.rev_next, re);
                }
            }
            comp_id = comp_id + 1.0;
        }
        ord_idx = ord_idx - 1.0;
    }

    // Pass 3: Check if any variable has pos and neg in same component
    var is_sat = 1.0;
    var var_i = 0.0;
    while (var_i < solver.num_vars) {
        let p_lit = sat_lit_pos(var_i);
        let n_lit = sat_lit_neg(var_i);
        let c_pos = collections_list_get(comp, p_lit);
        let c_neg = collections_list_get(comp, n_lit);
        if (c_pos == c_neg && c_pos > 0.0) {
            is_sat = 0.0;
            solver.conflict_found = 1.0;
            solver.conflict_var1 = var_i;
            solver.conflict_var2 = var_i;
            solver.conflict_type = 2.0; // SCC Cycle Contradiction
            break;
        }
        var_i = var_i + 1.0;
    }

    collections_free_list(visited);
    collections_free_list(order);
    collections_free_list(stack);
    collections_free_list(edge_cur);
    collections_free_list(comp);
    return is_sat;
}

// Axiomatic Verification Pass:
// For every strict invariant/axiom A:
// Verify pos(A) cannot reach neg(A) AND pos(A) cannot reach neg(B) for any other active axiom B.
fn sat_check_axiomatic_consistency(solver: SatSolver) -> float {
    let num_ax = collections_list_len(solver.axioms);
    if (num_ax == 0.0) { return 1.0; }

    var i = 0.0;
    while (i < num_ax) {
        let var_a = collections_list_get(solver.axioms, i);
        let p_a = sat_lit_pos(var_a);
        let n_a = sat_lit_neg(var_a);

        // Check if axiom implies its own negation: A -> not(A)
        if (sat_is_reachable(solver, p_a, n_a) != 0.0) {
            solver.conflict_found = 1.0;
            solver.conflict_var1 = var_a;
            solver.conflict_var2 = var_a;
            solver.conflict_type = 3.0; // Axiom Self-Violation
            return 0.0;
        }

        // Check against other axioms
        var j = 0.0;
        while (j < num_ax) {
            if (i != j) {
                let var_b = collections_list_get(solver.axioms, j);
                let n_b = sat_lit_neg(var_b);
                // If axiom A implies not(B) while B is also an active axiom: conflict!
                if (sat_is_reachable(solver, p_a, n_b) != 0.0) {
                    solver.conflict_found = 1.0;
                    solver.conflict_var1 = var_a;
                    solver.conflict_var2 = var_b;
                    solver.conflict_type = 3.0; // Axiom Cross-Contradiction
                    return 0.0;
                }
            }
            j = j + 1.0;
        }
        i = i + 1.0;
    }
    return 1.0;
}

// Direct Contradiction Pass:
// Check if rule A directly requires B and directly contradicts B.
fn sat_check_direct_contradictions(solver: SatSolver) -> float {
    var u = 0.0;
    while (u < solver.num_vars) {
        let p_u = sat_lit_pos(u);
        var e1 = collections_list_get(solver.fwd_head, p_u);
        while (e1 >= 0.0) {
            let lit_dst = collections_list_get(solver.fwd_to, e1);
            let var_dst = sat_lit_to_var(lit_dst);
            if (sat_lit_is_pos(lit_dst) != 0.0) {
                // p_u -> pos(var_dst). Check if p_u also has edge to neg(var_dst)
                var e2 = collections_list_get(solver.fwd_head, p_u);
                while (e2 >= 0.0) {
                    let lit_dst2 = collections_list_get(solver.fwd_to, e2);
                    if (lit_dst2 == sat_lit_neg(var_dst)) {
                        solver.conflict_found = 1.0;
                        solver.conflict_var1 = u;
                        solver.conflict_var2 = var_dst;
                        solver.conflict_type = 1.0; // Direct Contradiction
                        return 0.0;
                    }
                    e2 = collections_list_get(solver.fwd_next, e2);
                }
            }
            e1 = collections_list_get(solver.fwd_next, e1);
        }
        u = u + 1.0;
    }
    return 1.0;
}

// Unified SMT/SAT Solver Entry Point:
// Runs Direct, 2-SAT SCC, and Axiomatic verification passes.
// Returns 1.0 if strictly consistent, 0.0 if logical contradiction detected.
fn sat_solve_consistency(solver: SatSolver) -> float {
    solver.conflict_found = 0.0;
    solver.conflict_var1 = -1.0;
    solver.conflict_var2 = -1.0;
    solver.conflict_type = 0.0;

    // 1. Direct contradiction check
    if (sat_check_direct_contradictions(solver) == 0.0) {
        return 0.0;
    }

    // 2. 2-SAT Aspvall-Plass-Tarjan SCC cycle check
    if (sat_check_scc_satisfiability(solver) == 0.0) {
        return 0.0;
    }

    // 3. Axiomatic invariant reachability check
    if (sat_check_axiomatic_consistency(solver) == 0.0) {
        return 0.0;
    }

    return 1.0;
}

// Free SatSolver memory structures
fn sat_solver_free(solver: SatSolver) {
    if (solver.fwd_head != 0.0) { collections_free_list(solver.fwd_head); }
    if (solver.fwd_to != 0.0) { collections_free_list(solver.fwd_to); }
    if (solver.fwd_next != 0.0) { collections_free_list(solver.fwd_next); }
    if (solver.rev_head != 0.0) { collections_free_list(solver.rev_head); }
    if (solver.rev_to != 0.0) { collections_free_list(solver.rev_to); }
    if (solver.rev_next != 0.0) { collections_free_list(solver.rev_next); }
    if (solver.axioms != 0.0) { collections_free_list(solver.axioms); }
}
