// src/std/domain_lexicon.cl
// CARTAN Standard Library: Universal Cross-Domain Lexicon, Ontology & Discourse Framing
// Neuro-Symbolic Expert System (NSES) Phase 4 Core

include "src/std/math.cl";
include "src/std/collections.cl";
include "src/std/string.cl";

extern fn calloc(count: float, size: float) -> ptr;
extern fn free(p: ptr);
extern fn cartan_tree_create() -> ptr;
extern fn cartan_tree_push(t: ptr, item: ptr) -> void;
extern fn cartan_tree_get_f32(t: ptr, idx: float) -> ptr;
extern fn cartan_tree_len_f(t: ptr) -> float;

// Individual Lexicon Entry
struct DomainLexiconEntry {
    term: string;
    domain_id: float;
    ic_weight: float;       // Information Content weight in [0.0, 1.0]
    category_type: string;  // "entity", "predicate", "connective", "operator"
}

// Universal Cross-Domain Lexicon Container
struct DomainLexicon {
    terms_tree: ptr;
    domain_ids_list: ptr;
    ic_weights_list: ptr;
    categories_tree: ptr;
    discourse_frames_tree: ptr;
    count: float;
}

// Allocates an empty DomainLexicon registry
fn domain_lexicon_create() -> DomainLexicon {
    let t_tree = cartan_tree_create();
    let d_list = collections_create_list();
    let ic_list = collections_create_list();
    let c_tree = cartan_tree_create();
    let df_tree = cartan_tree_create();

    return DomainLexicon {
        terms_tree: t_tree,
        domain_ids_list: d_list,
        ic_weights_list: ic_list,
        categories_tree: c_tree,
        discourse_frames_tree: df_tree,
        count: 0.0
    };
}

// Registers a term into the domain lexicon with genuine Information Content weight
fn domain_lexicon_add_term(
    lex: DomainLexicon,
    term: string,
    domain_id: float,
    ic_weight: float,
    category_type: string
) -> float {
    if (term == 0.0 || cartan_string_length(term) == 0.0) { return lex.count; }
    cartan_tree_push(lex.terms_tree, term);
    collections_list_push(lex.domain_ids_list, domain_id);
    collections_list_push(lex.ic_weights_list, ic_weight);
    cartan_tree_push(lex.categories_tree, category_type);
    lex.count = lex.count + 1.0;
    return lex.count;
}

