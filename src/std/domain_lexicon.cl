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
}

// Populates universal cross-domain lexicons and ontologies across all 9 domains
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

    // Category Error: Biological predicates (photosynthesize, metabolize, phosphorylate) applied to formal math/logic/physics
    if (cartan_string_contains(predicate, "photosynthesize") != 0.0 ||
        cartan_string_contains(predicate, "metabolize") != 0.0 ||
        cartan_string_contains(predicate, "digest") != 0.0) {
        if (subject_domain == 2.0 || subject_domain == 3.0 || subject_domain == 7.0 || subject_domain == 8.0) {
            return 0.0; // Invariant violation: Abstract formal systems do not have biological metabolism
        }
    }

    // Category Error: Differential geometry / topological calculus applied to discrete propositional truth tables
    if (cartan_string_contains(predicate, "exterior_derivative_of") != 0.0 ||
        cartan_string_contains(predicate, "geodesic_curvature_of") != 0.0) {
        if (subject_domain == 7.0 || subject_domain == 3.0) {
            return 0.0; // Discrete logic / Turing complexity classes do not have smooth differential forms
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
