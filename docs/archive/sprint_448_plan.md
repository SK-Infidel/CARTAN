# Sprint 448 Implementation Plan: Phase 14 Rule-Guided Template Distillation & Hybrid Rejection Sampling

**Author:** CARTAN Architecture & Engineering Squad  
**Date:** 2026-09-26  
**Archive:** `docs/archive/sprint_448_plan.md`  

---

## 1. Executive Sprint Goal
Complete all remaining active items from **Phase 14** of the master roadmap:
1. Map deterministic ground-truth template logits directly into teacher distillation targets during `geomind.exe --train-distill`.
2. Implement the **Hybrid Ensemble Discriminator** in `test/geomind/chat.cl` dual-scoring trajectories against Continuous Hopfield attractor energy basins and template/veto match confidence.
3. Implement **Zero-Hallucination Weight Grafting** (`fusion_zero_hallucination_weight_graft`) in `src/std/fusion.cl` merging template-distilled weights with open-ended weights via SLERP geodesic interpolation and WordNet IC modulation.
4. Resolve `[ISSUE-202]` (`semantics_apply_lca_boost` vector bracket indexing).
5. Resolve `[ISSUE-203]` (synthetic 440 Hz sine wave in `geomind_chat_process_audio_input`).
6. Resolve backlog items `[BACKLOG-WORDNET-01]` and `[BACKLOG-VOCAB-01]`.

---

## 2. Technical Design

### A. Fix `semantics_apply_lca_boost` Vector Access (`src/std/semantics.cl`)
Replace `logits[i] = logits[i] + boost_factor * 0.5;` with:
```cartan
let cur = cartan_vec_get_f32(logits, i);
cartan_vec_set_f32(logits, i, cur + boost_factor * 0.5);
```

### B. Purge Synthetic Audio Sine Wave (`test/geomind/chat.cl`)
In `geomind_chat_process_audio_input`, require authentic audio samples or return `0.0`. Never generate synthetic sine waves `sin(pi2 * 440.0 * t)`.

### C. Zero-Hallucination Weight Grafting (`src/std/fusion.cl`)
Expose:
```cartan
fn fusion_zero_hallucination_weight_graft(template_weights: ptr, open_weights: ptr, alpha: float, vocab_cols: float) -> ptr {
    let fused = fusion_slerp_tensors(template_weights, open_weights, alpha);
    fusion_apply_wordnet_ic_modulation(fused, vocab_cols);
    return fused;
}
```

### D. Deterministic Ground Truth Teacher Target (`test/geomind/train.cl`)
In `geomind_distill_train_run`:
For synsets identified in the input WordNet text, inject deterministic ground truth target probability into the teacher distribution using `semantics_apply_concept_logit_boost` and rule-DAG hypernym alignments.

### E. Hybrid Ensemble Discriminator (`test/geomind/chat.cl`)
Implement `geomind_hybrid_ensemble_discriminate(candidate_h: ptr, candidate_text: string, primary_concept: string, nses_pipe: ptr) -> float`:
1. Compute Continuous Hopfield attractor energy $E_{\text{hopfield}}$.
2. Compute template/veto match confidence $C_{\text{template}}$ via Lin similarity and `veto_gate_scan`.
3. Emit composite discriminator score:
   $$S = 0.50 \cdot \frac{1.0}{1.0 + \exp(E_{\text{hopfield}} \cdot 0.1)} + 0.50 \cdot C_{\text{template}}$$

---

## 3. Verification Criteria
1. Full compiler regression suite (`run_tests.exe`) passes all 59 targets.
2. `geomind.exe --train-distill` runs with deterministic ground truth teacher target and reports clean convergence.
3. `geomind.exe --eval-analogy` runs with 100% pass on all 4 analogies.
4. `geomind.exe --sleep` runs all 5 metacognitive phases cleanly.
5. All issues marked `[RESOLVED]` in `ISSUES.md`.