// Registers canonical discourse framing templates for each domain (0..8)
fn domain_lexicon_register_frames(lex: DomainLexicon) {
    // Domain 0: SYSTEM_CORE (Inviolable Conservation & Bound Framing)
    cartan_tree_push(lex.discourse_frames_tree, "[System Invariant Frame] Under invariant boundary conditions, state transition delta_S preserves fundamental conservation constraints without violation.");
    // Domain 1: PHYSICS_SIM (Kinematics & Momentum Dynamics Framing)
    cartan_tree_push(lex.discourse_frames_tree, "[Physical Dynamics Frame] In closed mechanical collision, linear momentum is conserved while kinetic energy dissipates through restitution coefficient e.");
    // Domain 2: TOPOLOGY_GEOMETRY (Manifold Calculus & Differential Forms Framing)
    cartan_tree_push(lex.discourse_frames_tree, "[Differential Manifold Frame] Over smooth manifold M equipped with Riemannian metric g, exterior derivative d integrates across boundary via Stokes theorem.");
    // Domain 3: COMPLEXITY_THEORY (Tractability & Reductions Framing)
    cartan_tree_push(lex.discourse_frames_tree, "[Complexity Reduction Frame] Decision problem A reduces in polynomial time to problem B (A <=_p B), establishing formal membership in computational complexity class.");
    // Domain 4: BIOLOGICAL_SYSTEMS (Metabolic & Genetic Pathways Framing)
    cartan_tree_push(lex.discourse_frames_tree, "[Biological Pathway Frame] Living cellular organism couples continuous free energy catabolism through enzymatic phosphorylation, directing information flow from DNA to RNA.");
    // Domain 5: CAUSAL_TAXONOMY (Kinematic Derivatives & Matter States Framing)
    cartan_tree_push(lex.discourse_frames_tree, "[Causal Taxonomy Frame] Entity E is classified under taxonomic genus G, where spatial displacement derivative v = dx/dt and matter phase dictates volumetric resistance.");
    // Domain 6: LANGUAGE_DISCOURSE (Conversational Pragmatics & Speech Acts Framing)
    cartan_tree_push(lex.discourse_frames_tree, "[Discourse Pragmatic Frame] In response to illocutionary speech act query Q, informative assertion A provides grounded evidence while preserving topical anaphoric agreement.");
    // Domain 7: LOGIC_REASONING (Classical Deductive Inference Framing)
    cartan_tree_push(lex.discourse_frames_tree, "[Deductive Proof Frame] Given premises P and conditional implication P -> Q, rule of inference Modus Ponens validly entails consequent conclusion Q.");
    // Domain 8: DECISION_PLANNING (Sequential Policies & Game-Theoretic Framing)
    cartan_tree_push(lex.discourse_frames_tree, "[Decision Policy Frame] Optimal action A is executable because preconditions Pre(A) are entailed in state S, maximizing recursive Bellman value V*(s) toward goal G.");
    // Domain 9: EPISTEMOLOGY_BELIEF (Epistemic Credence & Defeasible Belief Revision Framing)
    cartan_tree_push(lex.discourse_frames_tree, "[Epistemic Belief Frame] Given prior probability P(H) and likelihood ratio P(E|H), empirical evidence E updates posterior credence P(H|E) via Bayes rule, minimally revising commitments under AGM contraction.");
    // Domain 10: COMPILER_SYSTEMS (Software Architecture, Compilers & Type Systems Framing)
    cartan_tree_push(lex.discourse_frames_tree, "[Compiler Architecture Frame] Under static single assignment (SSA) and type soundness constraints, source syntax lowers into canonical intermediate representation preserving memory exclusivity and type safety without stuck states.");
    // Domain 11: INFORMATION_CYBERNETICS (Feedback Dynamics & Channel Bounds Framing)
    cartan_tree_push(lex.discourse_frames_tree, "[Information Cybernetics Frame] Through feedback loops and channel capacity bounds, mutual information is maximized while continuous channel entropy is bounded by Shannon-Hartley limit.");
    // Domain 12: SYSTEMS_CONTROL (Closed-Loop Dynamics & Lyapunov Stability Framing)
    cartan_tree_push(lex.discourse_frames_tree, "[Systems Control Frame] Closed-loop transfer function stabilizes dynamical system toward asymptotic setpoint, ensuring bounded-input bounded-output (BIBO) stability under Lyapunov function V(x).");
    // Domain 13: METACOGNITION_INTROSPECTION (Higher-Order Calibration & Self-Reflection Framing)
    cartan_tree_push(lex.discourse_frames_tree, "[Metacognitive Introspection Frame] Higher-order epistemic monitor tracks belief confidence and calibration error, invoking cognitive restructuring when recursive self-reflection detects inference drift.");
    // Domain 14: NEUROMORPHIC_SYSTEMS (Spike Timing Dynamics & Membrane Potentials Framing)
    cartan_tree_push(lex.discourse_frames_tree, "[Neuromorphic Architecture Frame] Asynchronous event-driven spiking neural circuit integrates membrane potentials toward threshold firing, modulating synaptic plasticity via spike-timing-dependent plasticity (STDP).");
    // Domain 15: GAME_THEORY_COORDINATION (Multi-Agent Strategic Equilibria Framing)
    cartan_tree_push(lex.discourse_frames_tree, "[Game Coordination Frame] In multi-agent strategic interaction, correlated equilibrium and Pareto efficiency guide cooperative consensus, precluding dominated strategies under incentive-compatible payoffs.");
    // Domain 16: SCIENTIFIC_METHOD (Empirical Falsifiability & Experimental Control Framing)
    cartan_tree_push(lex.discourse_frames_tree, "[Scientific Method Frame] Falsifiable empirical hypothesis confronts controlled experimental observation, minimizing confounding bias through blinded counterfactual controls and statistical power.");
    // Domain 17: SECURITY_SANDBOXING (Compartmentalization & Capability Boundaries Framing)
    cartan_tree_push(lex.discourse_frames_tree, "[Security Sandbox Frame] Under strict capability-based access control and principle of least privilege, memory isolation sandbox prevents privilege escalation and enforces inviolable compartmentalization boundaries.");
    // Domain 18: SOFTWARE_ENGINEERING_ALGORITHMS (Hoare Contracts & Algorithmic Termination Framing)
    cartan_tree_push(lex.discourse_frames_tree, "[Software Engineering Frame] Under formal Hoare logic contracts, preconditions ensure execution safety and postconditions guarantee correctness, enforcing bounded complexity and deadlock freedom.");
}

