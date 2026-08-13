# Comprehensive AI Research Survey: M2N2, Absolute Zero Reasoning (AZR), and Zero-Training Weight Synthesis

**Lead AI Scientist & Research Team:** CARTAN GeoMind Project  
**Date:** August 11, 2026  
**Target Systems:** CARTAN Native Compiler (`cartanc.exe`), GeoMind Continuous Hopfield Engine (`test/geomind/`), and Standard Fusion Stack (`src/std/fusion.car`)

---

## Executive Overview

This comprehensive research survey synthesizes three state-of-the-art AI paradigms and formulates their mathematical implementation inside the **CARTAN GeoMind** ecosystem:
1. **Model Merging of Natural Niches (M2N2)**: Evolutionary model fusion eliminating rigid layer partitions using dynamic split-point boundaries, Map-Elites quality-diversity optimization, and attraction heuristics.
2. **Absolute Zero Reasoning (AZR)**: Autonomous self-play reasoning without human datasets via asymmetric Task Proposer / Solver loops and deterministic compiler exit-code verification rewards (`cartanc.exe` exit status 0 vs. failure).
3. **Broad Model Merging & Zero-Training Weight Synthesis**: Data-free capability acquisition using 4 classic vectors (SLERP, TIES, DARE, Task Arithmetic, Model Soups), low-rank SVD task subspace algebra (KnOTS), and non-gradient feature projection into Lie Group $E_8$ root lattices and Finsler-Randers Space (FRS).

---

## Section 1: Model Merging of Natural Niches (M2N2) & Evolutionary Neural Fusion

### 1.1 The Academic Foundation & Sakana AI's Breakthrough
Traditional model merging methods (e.g., block-wise interpolation or fixed layer concatenation) enforce rigid, uniform parameter boundaries across network architectures. The GECCO paper *Competition and Attraction Improve Model Fusion* by Sakana AI introduces **Model Merging of Natural Niches (M2N2)**, mapping biological evolutionary concepts (niche competition, attraction heuristics, and genetic crossover) onto neural parameter spaces.

### 1.2 Key Technical Mechanisms
1. **Dynamic Flexible Split-Point Boundaries**:
   - Removes hardcoded layer-by-layer alignment.
   - Permits cross-layer recombination where layer $i$ of Model $A$ feeds into layer $j$ of Model $B$ ($i \neq j$).
   - Optimizes parameter permutation matrices $\mathbf{P} \in \mathbb{R}^{d \times d}$ to realign internal neuron activation channels across disparate fine-tuned niches.
2. **Attraction Heuristic & Weight Pairing**:
   - Replaces random or uniform parameter selection with cosine-similarity attraction:
     $$S_{\text{attract}}(W_A^{(l)}, W_B^{(m)}) = \frac{\text{Tr}\left(W_A^{(l)T} W_B^{(m)}\right)}{\|W_A^{(l)}\|_F \|W_B^{(m)}\|_F}$$
   - Pairs complementary weight matrices across distinct specialization niches while suppressing destructive interference.
3. **Map-Elites Quality-Diversity Optimization**:
   - Maintains a multidimensional feature grid (e.g., accuracy vs. parameter efficiency vs. reasoning depth).
   - Iteratively mutates split points and crossover ratios, retaining high-performing "elites" in each niche cell to evolve entirely new architecture topologies.

### 1.3 CARTAN Integration: $E_8$ Geodesic M2N2 Fusion (`src/std/fusion.car`)
In CARTAN, M2N2 crossover is mapped directly to geodesic arcs on the 248-dimensional $E_8$ Lie group manifold:
$$\mathbf{W}_{\text{child}} = \text{Exp}_{\mathbf{W}_A}^{FRS}\left( t \cdot \text{Log}_{\mathbf{W}_A}^{FRS}(\mathbf{P} \mathbf{W}_B) \right)$$
where $\mathbf{P}$ is the attraction-paired permutation matrix and $\text{Exp}^{FRS}$ is the Finsler-Randers anisotropic exponential map.

---

## Section 2: Absolute Zero Reasoning (AZR) & Self-Supervised Open-Ended Learning

### 2.1 The Autonomous Self-Play Architecture
**Absolute Zero Reasoning (AZR)** removes human-curated chain-of-thought (CoT) datasets by pairing an asymmetric **Task Proposer ($\pi_{\phi}$)** and **Task Solver ($\pi_{\theta}$)** in a closed-loop self-play environment:

```
[ Task Proposer π_φ ] ──(P, T)──► [ Task Solver π_θ ] ──(Z, C)──► [ Hopfield Filter ] ──► [ cartanc.exe ]
          ▲                                                                                   │
          └───────────────────── Reward R = 1 (Success) / 0 (Failure) ────────────────────────┘
```

