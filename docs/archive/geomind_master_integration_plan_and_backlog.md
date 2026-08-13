# Master Architectural Integration Strategy & Product Backlog: GeoMind Prime Engine

**Lead AI Scientist & System Architect:** CARTAN GeoMind Architecture Team  
**Date:** August 11, 2026  
**Target Architecture:** Self-Hosting Native CARTAN (`.car`) Non-Euclidean Engine  
**Archive File:** `docs/archive/geomind_master_integration_plan_and_backlog.md`

---

## I. Executive Summary & Foundational Directives

This document establishes the official **Master Architectural Integration Strategy & Product Backlog** for the **GeoMind Prime Engine**. 

It unifies:
1. **Original GeoMind Vision (`C:\Users\rich-\source\repos\GeoMind`)**: The 248-dimensional continuous $E_8$ Lie Group manifold, 8-Stream 1984D Lie subgroup engine ($SO(16) \dots SU(3)^3$), $4 \times 4$ Freudenthal division algebra MoE grid ($\mathbb{R}, \mathbb{C}, \mathbb{H}, \mathbb{O}$), Sasaki tangent bundle phase-space routing ($TM = M \times T_x M$), Byte Coordinate Encoder Network (BCEN), Kronecker-factored embeddings ($W_{\text{context}} \otimes W_{\text{gauge}}$), and zero-allocation memory pools (~1,072 Tok/s).
2. **Test Engine Advancements (`test/geomind/`)**: Layer-1 Standard Library abstractions (`src/std/`), hardware-probed micro-kernel GEMM tiling (`std::autotune`), Sakana AI M2N2 evolutionary niche fusion (`std::fusion`), teacher-student KL divergence distillation (`std::distill`), SentencePiece BPE decoding (`std::tokenizer`), WordNet/SlangNet Information Content (IC) loss & LCA tree distance logit boosting (`std::semantics`), Absolute Zero Reasoning (AZR) compiler self-play, and Banach fixed-point continuous Hopfield attractor basin relaxation ($E(h)$).
3. **STRICT NON-EUCLIDEAN OPTIMIZATION DIRECTIVE**: **Euclidean Adam optimizers are strictly banned.** Standard Adam, AdamW, and SGD assume flat Euclidean metric spaces ($G_{ij} = \delta_{ij}$), which distort parameter norms, violate Lie algebra bracket symmetries, and cause gradient destruction on curved manifolds. All optimization is strictly governed by the **Finsler-Randers Riemannian Natural Gradient Optimizer (`FinslerOptimizer` / `RiemannianOptimizer`)**, using Sherman-Morrison dual metric updates ($g_{\text{randers}} = g - \frac{g \cdot b}{1 + \|b\|^2} b$), Adaptive Geodesic Gradient Clipping (AGC), and Hyperspherical Exponential Map Retractions ($\text{Exp}_W(v)$).

---

## II. The GeoMind Prime Architecture

```
                  ┌─────────────────────────────────────────────────────────┐
                  │          SentencePiece Tokenizer / Gemma 262k           │
                  └────────────────────────────┬────────────────────────────┘
                                               │
                                 ┌─────────────▼─────────────┐
                                 │ Kronecker Factored Embed  │
                                 │  (W_context ⊗ W_gauge)    │
                                 └─────────────┬─────────────┘
                                               │
                                 ┌─────────────▼─────────────┐
                                 │    Sasaki Phase Router    │
                                 │   (Position x, Velocity v)│
                                 └─────────────┬─────────────┘
                                               │
               ┌───────────────────────────────┴───────────────────────────────┐
               │         1984D Multi-Decomposition Stream Core (8 Streams)      │
               ├──────────────┬──────────────┬──────────────┬──────────────────┤
               │ Stream 0:    │ Stream 1:    │ Stream 2:    │ Stream 3:        │
               │ SO(16)       │ E7 x SU(2)   │ E6 x SU(3)   │ SU(9) Hyperbolic │
               │ Cosformer    │ SSM State    │ Real DFT     │ Poincare Ball    │
               ├──────────────┼──────────────┼──────────────┼──────────────────┤
               │ Stream 4:    │ Stream 5:    │ Stream 6:    │ Stream 7:        │
               │ F4 x G2      │ SO(10)xSU(4) │ SU(5)xSU(5)  │ Loop Homology    │
               │ Simplicial   │ Eikonal Ray  │ Heat Kernel  │ Symplectic       │
               └──────────────┴──────┬───────┴──────────────┴──────────────────┘
                                     │ (Autotuned GEMM Tiling)
                               ┌─────▼─────┐
                               │ 4x4 MoE   │ (Freudenthal Division Algebra Matrix)
                               └─────┬─────┘
                                     │
                        ┌────────────▼────────────┐
                        │ Banach Hopfield Attractor│ (Continuous Spin Relaxation E(h))
                        └────────────┬────────────┘
                                     │
                        ┌────────────▼────────────┐
                        │ 2D GEMM Unembedding Head│ (LCA Tree Distance Logit Boosted)
                        └─────────────────────────┘
```

---

## III. Non-Euclidean Riemannian Optimization Regimen