// Populates universal cross-domain lexicons and ontologies across all 18 domains
fn domain_lexicon_populate_defaults(lex: DomainLexicon) {
    // --- Domain 0: SYSTEM_CORE ---
    domain_lexicon_add_term(lex, "conservation", 0.0, 0.95, "predicate");
    domain_lexicon_add_term(lex, "energy", 0.0, 0.90, "entity");
    domain_lexicon_add_term(lex, "entropy", 0.0, 0.95, "entity");
    domain_lexicon_add_term(lex, "thermodynamics", 0.0, 0.92, "entity");
    domain_lexicon_add_term(lex, "spacetime", 0.0, 0.90, "entity");

    // --- Domain 1: PHYSICS_SIM ---
    domain_lexicon_add_term(lex, "momentum", 1.0, 0.88, "entity");
    domain_lexicon_add_term(lex, "velocity", 1.0, 0.82, "entity");
    domain_lexicon_add_term(lex, "kinetic", 1.0, 0.85, "entity");
    domain_lexicon_add_term(lex, "dissipation", 1.0, 0.90, "predicate");
    domain_lexicon_add_term(lex, "restitution", 1.0, 0.92, "entity");

    // --- Domain 2: TOPOLOGY_GEOMETRY ---
    domain_lexicon_add_term(lex, "manifold", 2.0, 0.95, "entity");
    domain_lexicon_add_term(lex, "differential", 2.0, 0.90, "operator");
    domain_lexicon_add_term(lex, "geodesic", 2.0, 0.92, "entity");
    domain_lexicon_add_term(lex, "exterior", 2.0, 0.88, "operator");
    domain_lexicon_add_term(lex, "curvature", 2.0, 0.91, "entity");

    // --- Domain 3: COMPLEXITY_THEORY ---
    domain_lexicon_add_term(lex, "turing", 3.0, 0.94, "entity");
    domain_lexicon_add_term(lex, "polynomial", 3.0, 0.89, "entity");
    domain_lexicon_add_term(lex, "np_complete", 3.0, 0.96, "entity");
    domain_lexicon_add_term(lex, "reduction", 3.0, 0.90, "predicate");
    domain_lexicon_add_term(lex, "tractability", 3.0, 0.92, "entity");

    // --- Domain 4: BIOLOGICAL_SYSTEMS ---
    domain_lexicon_add_term(lex, "photosynthesis", 4.0, 0.94, "predicate");
    domain_lexicon_add_term(lex, "metabolism", 4.0, 0.91, "entity");
    domain_lexicon_add_term(lex, "respiration", 4.0, 0.90, "predicate");
    domain_lexicon_add_term(lex, "phosphorylation", 4.0, 0.96, "predicate");
    domain_lexicon_add_term(lex, "ribosome", 4.0, 0.93, "entity");

    // --- Domain 5: CAUSAL_TAXONOMY ---
    domain_lexicon_add_term(lex, "taxonomic", 5.0, 0.87, "predicate");
    domain_lexicon_add_term(lex, "acceleration", 5.0, 0.84, "entity");
    domain_lexicon_add_term(lex, "deformation", 5.0, 0.88, "predicate");
    domain_lexicon_add_term(lex, "shear_stress", 5.0, 0.92, "entity");
    domain_lexicon_add_term(lex, "viscosity", 5.0, 0.89, "entity");

    // --- Domain 6: LANGUAGE_DISCOURSE ---
    domain_lexicon_add_term(lex, "anaphora", 6.0, 0.93, "entity");
    domain_lexicon_add_term(lex, "illocutionary", 6.0, 0.96, "predicate");
    domain_lexicon_add_term(lex, "pragmatics", 6.0, 0.91, "entity");
    domain_lexicon_add_term(lex, "presupposition", 6.0, 0.94, "entity");
    domain_lexicon_add_term(lex, "coherence", 6.0, 0.88, "predicate");

    // --- Domain 7: LOGIC_REASONING ---
    domain_lexicon_add_term(lex, "modus_ponens", 7.0, 0.97, "operator");
    domain_lexicon_add_term(lex, "syllogism", 7.0, 0.92, "entity");
    domain_lexicon_add_term(lex, "contraposition", 7.0, 0.94, "operator");
    domain_lexicon_add_term(lex, "resolution", 7.0, 0.91, "operator");
    domain_lexicon_add_term(lex, "entailment", 7.0, 0.95, "predicate");

    // --- Domain 8: DECISION_PLANNING ---
    domain_lexicon_add_term(lex, "bellman", 8.0, 0.97, "entity");
    domain_lexicon_add_term(lex, "nash_equilibrium", 8.0, 0.96, "entity");
    domain_lexicon_add_term(lex, "pareto", 8.0, 0.94, "entity");
    domain_lexicon_add_term(lex, "precondition", 8.0, 0.93, "predicate");
    domain_lexicon_add_term(lex, "admissibility", 8.0, 0.95, "predicate");

    // --- Domain 9: EPISTEMOLOGY_BELIEF ---
    domain_lexicon_add_term(lex, "bayes", 9.0, 0.98, "operator");
    domain_lexicon_add_term(lex, "posterior", 9.0, 0.96, "entity");
    domain_lexicon_add_term(lex, "likelihood", 9.0, 0.95, "entity");
    domain_lexicon_add_term(lex, "prior", 9.0, 0.92, "entity");
    domain_lexicon_add_term(lex, "epistemic", 9.0, 0.94, "predicate");
    domain_lexicon_add_term(lex, "defeasible", 9.0, 0.96, "predicate");
    domain_lexicon_add_term(lex, "agm_revision", 9.0, 0.97, "operator");
    domain_lexicon_add_term(lex, "dempster_shafer", 9.0, 0.95, "operator");
    domain_lexicon_add_term(lex, "credence", 9.0, 0.91, "entity");

    // --- Domain 10: COMPILER_SYSTEMS ---
    domain_lexicon_add_term(lex, "monomorphization", 10.0, 0.98, "operator");
    domain_lexicon_add_term(lex, "llvm_ir", 10.0, 0.97, "entity");
    domain_lexicon_add_term(lex, "type_soundness", 10.0, 0.96, "predicate");
    domain_lexicon_add_term(lex, "ssa_dominance", 10.0, 0.95, "predicate");
    domain_lexicon_add_term(lex, "register_allocation", 10.0, 0.94, "operator");
    domain_lexicon_add_term(lex, "curry_howard", 10.0, 0.96, "operator");
    domain_lexicon_add_term(lex, "linear_type", 10.0, 0.93, "entity");
    domain_lexicon_add_term(lex, "dead_code_elimination", 10.0, 0.95, "operator");

    // --- Domain 11: INFORMATION_CYBERNETICS ---
    domain_lexicon_add_term(lex, "shannon_entropy", 11.0, 0.97, "entity");
    domain_lexicon_add_term(lex, "channel_capacity", 11.0, 0.96, "entity");
    domain_lexicon_add_term(lex, "cybernetic_feedback", 11.0, 0.95, "operator");
    domain_lexicon_add_term(lex, "mutual_information", 11.0, 0.96, "entity");
    domain_lexicon_add_term(lex, "ergodic", 11.0, 0.93, "predicate");

    // --- Domain 12: SYSTEMS_CONTROL ---
    domain_lexicon_add_term(lex, "lyapunov_stability", 12.0, 0.98, "predicate");
    domain_lexicon_add_term(lex, "transfer_function", 12.0, 0.95, "entity");
    domain_lexicon_add_term(lex, "closed_loop", 12.0, 0.94, "predicate");
    domain_lexicon_add_term(lex, "kalman_filter", 12.0, 0.97, "operator");
    domain_lexicon_add_term(lex, "controllability", 12.0, 0.96, "predicate");

    // --- Domain 13: METACOGNITION_INTROSPECTION ---
    domain_lexicon_add_term(lex, "metacognitive_monitoring", 13.0, 0.97, "operator");
    domain_lexicon_add_term(lex, "epistemic_calibration", 13.0, 0.96, "predicate");
    domain_lexicon_add_term(lex, "self_reflection", 13.0, 0.95, "operator");
    domain_lexicon_add_term(lex, "cognitive_bias", 13.0, 0.94, "entity");
    domain_lexicon_add_term(lex, "error_detection", 13.0, 0.95, "predicate");

    // --- Domain 14: NEUROMORPHIC_SYSTEMS ---
    domain_lexicon_add_term(lex, "spike_timing", 14.0, 0.97, "entity");
    domain_lexicon_add_term(lex, "synaptic_plasticity", 14.0, 0.96, "predicate");
    domain_lexicon_add_term(lex, "membrane_potential", 14.0, 0.95, "entity");
    domain_lexicon_add_term(lex, "integrate_and_fire", 14.0, 0.96, "operator");
    domain_lexicon_add_term(lex, "asynchronous_event", 14.0, 0.94, "predicate");

    // --- Domain 15: GAME_THEORY_COORDINATION ---
    domain_lexicon_add_term(lex, "pareto_efficient", 15.0, 0.97, "predicate");
    domain_lexicon_add_term(lex, "correlated_equilibrium", 15.0, 0.98, "entity");
    domain_lexicon_add_term(lex, "cooperative_game", 15.0, 0.95, "entity");
    domain_lexicon_add_term(lex, "mechanism_design", 15.0, 0.96, "operator");
    domain_lexicon_add_term(lex, "zero_sum", 15.0, 0.94, "predicate");

    // --- Domain 16: SCIENTIFIC_METHOD ---
    domain_lexicon_add_term(lex, "falsifiability", 16.0, 0.98, "predicate");
    domain_lexicon_add_term(lex, "null_hypothesis", 16.0, 0.97, "entity");
    domain_lexicon_add_term(lex, "controlled_experiment", 16.0, 0.96, "operator");
    domain_lexicon_add_term(lex, "confounding_variable", 16.0, 0.95, "entity");
    domain_lexicon_add_term(lex, "replicability", 16.0, 0.97, "predicate");

    // --- Domain 17: SECURITY_SANDBOXING ---
    domain_lexicon_add_term(lex, "capability_security", 17.0, 0.98, "entity");
    domain_lexicon_add_term(lex, "least_privilege", 17.0, 0.97, "predicate");
    domain_lexicon_add_term(lex, "memory_isolation", 17.0, 0.98, "predicate");
    domain_lexicon_add_term(lex, "privilege_escalation", 17.0, 0.96, "operator");
    domain_lexicon_add_term(lex, "sandboxing", 17.0, 0.95, "entity");

    // --- Domain 18: SOFTWARE_ENGINEERING_ALGORITHMS ---
    domain_lexicon_add_term(lex, "hoare_contract", 18.0, 0.98, "entity");
    domain_lexicon_add_term(lex, "algorithmic_termination", 18.0, 0.97, "predicate");
    domain_lexicon_add_term(lex, "deadlock_freedom", 18.0, 0.96, "predicate");
    domain_lexicon_add_term(lex, "amortized_complexity", 18.0, 0.95, "entity");
    domain_lexicon_add_term(lex, "cache_locality", 18.0, 0.96, "operator");

    domain_lexicon_register_frames(lex);
}

