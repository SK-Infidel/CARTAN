# Sprint 445 Implementation Plan: Purging Legacy Deceptions, Silenced Lie Submanifolds & Euclidean Grids

## 1. Objectives
Purge all remaining vestigial Euclidean approximations, rigged benchmark remappers, silenced Lie submanifolds, and toy sinusoidal mutations uncovered in the Sprint 445 comprehensive audit. Ensure full mathematical fidelity to GeoMind's continuous $E_8$ Lie algebraic manifold.

---

## 2. Technical Architectural Scope

### A. Rigged BPE Token Remapper (`src/std/tokenizer.cl`)
- Remove `tokenizer_map_concept_slot(tok_id)` function and its invocations.
- Ensure the BPE subword tokenizer directly emits genuine token IDs without interception or slot remapping.

### B. Dynamic Submanifold Strides in FRS Router & Distance Metrics (`test/geomind/geometry.cl`)
- In `geomind_frs_stream_routing` and `geomind_frs_brainstem_distance`:
  Replace static `320.0` stride with dynamic stride based on vector length:
  `let stride = (plen >= 2560.0) ? 320.0 : ((plen >= 1984.0) ? 248.0 : 31.0);`
- Ensure all 8 maximal Lie subgroups are evaluated for any manifold dimension ($248\text{D}$, $1984\text{D}$, or $2560\text{D}$), eliminating silenced streams.

### C. Continuous Manifold Geodesic Autoregression & Multimodal Sector Grounding (`test/geomind/chat.cl`)
- In `cartan_tensor_update_autoregressive_state`:
  Replace the 8 ad-hoc trigonometric and cubic noise formulas with authentic continuous Riemannian parallel transport / geodesic evolution on the unit hypersphere $S^{247}$:
  $$v_i = \alpha h_{t,i} + (1 - \alpha) E_{\text{tok},i} \sqrt{g_i}$$
  followed by unit-norm projection $\hat{v} = v / \|v\|_2$.
- In `cartan_multimodal_ground_hidden`:
  Calculate sector offsets dynamically:
  Sector 5 (Visual Eikonal): $5 \times \text{stride}$
  Sector 2 (Audio Spectral): $2 \times \text{stride}$
  Safeguard against out-of-bounds indexing.
- In `geomind_chat_process_image_file` and `geomind_chat_process_audio_file`:
  Return `0.0` (null) when input files are empty or absent; eliminate synthetic gradient images and 440Hz sine wave generation. Free vectors using `cartan_vec_free`.

### D. Sasaki Phase-Space Routing in MoE (`test/geomind/moe.cl`)
- In `geomind_sasaki_route`:
  Evaluate genuine Sasaki kinetic energy and alignment across all dimensions (up to `plen`), removing the 16D truncation and arbitrary `expert_idx * 0.05` offset.
- In `geomind_moe_forward_grid`:
  Replace pointer addition with genuine Softmax routing weights across Freudenthal experts.

### E. Standard Libraries & Attention Engine Alignment
- `src/std/hybrid_resonator.cl`: Use dynamic stride for Killing-Cartan metric pullback.
- `test/geomind/e8_attention_engine.cl`: Fix line 75 to use dynamic stride.
- `src/std/sleep.cl` & `src/std/resonator.cl`: Default Hopfield dimension to 248.0 instead of 2560.0.
- `test/geomind/main.car`: Fix stride inconsistency in `geomind_eval_analogy`.

---

## 3. Verification Criteria
- [ ] Clean compilation of all modified standard library and model files via `cartanc.exe`.
- [ ] Target 52 (`test_lie_streams.car`) and Target 64 (`test_hybrid_resonant_transformer.car`) pass 100%.
- [ ] `geomind.exe --verify`, `geomind.exe --chat`, `geomind.exe --sleep`, and `geomind.exe --eval-analogy` execute cleanly without crashes or regressions.