### 1. Finsler-Randers Metric Density
$$\mathcal{F}(x, v) = \alpha(x, v) + \beta(x, v) \cdot \lambda = \sqrt{a_{ij}(x) v^i v^j} + b_i(x) v^i \cdot \lambda$$
where $a_{ij}$ is the Riemannian base metric and $b_i$ is the anisotropic background action drift field.

### 2. Sherman-Morrison Dual Inverse Metric Projection
$$\mathbf{g}_{\text{randers}} = \mathbf{g} - \left( \frac{\mathbf{g} \cdot \mathbf{b}}{1 + \|\mathbf{b}\|^2} \right) \mathbf{b}$$
Evaluated in linear $O(d)$ time, projecting loss gradients strictly orthogonal to irreversible manifold drift.

### 3. Adaptive Geodesic Gradient Clipping (AGC)
$$\text{clip\_factor} = \min\left(1.0, \frac{\max(0.01 \cdot \|\mathbf{W}\|_M, 0.05)}{\|\mathbf{g}_{\text{randers}}\|_M}\right)$$

### 4. Hyperspherical Exponential Map Retraction
$$\text{Exp}_{\mathbf{W}}(v) = \frac{\mathbf{W}_t - \eta (v_{\text{effective}} + \gamma \mathbf{W}_t)}{\|\mathbf{W}_t - \eta (v_{\text{effective}} + \gamma \mathbf{W}_t)\|}$$
Guarantees parameters remain on unit hyperspherical manifolds ($\|\mathbf{W}\|_{t+1} = 1.0$) without numerical drift.

---

