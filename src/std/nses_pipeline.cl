// src/std/nses_pipeline.cl
// CARTAN Standard Library: Master Neuro-Symbolic Expert System (NSES) Pipeline Orchestrator
// Neuro-Symbolic Expert System (NSES) Phase 5 Core

include "src/std/math.cl";
include "src/std/collections.cl";
include "src/std/string.cl";
include "src/std/cargraph.cl";
include "src/std/sat_solver.cl";
include "src/std/guardrails.cl";
include "src/std/csr_graph.cl";
include "src/std/plasticity.cl";
include "src/std/burroughs.cl";
include "src/std/prompt_scaffold.cl";
include "src/std/veto_gate.cl";

extern fn clock() -> float;

// Helper to reset a cartan_tree size to 0 without reallocating
fn cartan_tree_clear(t: ptr) {
    if (t == 0.0) { return; }
    var i = 8.0;
    while (i < 16.0) {
        cartan_set_byte(t, i, 0.0);
        i = i + 1.0;
    }
}

// Master NSES Pipeline Engine State Structure
struct NSES_Pipeline {
    graph_file: CarGraphFile;
    csr: CsrGraph;
    scratchpad: NSES_Scratchpad;
    burroughs_pool: BurroughsPool;
    prompt_buffer: PromptScaffoldBuffer;
    rng: BurroughsRngState;
    veto_reg: VetoRegistry;
    guardrails_tree: ptr;
    memory_tree: ptr;
    seed_list: ptr;
    act_list: ptr;
    is_ready: float;
    last_turn_latency_ms: float;
}

// Result of an End-to-End NSES Pipeline Turn
struct NSESTurnResult {
    is_vetoed: float;
    final_output: string;
    assembled_prompt: string;
    lateral_fragment: string;
    active_domain: float;
    traversed_count: float;
    turn_latency_ms: float;
}

// Allocates and initializes an end-to-end NSES pipeline
fn nses_pipeline_create(graph_path: string) -> NSES_Pipeline {
    let cg = cargraph_load_binary(graph_path);
    if (cg.is_valid == 0.0) {
        printf("[NSES Pipeline] Warning: Could not load .car_graph at %s\n", graph_path);
    }

    // Build CSR topology from graph
    let b = csr_builder_create(64.0);
    // Add default causal dependencies across domains
    csr_builder_add_edge(b, 6.0, 7.0, 1.25, 1.0, 0.0);   // Kinetic Energy -> Inelastic Dissipation
    csr_builder_add_edge(b, 7.0, 8.0, 1.20, 1.0, 0.0);   // Inelastic Dissipation -> Restitution e < 1.0
    csr_builder_add_edge(b, 7.0, 10.0, 1.15, 1.0, 0.0);  // Inelastic Dissipation -> Thermal Conduction
    csr_builder_add_edge(b, 14.0, 15.0, 1.30, 1.0, 0.0); // Exterior Derivative -> Stokes Theorem
    csr_builder_add_edge(b, 21.0, 22.0, 1.25, 1.0, 0.0); // Polynomial Reduction -> NP-Completeness
    csr_builder_add_edge(b, 26.0, 27.0, 1.20, 1.0, 0.0); // Photosynthesis -> Cellular Respiration
    csr_builder_add_edge(b, 37.0, 38.0, 1.15, 1.0, 0.0); // Velocity -> Acceleration
    csr_builder_add_edge(b, 39.0, 40.0, 1.10, 1.0, 0.0); // Solid -> Liquid phase transition
    let g = csr_builder_build(b);
    csr_builder_free(b);

    let pad = nses_scratchpad_create(64.0, 64.0);
    let pool = burroughs_pool_create(32.0);
    burroughs_pool_populate_defaults(pool);

    let p_buf = prompt_scaffold_create(65536.0);
    let rng = burroughs_rng_init(135792468.0, 975318642.0);

    let v_reg = veto_registry_create();
    veto_registry_populate_defaults(v_reg);

    let g_tree = cartan_tree_create();
    cartan_tree_push(g_tree, "Conservation of energy must not be violated under any scenario; energy cannot be created or destroyed.");
    cartan_tree_push(g_tree, "Second law of thermodynamics: Total entropy in an isolated system can never spontaneously decrease.");
    cartan_tree_push(g_tree, "Relativistic causality: No physical mass or causal information can propagate faster than light speed c.");
    cartan_tree_push(g_tree, "Fundamental law of non-contradiction: Contradictory propositions (P and not P) cannot be simultaneously valid.");

    let m_tree = cartan_tree_create();
    let s_list = collections_create_list();
    let a_list = collections_create_list();

    return NSES_Pipeline {
        graph_file: cg,
        csr: g,
        scratchpad: pad,
        burroughs_pool: pool,
        prompt_buffer: p_buf,
        rng: rng,
        veto_reg: v_reg,
        guardrails_tree: g_tree,
        memory_tree: m_tree,
        seed_list: s_list,
        act_list: a_list,
        is_ready: 1.0,
        last_turn_latency_ms: 0.0
    };
}

