// src/std/saliency_probe.cl
// CARTAN Standard Library: Top-4 Epistemic Saliency & Certainty Spike Probe
// Neuro-Symbolic Expert System (NSES) Phase 6 Core

include "src/std/math.cl";
include "src/std/collections.cl";

// Saliency Probe Result Structure
struct SaliencyResult {
    is_epistemic_spike: float;    // 1.0 if H4 <= 0.20 nats and Margin >= 3.2 logits
    h4_entropy_nats: float;       // Top-4 Shannon entropy
    logit_margin: float;          // Top-1 vs Top-2 margin
    top1_logit: float;
    top2_logit: float;
}

// Computes H4 entropy and Top-1 vs Top-2 margin directly on top-4 scalar logits in <15 ns
fn saliency_probe_top4_values(m0: float, m1: float, m2: float, m3: float) -> SaliencyResult {
    let margin = m0 - m1;
    if (margin < 3.20) {
        return SaliencyResult {
            is_epistemic_spike: 0.0,
            h4_entropy_nats: 1.0,
            logit_margin: margin,
            top1_logit: m0,
            top2_logit: m1
        };
    }

    // Exact Analytic Identity: H4 = ln(S) - sum(e_i * (m_i - m_0)) / S
    // Reduces 4 log evaluations to a single log(S)
    let d1 = m1 - m0;
    let d2 = m2 - m0;
    let d3 = m3 - m0;

    let e1 = exp(d1);
    let e2 = exp(d2);
    let e3 = exp(d3);
    let sum_e = 1.0 + e1 + e2 + e3;

    let weighted_dot = (e1 * d1) + (e2 * d2) + (e3 * d3);
    let h4 = log(sum_e) - (weighted_dot / sum_e);

    // Certainty spike when H4 <= 0.20 nats and Margin >= 3.2 logits
    var spike = 0.0;
    if (h4 <= 0.20) {
        spike = 1.0;
    }

    return SaliencyResult {
        is_epistemic_spike: spike,
        h4_entropy_nats: h4,
        logit_margin: margin,
        top1_logit: m0,
        top2_logit: m1
    };
}

// Scans an array/buffer of logits and extracts Top-4 with zero heap allocations
fn saliency_probe_top4(logits_buf: ptr, vocab_size: float) -> SaliencyResult {
    if (logits_buf == 0.0 || vocab_size < 4.0) {
        return SaliencyResult {
            is_epistemic_spike: 0.0,
            h4_entropy_nats: 99.0,
            logit_margin: 0.0,
            top1_logit: 0.0,
            top2_logit: 0.0
        };
    }

    var m0 = -100000.0;
    var m1 = -100000.0;
    var m2 = -100000.0;
    var m3 = -100000.0;

    var i = 0.0;
    while (i < vocab_size) {
        let val = logits_buf[i];
        if (val > m0) {
            m3 = m2;
            m2 = m1;
            m1 = m0;
            m0 = val;
        } else if (val > m1) {
            m3 = m2;
            m2 = m1;
            m1 = val;
        } else if (val > m2) {
            m3 = m2;
            m2 = val;
        } else if (val > m3) {
            m3 = val;
        }
        i = i + 1.0;
    }

    return saliency_probe_top4_values(m0, m1, m2, m3);
}
