# Sprint 479 Implementation Plan: Non-Euclidean Geometric Manifold Transformation & Empirical Analogy Alignment

**Sprint**: 479  
**Goal**: Design, implement, and benchmark non-Euclidean geometric manifold transformations to bridge flat Euclidean Gemma embeddings ($\mathbb{R}^{2560}$) into GeoMind's Lie group architecture. Establish a canonical analogy benchmark dataset, fix measurement normalization bugs, and measure empirical rank/cosine gap telemetry without expert system priming.  
**Pair Programmers**: Rick & Antigravity  

---

## 1. Problem Statement & Root Cause

1. **Analogy Metric Distortion ([ISSUE-284])**:
   In `test/geomind/main.car:416`, `sim = dot / norm_t;` divides only by query vector norm $\|\vec{v}_t\|$, failing to divide by candidate vector norms $\|\vec{v}_c\|$. Tokens with large norms falsely dominate the evaluation.
2. **Decoupling from Full Model Embeddings ([ISSUE-285])**:
   `geomind_eval_single_analogy` in `test/geomind/main.car` branches exclusively into legacy 248D coordinates (`geomind_e8_embeddings.bin`) rather than Gemma's authentic 2,560D embedding table (`geomind_embeddings_full_262k.bin`).
3. **Representation Degeneration & Non-Euclidean Distortion ([ISSUE-286])**:
   Flat Euclidean embeddings reside in an anisotropic cone with a non-zero mean. GeoMind operates on an anisotropic Finsler-Randers metric space with 8 Lie subgroups and Sasaki tangent bundle dynamics. Flat embeddings must undergo Riemannian metric-aware centering, Killing-Cartan whitening, and geodesic parallel transport.
4. **Absence of Canonical Benchmark Dataset & Telemetry ([ISSUE-287])**:
   Only 4 manual analogies currently exist in `main.car`. An automated multi-category benchmark suite (semantic: family, capital-country, currency; syntactic: comparative, superlative, opposite) is required to empirically quantify the gap.

---

## 2. Architectural Deliverables

### Phase 1: Analogy Evaluator Normalization & Multi-Dimension Ingestion (`test/geomind/main.car`, `src/std/cartan_native_io.c`)
- **Fix Cosine Formula**: Ensure all candidate similarity evaluations divide by both query and candidate norms:
  $$\cos(\theta) = \frac{\langle u, v \rangle}{\|u\| \cdot \|v\|}$$
  Or pre-normalize candidate vectors so $\|\hat{v}\| = 1.0$.
- **Fast AVX2/AVX-512 SIMD Top-K Kernel**: Implement `c_cartan_analogy_search_topk` in `src/std/cartan_native_io.c` to evaluate all 262,144 candidates in $< 40\text{ ms}$ instead of $35\text{--}60\text{ seconds}$ in scalar CARTAN.
- **Wire 2,560D Authentic Embedding Mode**: Support evaluating directly against `geomind_embeddings_full_262k.bin`.

### Phase 2: Canonical Analogy Benchmark Dataset (`test/geomind/trainingdata/analogy_benchmark.json`)
- Author a balanced, curated benchmark dataset across 6 categories:
  - Semantic: Family (king:queen, father:mother, boy:girl, etc.), Capital-Country (paris:france, tokyo:japan, etc.), Currency (usa:dollar, japan:yen, etc.).
  - Syntactic: Comparative (fast:faster, dark:darker, etc.), Superlative (fast:fastest, high:highest, etc.), Opposites (good:bad, hot:cold, etc.).
- Ensure all words map to verified single BPE tokens in Gemma's 262k vocabulary.
- Operate with **zero expert system priming** across the full 262k vocabulary.

### Phase 3: Non-Euclidean Geometric Manifold Transformation Substrate (`tools/transform_manifold_embeddings.py`, `src/std/geom.cl`)
- Implement a 4-phase transformation algorithm:
  1. **Phase 1 (Baseline)**: Raw Gemma flat Euclidean $\mathbb{R}^{2560}$.
  2. **Phase 2 (Centered & Whitened Hypersphere $S_G^{2559}$)**:
     $$\tilde{x} = x - \mu, \quad \hat{x} = \frac{\tilde{x}}{\sqrt{\tilde{x}^T G \tilde{x}}}$$
     contracted with Killing-Cartan metric tensor $G = \text{diag}(\kappa_0 I_{320}, \dots, \kappa_7 I_{320})$.
  3. **Phase 3 (8-Subgroup Lie Cartan Projection)**: Orthogonal projection into the 8 Lie submanifolds.
  4. **Phase 4 (Riemannian Geodesic Parallel Transport)**:
     $$v = \log_b(a) \in T_b M, \quad P_{b \to c}(v) \in T_c M, \quad d = \exp_c(P_{b \to c}(v)) \in M$$
- Output standardized `CARM` binary file containing transformed manifold coordinates.

### Phase 4: Empirical Telemetry & Gap Quantification
- Measure Top-1 Accuracy, Top-5 Accuracy, Mean Reciprocal Rank (MRR), and Cosine Margin across all 4 transformation phases.
- Truth-first reporting: document exact numbers without simulated or mocked outputs.

---

## 3. Regression Prevention & DoD
- All 87 compiler test suite targets must compile and pass cleanly via `tools/run_affected_tests.ps1`.
- Clean compilation of `geomind.exe` with `cartanc.exe`.
- All plans, tasks, and walkthroughs saved to `docs/archive/`.
- `CHANGELOG.md` and `ISSUES.md` updated.
