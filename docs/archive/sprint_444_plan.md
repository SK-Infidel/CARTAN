# Sprint 444 Plan: 1984D 8-Subgroup Representation, Weyl Group Reflections & Metacognitive Void Detection

## Goal & Mission
Completely advance GeoMind from a single 248D stream to its authentic 1984D multi-decomposition architecture ($8 \times 248\text{D}$ across all 8 maximal Lie subgroups), integrate the 240-root Weyl reflection operator into the Magic Square experts, and port the metacognitive void detection and epiphany discovery into the sleep consolidation engine.

---

## Architectural Breakdown

### 1. 1984D 8-Subgroup Multi-Stream Engine (`streams.cl`, `e8_attention_engine.cl`, `moe.cl`)
- **Purge 320-stride vestige**: Replace the legacy `start_d = s * 320.0` offsets with authentic 248D stream dimensions.
- **8 Maximal Lie Subgroups**:
  1. $SO(16)$ Cosformer Linear Attention (dims 0..247)
  2. $E_7 \times SU(2)$ Selective State-Space Recurrence (dims 0..247)
  3. $E_6 \times SU(3)$ Spectral Harmonic Filter (dims 0..247)
  4. $SU(9)$ Hyperbolic Poincare Metric (dims 0..247)
  5. $F_4 \times G_2$ Simplicial Homology (dims 0..247)
  6. $SO(10) \times SU(4)$ Eikonal Ray-Tracing (dims 0..247)
  7. $SU(5) \times SU(5)$ Laplacian Diffusion (dims 0..247)
  8. $SU(3)^3$ Triality Symplectic Rotation (dims 0..247)
- **`E8StreamHerald` Gauge Exchange**:
  Every 6 layers (`HERALD_EVERY = 6`), streams exchange gauge fields via cross-subgroup attention.
- **Freudenthal Mean Readout**:
  Project the 8 streams to a single 248D vector at the final layer for continuous cosine projection against the 262k SentencePiece vocabulary.

### 2. Weyl Group 240-Root Reflection Entanglement (`geometry.cl`, `moe.cl`)
- Use the 240 canonical roots of $E_8$ initialized in `g_e8_roots_table`.
- Implement `geom_weyl_reflect_vector(v: ptr, root_idx: float) -> ptr`:
  $$s_\alpha(v) = v - \langle v, \alpha \rangle \alpha, \quad \alpha \in \Phi(E_8)$$
  evaluated across the 31 Cartan octaves ($31 \times 8 = 248$).
- Integrate Weyl reflection operators into the 16 Magic Square experts in `moe.cl`.

### 3. Metacognitive Void Detection & Epiphany Discovery (`sleep.cl`, `sleep.car`)
- Implement spherical clustering over active continuous Hopfield attractor basins on the $S^{247}$ hypersphere.
- Identify the largest angular gap (minimum cosine similarity between cluster centroids).
- Synthesize an associative bridge vector and imprint it into slow memory.

### 4. Empirical QA & Regression Verification
- Compile `build/geomind.exe` with `cartanc.exe`.
- Test `--chat`, `--eval-analogy`, and `--sleep`.
- Run full 64-target test suite (`run_tests.exe`) to maintain 100% pass rate.