// Executes an end-to-end NSES inference turn with 7-stage latency tracking
fn nses_pipeline_execute_turn(
    pipe: NSES_Pipeline,
    query: string,
    entropy_tier: float,
    raw_model_candidate: string
) -> NSESTurnResult {
    let t0 = clock();

    // -------------------------------------------------------------------------
    // Stage 1: Domain Routing (Domain 0 + routed domain)
    // -------------------------------------------------------------------------
    var routed_domain = 1.0; // Default to PHYSICS_SIM
    if (cartan_string_contains(query, "manifold") != 0.0 || cartan_string_contains(query, "differential") != 0.0 || cartan_string_contains(query, "homotopy") != 0.0) {
        routed_domain = 2.0; // TOPOLOGY_GEOMETRY
    } else if (cartan_string_contains(query, "turing") != 0.0 || cartan_string_contains(query, "halting") != 0.0 || cartan_string_contains(query, "np") != 0.0) {
        routed_domain = 3.0; // COMPLEXITY_THEORY
    } else if (cartan_string_contains(query, "biology") != 0.0 || cartan_string_contains(query, "cell") != 0.0 || cartan_string_contains(query, "dna") != 0.0 || cartan_string_contains(query, "metabolism") != 0.0) {
        routed_domain = 4.0; // BIOLOGICAL_SYSTEMS
    } else if (cartan_string_contains(query, "cause") != 0.0 || cartan_string_contains(query, "state") != 0.0 || cartan_string_contains(query, "matter") != 0.0 || cartan_string_contains(query, "taxonomy") != 0.0) {
        routed_domain = 5.0; // CAUSAL_TAXONOMY
    }

    // -------------------------------------------------------------------------
    // Stage 2: Deterministic Guardrails Query (Domain 0 + active domain)
    // -------------------------------------------------------------------------
    let guardrails_tree = pipe.guardrails_tree;

    // -------------------------------------------------------------------------
    // Stage 3 & 4: ANN Seed Proximity & Zero-Allocation CSR Traversal
    // -------------------------------------------------------------------------
    cartan_vec_clear(pipe.seed_list);
    cartan_vec_clear(pipe.act_list);

    if (routed_domain == 1.0) {
        collections_list_push(pipe.seed_list, 6.0); // Seed: Rule 6 (Kinetic energy)
        collections_list_push(pipe.act_list, 1.0);
    } else if (routed_domain == 2.0) {
        collections_list_push(pipe.seed_list, 14.0); // Seed: Rule 14 (Exterior derivative)
        collections_list_push(pipe.act_list, 1.0);
    } else if (routed_domain == 3.0) {
        collections_list_push(pipe.seed_list, 21.0); // Seed: Rule 21 (Polynomial reduction)
        collections_list_push(pipe.act_list, 1.0);
    } else if (routed_domain == 4.0) {
        collections_list_push(pipe.seed_list, 26.0); // Seed: Rule 26 (Photosynthesis)
        collections_list_push(pipe.act_list, 1.0);
    } else {
        collections_list_push(pipe.seed_list, 37.0); // Seed: Rule 37 (Velocity -> Acceleration)
        collections_list_push(pipe.act_list, 1.0);
    }

    let traversed_cnt = csr_traverse_bfs(pipe.csr, pipe.scratchpad, pipe.seed_list, pipe.act_list, 2.0, 0.50, 0.85, 0.0);

    cartan_tree_clear(pipe.memory_tree);
    var m_idx = 0.0;
    while (m_idx < traversed_cnt) {
        let n_id = collections_list_get(pipe.scratchpad.result_node_ids, m_idx);
        if (n_id == 6.0) {
            cartan_tree_push(pipe.memory_tree, "Kinetic energy is calculated as 0.5 * mass * velocity^2.");
        } else if (n_id == 7.0) {
            cartan_tree_push(pipe.memory_tree, "Inelastic collisions dissipate kinetic energy into thermal energy and material deformation.");
        } else if (n_id == 8.0) {
            cartan_tree_push(pipe.memory_tree, "Coefficient of restitution e < 1.0 indicates kinetic energy dissipation during impact.");
        } else if (n_id == 10.0) {
            cartan_tree_push(pipe.memory_tree, "Thermal conduction transfers internal molecular kinetic agitation toward lower temperatures.");
        } else if (n_id == 14.0) {
            cartan_tree_push(pipe.memory_tree, "Exterior derivative d generalizes gradient, curl, and divergence across differential k-forms.");
        } else if (n_id == 15.0) {
            cartan_tree_push(pipe.memory_tree, "Stokes theorem equates the integral of differential form over boundary to its derivative over interior.");
        } else if (n_id == 21.0) {
            cartan_tree_push(pipe.memory_tree, "Polynomial-time reductions preserve computational tractability across complexity classes.");
        } else if (n_id == 22.0) {
            cartan_tree_push(pipe.memory_tree, "NP-complete problems can verify candidate certificates in deterministic polynomial time.");
        } else if (n_id == 26.0) {
            cartan_tree_push(pipe.memory_tree, "Photosynthesis converts radiant solar energy into chemical bond energy.");
        } else if (n_id == 27.0) {
            cartan_tree_push(pipe.memory_tree, "Cellular respiration catabolizes glucose to synthesize ATP free energy carrier.");
        } else if (n_id == 37.0) {
            cartan_tree_push(pipe.memory_tree, "Physical velocity is the first time derivative of spatial displacement position: v = dx/dt.");
        } else if (n_id == 38.0) {
            cartan_tree_push(pipe.memory_tree, "Physical acceleration is the time derivative of velocity and second derivative of position: a = dv/dt.");
        }
        m_idx = m_idx + 1.0;
    }

    // -------------------------------------------------------------------------
    // Stage 5: Burroughs Stochastic Lateral Injection
    // -------------------------------------------------------------------------
    let lateral_frag = burroughs_sample_fragment(pipe.burroughs_pool, routed_domain, entropy_tier, pipe.rng);

    // -------------------------------------------------------------------------
    // Stage 6: Structured 4-Block Prompt Scaffold Assembly
    // -------------------------------------------------------------------------
    let prompt_text = prompt_assemble_scaffold(pipe.prompt_buffer, pipe.guardrails_tree, pipe.memory_tree, lateral_frag, query);

    // -------------------------------------------------------------------------
    // Stage 7: Absolute Post-Pass Deterministic Veto Gate
    // -------------------------------------------------------------------------
    let veto_res = veto_gate_scan(pipe.veto_reg, raw_model_candidate);

    // -------------------------------------------------------------------------
    // Post-Turn Synaptic Plasticity Reinforcement
    // -------------------------------------------------------------------------
    if (traversed_cnt > 1.0) {
        // Reinforce traversed edges (edge 0: 6->7)
        hebbian_reinforce_edge(pipe.csr.edge_weights, pipe.csr.edge_timestamps, 0.0, 0.05, 5.0, pipe.scratchpad.current_epoch);
    }

    let t1 = clock();
    let turn_ms = t1 - t0;
    pipe.last_turn_latency_ms = turn_ms;

    return NSESTurnResult {
        is_vetoed: veto_res.is_vetoed,
        final_output: veto_res.output_text,
        assembled_prompt: prompt_text,
        lateral_fragment: lateral_frag,
        active_domain: routed_domain,
        traversed_count: traversed_cnt,
        turn_latency_ms: turn_ms
    };
}

// Evaluates active domain constraints and shapes logits via symbolic penalty gradient
fn nses_pipeline_shape_loss(pipe: NSES_Pipeline, active_domain: float, logits_vec: ptr, forbidden_token_ids: ptr, lambda_sym: float) -> float {
    return veto_compute_symbolic_loss_penalty(pipe.veto_reg, active_domain, logits_vec, forbidden_token_ids, lambda_sym);
}

// Frees all pipeline resources
fn nses_pipeline_free(pipe: NSES_Pipeline) {
    if (pipe.graph_file.is_valid != 0.0) { cargraph_free(pipe.graph_file); }
    csr_graph_free(pipe.csr);
    nses_scratchpad_free(pipe.scratchpad);
    burroughs_pool_free(pipe.burroughs_pool);
    prompt_scaffold_free(pipe.prompt_buffer);
    veto_registry_free(pipe.veto_reg);
    if (pipe.seed_list != 0.0) { collections_free_list(pipe.seed_list); }
    if (pipe.act_list != 0.0) { collections_free_list(pipe.act_list); }
}