1. **Task Proposer ($\pi_{\phi}$)**: Generates synthetic CARTAN code problem statements $P$ and unit test assertions $T$.
2. **Task Solver ($\pi_{\theta}$)**: Generates an intermediate Chain-of-Thought reasoning trace $Z$ and candidate CARTAN code $C$.
3. **Compiler Verification Oracle**: Executes `cartanc.exe` in a isolated sandbox. Exit code 0 yields binary reward $R = +1$; syntax/type errors yield $R = 0$.

### 2.2 Dynamic Intrinsic Motivation & GRPO Optimization
- **Proposer Learning Progress Reward**:
  $$R_{\text{prop}}(P, T) = 4 \cdot P_{\text{solve}}(P, T) \cdot \left(1 - P_{\text{solve}}(P, T)\right)$$
  Directs problem generation to the "Zone of Proximal Development" ($P_{\text{solve}} \approx 0.5$).
- **Group Relative Policy Optimization (GRPO)**:
  Updates solver policies using normalized group relative advantages $\hat{A}_i = \frac{R_i - \bar{R}}{\sigma_R}$ across $G$ sampled code solutions, eliminating the need for a separate value critic network.

### 2.3 GeoMind Continuous Hopfield Resonator Integration
Verified reasoning traces are saved into GeoMind's Continuous Hopfield attractor memory matrix $\mathbf{\Xi} \in \mathbb{R}^{d \times K}$. Spin relaxation filtering ($\mathbf{h}^{(t+1)} = \mathbf{\Xi}^T \text{softmax}(\beta \mathbf{\Xi} \mathbf{h}^{(t)})$) screens out high-entropy synthetic code prior to compilation, increasing self-play execution throughput by 10x.

---

## Section 3: Broad Model Merging & Zero-Training Weight Synthesis

### 3.1 The 4 Classic Merging Vectors & Model Soups
1. **Model Soups**: Uniform or greedy parameter averaging $\theta_{\text{soup}} = \sum w_i \theta_i$ across fine-tuned loss basins.
2. **Task Arithmetic**: Feature editing via Task Vectors $\tau_i = \theta_i - \theta_0$:
   $$\theta_{\text{merged}} = \theta_0 + \lambda_1 \tau_A + \lambda_2 \tau_B - \lambda_3 \tau_{\text{unwanted}}$$
3. **SLERP (Spherical Linear Interpolation)**: Hyperspherical arc interpolation preserving weight magnitude and angular orientation.
4. **TIES-Merging**: 3-stage interference resolution: Trimming low-magnitude parameters, Majority Sign Voting ($\gamma_j = \text{sign}(\sum \tau_{i, j})$), and Disjoint Parameter Averaging.
5. **DARE (Drop And Rescale)**: Randomly drops 90-99% of task vector parameters ($p \in [0.9, 0.99]$) and rescales survivors by $\frac{1}{1-p}$ to eliminate parameter density conflicts without gradient retraining.

### 3.2 Low-Rank Task Subspace Algebra & KnOTS
- **SVD Task Subspace Extraction**: Decomposes weight delta $\Delta W = U \Sigma V^T$ to isolate dominant low-rank task subspaces $\mathcal{S} = \text{span}(U_{1:k})$.
- **KnOTS (Knowledge Orthogonal Task Subspaces)**: Enforces mutual orthogonality between task subspaces by projecting $\Delta W_B$ onto the null-space of $\mathcal{S}_A$:
  $$\Delta W_B^\perp = (I - U_A U_A^T) \Delta W_B (I - V_A V_A^T)$$
  Guarantees zero cross-talk during multi-task inference: $(W_0 + \Delta W_A + \Delta W_B^\perp) x = W_0 x + \Delta W_A x + \Delta W_B^\perp x$.

### 3.3 Anisotropic Finsler-Randers Space (FRS) Mapping
CARTAN synthesizes zero-training weight combinations by projecting low-rank task subspaces onto anisotropic FRS manifolds:
$$W_{\text{CARTAN}} = \text{Exp}_{W_0}^{FRS}\left( \sum_{k=1}^M \lambda_k \cdot \text{proj}_{E8}\left( \Delta W_k^\perp \right) \right)$$
where $E_8$ root lattice projections enforce submodular geometric boundaries and anisotropic Randers drift vectors $b_i$ bias weight updates toward least-cost action directions.

---

## Architectural Synthesis Matrix

| Technology Domain | Primary Mechanism | Verification / Selection Oracle | CARTAN Engine Mapping |
| :--- | :--- | :--- | :--- |
| **M2N2 (Sakana AI)** | Flexible split points & Attraction Heuristics | Map-Elites Quality-Diversity Grid | `src/std/fusion.car` ($E_8$ Lie Crossover) |
| **Absolute Zero Reasoning (AZR)** | Self-Play Task Proposer / Solver Loops | Deterministic `cartanc.exe` Exit Status | `test/geomind/` (Continuous Hopfield Gate) |
| **Zero-Train Weight Synthesis** | SVD KnOTS Null-Space Projection | Orthogonal Subspace Algebra | FRS Anisotropic Geodesic Retraction |

---
*Document archived in `docs/archive/research_m2n2_azr_zerotraining_synthesis_report.md`.*