// Computes Information Content (IC) weight for a word; returns default 0.10 for stopwords
fn domain_lexicon_lookup_ic(lex: DomainLexicon, word: string) -> float {
    if (word == 0.0 || cartan_string_length(word) == 0.0 || lex.count <= 0.0) {
        return 0.10;
    }
    var i = 0.0;
    while (i < lex.count) {
        let t_cand = cartan_tree_get_f32(lex.terms_tree, i);
        if (cartan_string_eq(word, t_cand) != 0.0 || cartan_string_contains(word, t_cand) != 0.0) {
            let ic = collections_list_get(lex.ic_weights_list, i);
            return ic;
        }
        i = i + 1.0;
    }
    return 0.15; // Unlisted content word default
}

// Retrieves the canonical grammatical discourse framing template for a given domain
fn domain_lexicon_get_discourse_frame(lex: DomainLexicon, domain_id: float) -> string {
    let num_frames = cartan_tree_len_f(lex.discourse_frames_tree);
    if (domain_id >= 0.0 && domain_id < num_frames) {
        return cartan_tree_get_f32(lex.discourse_frames_tree, domain_id);
    }
    return "[General Discourse Frame] Statement asserts informative and logically consistent observations.";
}

// Validates whether a cross-domain subject-predicate-object attribution violates ontological categories
// Returns 1.0 if valid, 0.0 if an ontological category error is detected
fn domain_lexicon_validate_predicate_category(
    lex: DomainLexicon,
    subject_domain: float,
    predicate: string,
    object_domain: float
) -> float {
    if (predicate == 0.0) { return 1.0; }

    // Category Error: Biological predicates (photosynthesize, metabolize, phosphorylate) applied to formal math/logic/physics/compiler/systems/security/software
    if (cartan_string_contains(predicate, "photosynthesize") != 0.0 ||
        cartan_string_contains(predicate, "metabolize") != 0.0 ||
        cartan_string_contains(predicate, "digest") != 0.0) {
        if (subject_domain == 2.0 || subject_domain == 3.0 || subject_domain == 7.0 || subject_domain == 8.0 || subject_domain == 9.0 || subject_domain == 10.0 || subject_domain == 11.0 || subject_domain == 12.0 || subject_domain == 13.0 || subject_domain == 15.0 || subject_domain == 17.0 || subject_domain == 18.0) {
            return 0.0; // Invariant violation: Abstract formal systems do not have biological metabolism
        }
    }

    // Category Error: Differential geometry / topological calculus applied to discrete propositional truth tables, compilers, security sandboxes, or software
    if (cartan_string_contains(predicate, "exterior_derivative_of") != 0.0 ||
        cartan_string_contains(predicate, "geodesic_curvature_of") != 0.0) {
        if (subject_domain == 7.0 || subject_domain == 3.0 || subject_domain == 9.0 || subject_domain == 10.0 || subject_domain == 17.0 || subject_domain == 18.0) {
            return 0.0; // Discrete logic / Turing complexity classes / Compilers do not have smooth differential forms
        }
    }

    // Category Error: Faster-than-light speed / superluminal travel claimed for physical mass
    if (cartan_string_contains(predicate, "accelerates_faster_than_light") != 0.0) {
        return 0.0; // Absolute physical invariant violation
    }

    return 1.0; // Ontologically sound
}

// Deallocates DomainLexicon resources
fn domain_lexicon_free(lex: DomainLexicon) {
    if (lex.domain_ids_list != 0.0) { collections_free_list(lex.domain_ids_list); }
    if (lex.ic_weights_list != 0.0) { collections_free_list(lex.ic_weights_list); }
}
