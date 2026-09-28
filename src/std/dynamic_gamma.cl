// src/std/dynamic_gamma.cl
// CARTAN Standard Library: Dynamic Gamma Scaling & Adaptive Hopfield Coupling
// Neuro-Symbolic Expert System (NSES) Phase 6 Core

include "src/std/math.cl";

struct DynamicGammaConfig {
    base_gamma: float;
    min_gamma: float;
    max_gamma: float;
    ent_ref: float;
    cert_ref: float;
}

fn dynamic_gamma_create(
    base_gamma: float,
    min_gamma: float,
    max_gamma: float,
    ent_ref: float,
    cert_ref: float
) -> DynamicGammaConfig {
    var bg = base_gamma;
    if (bg <= 0.0) { bg = 0.10; }
    var mg = min_gamma;
    if (mg <= 0.0) { mg = 0.02; }
    var xg = max_gamma;
    if (xg <= 0.0) { xg = 0.35; }
    var er = ent_ref;
    if (er <= 0.0) { er = 6.0; }
    var cr = cert_ref;
    if (cr <= 0.0) { cr = 0.10; }

    return DynamicGammaConfig {
        base_gamma: bg,
        min_gamma: mg,
        max_gamma: xg,
        ent_ref: er,
        cert_ref: cr
    };
}

// Computes domain baseline factor gamma_base(d)
fn dynamic_gamma_domain_baseline(cfg: DynamicGammaConfig, domain_idx: float) -> float {
    var b = cfg.base_gamma;
    if (domain_idx == 0.0) {
        // SYSTEM_CORE: Hard physical/mathematical conservation invariants
        b = b * 1.40;
    } else if (domain_idx == 1.0) {
        // PHYSICS_SIM: Conservation of momentum and collision mechanics
        b = b * 1.25;
    } else if (domain_idx == 2.0) {
        // TOPOLOGY_GEOMETRY: Manifold & differential form constraints
        b = b * 1.20;
    } else if (domain_idx == 3.0) {
        // COMPLEXITY_THEORY: Formal automata & complexity bounds
        b = b * 1.00;
    } else if (domain_idx == 4.0) {
        // BIOLOGICAL_SYSTEMS: Empirical metabolic & genetic rules
        b = b * 0.85;
    } else if (domain_idx == 5.0) {
        // CAUSAL_TAXONOMY: Linguistic & taxonomic mutual exclusion
        b = b * 0.85;
    } else if (domain_idx == 6.0) {
        // LANGUAGE_DISCOURSE: Conversational pragmatics & speech acts
        b = b * 0.90;
    } else if (domain_idx == 7.0) {
        // LOGIC_REASONING: Deductive formal proof rules
        b = b * 1.35;
    } else if (domain_idx == 8.0) {
        // DECISION_PLANNING: Bellman optimality & policy constraints
        b = b * 1.10;
    } else if (domain_idx == 9.0) {
        // EPISTEMOLOGY_BELIEF: Bayesian posterior & AGM revision
        b = b * 1.15;
    } else if (domain_idx == 10.0) {
        // COMPILER_SYSTEMS: Type soundness & memory safety
        b = b * 1.30;
    } else if (domain_idx == 11.0) {
        // INFORMATION_CYBERNETICS: Shannon capacity & feedback bounds
        b = b * 1.20;
    } else if (domain_idx == 12.0) {
        // SYSTEMS_CONTROL: Lyapunov stability & transfer functions
        b = b * 1.25;
    } else if (domain_idx == 13.0) {
        // METACOGNITION_INTROSPECTION: Epistemic calibration & self-monitoring
        b = b * 1.15;
    } else if (domain_idx == 14.0) {
        // NEUROMORPHIC_SYSTEMS: Spike timing & synaptic plasticity
        b = b * 1.10;
    } else if (domain_idx == 15.0) {
        // GAME_THEORY_COORDINATION: Multi-agent equilibria & mechanism design
        b = b * 1.15;
    } else if (domain_idx == 16.0) {
        // SCIENTIFIC_METHOD: Falsifiability & controlled experimentation
        b = b * 1.20;
    } else if (domain_idx == 17.0) {
        // SECURITY_SANDBOXING: Capability boundaries & least privilege
        b = b * 1.35;
    }
    return b;
}

// Computes dynamic gamma coupling based on active domain, entropy, certainty, and loss dynamics
fn dynamic_gamma_compute(
    cfg: DynamicGammaConfig,
    domain_idx: float,
    cur_entropy: float,
    cur_certainty: float,
    cur_loss: float,
    ema_loss: float
) -> float {
    let d_base = dynamic_gamma_domain_baseline(cfg, domain_idx);

    // 1. Uncertainty modulation: scale up with entropy, scale down with certainty
    var mu_unc = 1.0;
    if (cur_entropy > 0.0 && cfg.ent_ref > 0.0) {
        var d_ent = (cur_entropy - cfg.ent_ref) / cfg.ent_ref;
        if (d_ent < -0.5) { d_ent = -0.5; }
        if (d_ent > 1.5) { d_ent = 1.5; }

        var d_cert = 0.0;
        if (cfg.cert_ref > 0.0) {
            d_cert = (cfg.cert_ref - cur_certainty) / cfg.cert_ref;
            if (d_cert < -0.5) { d_cert = -0.5; }
            if (d_cert > 1.0) { d_cert = 1.0; }
        }

        mu_unc = 1.0 + (0.50 * d_ent) + (0.50 * d_cert);
        if (mu_unc < 0.35) { mu_unc = 0.35; }
        if (mu_unc > 2.50) { mu_unc = 2.50; }
    }

    // 2. Loss surge modulation: boost coupling if current loss spikes above EMA
    var mu_surge = 1.0;
    if (ema_loss > 0.0 && cur_loss > (1.15 * ema_loss)) {
        let surge_ratio = (cur_loss - (1.15 * ema_loss)) / ema_loss;
        var boost = surge_ratio;
        if (boost > 1.0) { boost = 1.0; }
        mu_surge = 1.0 + boost;
    }

    // 3. Composite coupling with safety clamp
    var gamma = d_base * mu_unc * mu_surge;
    if (gamma < cfg.min_gamma) { gamma = cfg.min_gamma; }
    if (gamma > cfg.max_gamma) { gamma = cfg.max_gamma; }

    return gamma;
}