## IV. Integrated Product Backlog & Roadmap

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                             GEOMIND PRIME INTEGRATED ROADMAP                                │
├───────────────────────────────────┬───────────────────────────────────┬─────────────────────┤
│ Milestone A: Core Manifold & Engine│ Milestone B: Subgroup Stream Core │ Milestone C: Intelligence
├───────────────────────────────────┼───────────────────────────────────┼─────────────────────┤
│ • Sprint 100: FRS & Sherman-Morrison│ • Sprint 103: 8-Stream Modular Core│ • Sprint 106: WordNet
│ • Sprint 101: Kronecker Embeddings│ • Sprint 104: 4x4 Division MoE    │ • Sprint 107: AZR   
│ • Sprint 102: BufferPool Memory   │ • Sprint 105: Autotuned GEMM      │ • Sprint 108: M2N2  
└───────────────────────────────────┴───────────────────────────────────┴─────────────────────┘
```

### Phase 1: Core Manifold, Metric Optimization & Memory (Milestone A)

- [ ] **Sprint 100: Finsler-Randers Metric & Sherman-Morrison Optimizer (`test/geomind/geometry.car` & `engine.car`)**
  - Implement `FinslerRandersMetric` and `RiemannianOptimizer` using Sherman-Morrison projection ($g_{\text{randers}} = g - \frac{g \cdot b}{1 + \|b\|^2} b$), AGC clipping, and Exponential Map Retractions. Fully purge all Euclidean Adam terminology and fallbacks.
  - *Verification*: SFT training run exhibits monotone geodesic loss convergence with unit weight norms ($\|W\| = 1.0$).

- [ ] **Sprint 101: Kronecker-Factored Embedding Engine (`src/std/geom.car` & `test/geomind/engine.car`)**
  - Implement $W_{\text{context}} \otimes W_{\text{gauge}}$ embedding factorization, reducing VRAM footprint by 87.5% while mapping 256,000 Gemma tokens onto $S^{247}$ hypersphere coordinates.
  - *Verification*: Memory inspection verifies 87.5% footprint reduction with zero loss of embedding precision.

- [ ] **Sprint 102: Liveness-Analyzed Zero-Allocation Memory Pool (`src/cartanc/c_runtime.c`)**
  - Port OpenCL BufferPool exact-size allocation logic into CARTAN C-runtime static pools, saturating memory on step 1 to achieve zero VRAM allocations during execution.
  - *Verification*: Benchmark confirms zero dynamic `malloc`/`free` calls during 1,000 continuous generative steps (~1,072 Tok/s).

---

### Phase 2: Subgroup Stream Core & Division Algebra MoE (Milestone B)

- [ ] **Sprint 103: 8-Stream 1984D Lie Subgroup Attention Core (`test/geomind/streams.car`)**
  - Port the 8 maximal $E_8$ Lie subgroup streams ($SO(16)$ Cosformer, $E_7 \times SU(2)$ SSM, $E_6 \times SU(3)$ Spectral, $SU(9)$ Poincaré, $F_4 \times G_2$ Homology, $SO(10) \times SU(4)$ Eikonal, $SU(5) \times SU(5)$ Heat Kernel, $SU(3)^3$ Triality) into native `.car` standard library modules.
  - *Verification*: `multi_stream_test.car` regression suite passes with 0 auto-diff gradient desynchronizations.

- [ ] **Sprint 104: 4x4 Division Algebra Freudenthal MoE & Sasaki Router (`test/geomind/moe.car`)**
  - Integrate 16 experts on the $4 \times 4$ composition algebra matrix ($\mathbb{R}, \mathbb{C}, \mathbb{H}, \mathbb{O}$) guided by `SasakiRouter` phase-space distance over position $x$ and velocity momentum $v$.
  - *Verification*: Routing benchmark confirms active expert selection and smooth tangent bundle momentum tracking.

- [ ] **Sprint 105: Hardware Autotuned Tile GEMM Engine (`src/std/autotune.car`)**
  - Wire `std::autotune` micro-kernel tiling (`autotune_matmul_tiled`) across all 8 streams and MoE matrices, probing L1/L2 caches and SIMD registers.
  - *Verification*: Throughput exceeds 4.0M tokens/sec on native CPU hardware.

---

### Phase 3: Intelligence, Taxonomy, Zero-Data Reasoning & Self-Play (Milestone C)

- [ ] **Sprint 106: WordNet IC Loss Weighting & LCA Tree Distance Logit Boosting (`src/std/semantics.car`)**
  - Integrate WordNet/SlangNet hypernym tree taxonomy, scaling cross-entropy loss by $IC(t) = -\log P(t)$ and boosting logits via $O(1)$ Lowest Common Ancestor (LCA) tree distance.
  - *Verification*: SFT loss drops below 2.0 with 0 off-topic hallucinations during chat sessions.

- [ ] **Sprint 107: Zero-Data Latent Reasoning & Banach Fixed-Point Attractor Basin Engine (`test/geomind/chat.car`)**
  - Implement Zero-Data Implicit Chain-of-Thought (Implicit CoT) continuous residual stream transformations ($h_0 \dots h_{32}$) passing through Continuous Hopfield Attractor Basins ($E(h)$).
  - Prove Banach fixed-point contraction mapping convergence ($\|h_{32} - h^*\| \le \frac{\gamma^{32}}{1-\gamma}\|h_1 - h_0\|$) for 32-iteration $E_8$ Lie root lattice recursive self-attention loops.
  - *Verification*: Latent noise injection tests prove 100% recovery to canonical attractor states within 32 iterations without extra text token emission.

- [ ] **Sprint 108: Broad Model Merging & "Zero-Training" Weight Synthesis (`src/std/fusion.car`)**
  - Implement zero-training feature acquisition using the 4 Classic Vectors (SLERP, TIES sign election, DARE drop-and-rescale, Task Arithmetic, Model Soups).
  - Implement Low-Rank Subspace Algebra & KnOTS (Knowledge Orthogonal Task Subspaces) via SVD decomposition ($\Delta W = U \Sigma V^T$) projecting task vectors onto null-spaces ($\Delta W_B^\perp = (I - U_A U_A^T)\Delta W_B (I - V_A V_A^T)$) for instant data-free capability synthesis.
  - *Verification*: Data-free weight fusion achieves multi-task capability alignment with zero cross-talk interference.

- [ ] **Sprint 109: Sakana AI M2N2 Evolutionary Niche Fusion (`src/std/fusion.car`)**
  - Implement Model Merging of Natural Niches (M2N2, GECCO paper) removing rigid fixed-layer parameter partitions using dynamic flexible split-point boundaries.
  - Integrate MAP-Elites quality-diversity optimization and Sakana AI Attraction Heuristic ($S_{\text{attract}}(W_A, W_B) = \frac{\text{Tr}(W_A^T W_B)}{\|W_A\| \|W_B\|}$) mapped onto $E_8$ Lie algebra geodesic crossover.
  - *Verification*: MAP-Elites grid evaluation evolves novel model architectures without human dataset curation.

- [ ] **Sprint 110: Absolute Zero Reasoning (AZR) Autonomous Self-Play (`test/geomind/main.car`)**
  - Implement `--azr-selfplay` CLI driver flag, pairing asymmetric Task Proposer and Task Solver self-play feedback loops.
  - Integrate deterministic `cartanc.exe` code execution verification oracle (compiled exit code 0 yields reward $R=1$; syntax/type errors yield $R=0$) with Group Relative Policy Optimization (GRPO) advantage updates ($\hat{A}_i = \frac{R_i - \bar{R}}{\sigma_R}$) and Proposer progress rewards ($R_{\text{prop}} = 4 P_{\text{solve}} (1 - P_{\text{solve}})$).
  - *Verification*: Native `geomind.exe --azr-selfplay` executes open-ended self-play loops, spontaneously generating multi-step math and coding logic without human QA datasets.

---

## V. Governance & Architectural Rules

1. **Strict Zero Euclidean Fallback**: Every parameter update must pass through `FinslerOptimizer` / `RiemannianOptimizer` via Sherman-Morrison gradient projections and Exponential Retractions.
2. **Pure Native CARTAN Execution**: All code must reside in `.car` files compiled directly by `cartanc.exe`. No C++ or Python FFI wrappers permitted.
3. **Artifact & Roadmap Archival**: Every sprint MUST update `CHANGELOG.md`, `docs/ROADMAP.md`, and archive implementation plans in `docs/archive/`.

---
*Blueprint archived in `docs/archive/geomind_master_integration_plan_and_backlog.md`.*

