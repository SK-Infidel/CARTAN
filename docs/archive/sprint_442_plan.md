# Sprint 442 Plan: Full Geometric Realignment of GeoMind in Native CARTAN

## Executive Summary
Sprint 442 realigns CARTAN's GeoMind implementation with the mathematical specification from `vision.md` and the reference implementation in `GeoMind`. It resolves the use-after-free crash, removes the 2,560-token clamp, eliminates synthetic sinusoidal noise, and replaces the discrete pseudo-LM-head with authentic continuous manifold cosine similarity over the full vocabulary, while preserving CARTAN's compiled Sasaki tangent packet router.

---

## 1. Objectives & Technical Epics

### Epic 1: Memory Safety & Lifecycle Hardening (P0 - Blocker)
- **Problem**: `prompt_scaffold_free(gen_buffer)` frees buffer memory before `full_gen_text` is read by `veto_gate_scan()` and `geomind_chat_log_turn()`, causing `STATUS_ACCESS_VIOLATION` (`0xC0000005`).
- **Solution**: Move `prompt_scaffold_free(gen_buffer)` to the very end of `geomind_chat_generate_reply_multimodal()`, ensuring all consumers finish before memory is released.

### Epic 2: Manifold Cosine Projection & Vocabulary Restoration (P0 - Core Architecture)
- **Problem**: 
  - Token IDs $\ge 2560$ are clamped to `3.0`, destroying 99% of English vocabulary.
  - `vocab_cols = 2560.0` discrete matrix multiplication truncates output space.
  - Heuristic `0.10 * sin(...)` corrupts embedding representations.
- **Solution**:
  - Remove token clamping and aliasing to `3.0`.
  - Re-establish continuous manifold projection: the network output is a normalized continuous coordinate $\hat{h} \in S^{247}$ (or 2560D $E_8$ manifold space).
  - Compute next-token logits via cosine similarity against normalized continuous embeddings:
    $$\text{logit}_i = 30.0 \cdot \langle \hat{h}, \hat{E}_i \rangle$$
  - Implement Zipfian Information Content (IC) prior subtraction: $\text{logit}_i \leftarrow \text{logit}_i - 0.3 \cdot \text{IC}_i$.
  - Enforce vocabulary validity masking (`valid_mask`) to suppress unmapped token IDs.
  - Strip arbitrary sinusoidal phase noise from `cartan_tensor_compute_hidden_state_from_tokens` and `cartan_tensor_update_autoregressive_state`.

### Epic 3: Strict Zero-Mock Enforcement in Standard Library & Tests (P1 - Quality)
- **Problem**: `cartan_transformer_layer_forward` and `cartan_swiglu_mlp_forward` contain silent `0.01` fallbacks when weights are null, and Test Target 64 passes null pointers.
- **Solution**:
  - Assert on null weights or require genuine tensor inputs.
  - Update Target 64 (`test_hybrid_resonant_transformer.car`) with initialized test weights and assert non-trivial logit distributions.

### Epic 4: Native Compiled Sasaki Packet Routing Verification (P1 - Performance)
- **Problem**: Sasaki metric and tangent velocity routing was operating on corrupted, clamped state vectors.
- **Solution**:
  - Feed genuine continuous momentum vectors $\dot{h}_t = h_t - h_{t-1}$ through the compiled Sasaki router (`geometry.cl`).
  - Verify multi-stream modulation across all 8 maximal Lie subgroups in sub-milliseconds without Python or OpenCL latency.

---

## 2. Definition of Done (DoD)
- [ ] `geomind.exe --chat -prompt "..."` executes to completion with exit code 0 (zero memory violations).
- [ ] Full vocabulary (up to 262k / active vocabulary table) is accessible without clamping to 3.0.
- [ ] Zero fallback `0.01` constants in `src/std/transformer.cl`.
- [ ] Compiler test suite Target [64/64] passes cleanly.
- [ ] `docs/archive/sprint_442_walkthrough.md` and `CHANGELOG.md` updated.
