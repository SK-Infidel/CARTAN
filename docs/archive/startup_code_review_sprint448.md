# Startup Code Review — Sprint 448: Phase 14 Rule-Guided Template Distillation & Hybrid Rejection Sampling

**Date:** 2026-09-26  
**Author:** CARTAN Architecture & Engineering Squad  
**Review Target:** `src/std/semantics.cl`, `src/std/fusion.cl`, `test/geomind/chat.cl`, `test/geomind/train.cl`, `ISSUES.md`, `docs/ROADMAP.md`  

---

## 1. Executive Summary & Sprint Scope

In accordance with Rick's directive to "knock it all out in the next sprint", Sprint 448 addresses all remaining active roadmap items from **Phase 14** and backlogged technical debt:
1. **Deterministic Ground Truth Teacher Target** (`docs/ROADMAP.md` Phase 14 Item 1): Map template logits and taxonomy ground truth directly into `distill_kl_loss` targets during `geomind.exe --train-distill` passes.
2. **Hybrid Ensemble Discriminator** (`docs/ROADMAP.md` Phase 14 Item 2): Implement a dual-score evaluator in `test/geomind/chat.cl` comparing continuous Hopfield energy minimum against template match confidence to pick optimal response trajectories.
3. **Zero-Hallucination Weight Grafting** (`docs/ROADMAP.md` Phase 14 Item 3): Merge template-distilled weights with open-ended transformer weights via SLERP geodesic interpolation (`src/std/fusion.cl`).
4. **Resolution of `[BACKLOG-WORDNET-01]`**: WordNet/SlangNet taxonomy DAG dot-path resolution and IC loss weighting in `src/std/semantics.cl` and fix vector bracket-index bug in `semantics_apply_lca_boost`.
5. **Resolution of `[BACKLOG-VOCAB-01]`**: Verified authentic 262,144 HuggingFace vocabulary binding on $S^{247}$ without discrete slot remapping.
6. **Synthetic Audio Tone Purge**: Purge synthetic 440Hz test sine tone in `geomind_chat_process_audio_input` (`test/geomind/chat.cl`).

---

## 2. Logical Dependency Tree

```
CARTAN Core Toolchain (cartanc.exe)
  ├── Frontend: Lexer -> Parser -> AST -> TypeChecker -> Codegen
  └── Core Runtime (Zig -O3 LTO Vectorized Pass Pipeline)
        │
        ├── std::math (src/std/math.cl)
        ├── std::geom (src/std/geom.cl) [Killing-Cartan Metric, Sherman-Morrison]
        ├── std::tokenizer (src/std/tokenizer.cl) [SentencePiece BPE 65k/262k]
        ├── std::semantics (src/std/semantics.cl) [WordNet/SlangNet DAG, LCA, Lin/Resnik IC]
        │     └── depends on: math.cl, string.cl, collections.cl
        ├── std::distill (src/std/distill.cl) [KL Divergence, Analytical Softmax Gradients]
        │     └── depends on: math.cl, tensor.cl
        ├── std::fusion (src/std/fusion.cl) [SLERP, Tangent Space Geodesics, Zero-Hallucination Graft]
        │     └── depends on: math.cl, geom.cl, tokenizer.cl, tensor.cl
        ├── std::resonator (src/std/resonator.cl) [Continuous Hopfield Basins]
        │     └── depends on: math.cl, collections.cl
        │
        └── GeoMind Neural Substrate (test/geomind/)
              ├── geometry.cl & streams.cl [8 Lie Subgroups, Weyl Reflections]
              ├── e8_attention_engine.cl [Continuous S^247 Manifold Attention]
              ├── moe.cl [Sasaki Phase-Space Router, Freudenthal Magic Square]
              ├── train.cl [Causal WebGPU Engine, Distillation, Steady-State SFT]
              │     └── calls: distill.cl, fusion.cl, tokenizer.cl, semantics.cl, resonator.cl
              ├── chat.cl [Interactive Engine, Hybrid Ensemble Discriminator, Multimodal]
              │     └── calls: resonator.cl, semantics.cl, veto_gate, streams.cl
              └── main.car / geomind.exe [CLI Entry Points: --chat, --eval-analogy, --sleep, --train-distill]
```

---

## 3. Discovered Bugs & Code Review Findings

### Finding 1: Raw Array Bracket Indexing on CARTAN Vector (`src/std/semantics.cl:388`)
- **Location**: `src/std/semantics.cl` line 388: `logits[i] = logits[i] + boost_factor * 0.5;`
- **Defect**: `logits` is a CARTAN vector pointer (heap-allocated `cartan_vec`), but line 388 uses C array subscript notation (`logits[i]`). If invoked with a CARTAN vector, this bypasses the vector header and corrupts memory.
- **Remediation**: Use `cartan_vec_get_f32(logits, i)` and `cartan_vec_set_f32(logits, i, ...)`. Logged as `[ISSUE-202]`.

### Finding 2: Synthetic 440 Hz Sine Tone in Audio Ingestion (`test/geomind/chat.cl:618`)
- **Location**: `test/geomind/chat.cl` lines 612–627: `let s = sin(pi2 * 440.0 * t);`
- **Defect**: In `geomind_chat_process_audio_input`, synthetic sinusoidal waveforms are generated when called without real audio buffers.
- **Remediation**: Guard against uninitialized audio and return clean NULL stream `0.0` unless genuine audio samples are provided. Logged as `[ISSUE-203]`.

### Finding 3: Missing Zero-Hallucination Weight Grafting Primitive (`src/std/fusion.cl`)
- **Location**: `src/std/fusion.cl`
- **Defect**: Roadmap Phase 14 specifies `fusion_zero_hallucination_weight_graft` merging template-distilled weights with open-ended weights via SLERP geodesic interpolation and WordNet IC modulation.
- **Remediation**: Implement `fusion_zero_hallucination_weight_graft(template_weights, open_weights, alpha, vocab_cols)`.

### Finding 4: Missing Hybrid Ensemble Discriminator in Inference (`test/geomind/chat.cl`)
- **Location**: `test/geomind/chat.cl`
- **Defect**: Candidate generation evaluates single-trajectory outputs without dual-scoring against Continuous Hopfield attractor energy basins and template/veto match confidence.
- **Remediation**: Implement `geomind_hybrid_ensemble_discriminate` to evaluate trajectories and score via combined energy-template objective.

---

## 4. Planned Issue Tracking

- **`[ISSUE-202]`**: Raw Array Bracket Indexing on CARTAN Vector in `semantics_apply_lca_boost`.
- **`[ISSUE-203]`**: Synthetic 440 Hz Sine Wave Generator in Audio Ingestion (`chat.cl`).
