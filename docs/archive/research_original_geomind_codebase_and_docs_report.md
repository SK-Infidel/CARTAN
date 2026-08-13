# Scientific Research Survey: Original GeoMind (.ctn) Codebase & Documentation Audit

**Lead AI Scientist & Research Team:** CARTAN GeoMind Project Group  
**Date:** August 11, 2026  
**Source Repositories Audited:**  
- Documentation: `C:\Users\rich-\source\repos\GeoMind\Documentation`  
- Source Codebase: `C:\Users\rich-\source\repos\GeoMind\source` (and `Archive/csrc/`, `Archive/core/`)  
**Target Architecture:** Bare-Metal CARTAN Non-Euclidean Engine  

---

## Executive Overview

This master research report presents a comprehensive scientific analysis of the **original GeoMind system**, as documented in `C:\Users\rich-\source\repos\GeoMind\Documentation` and implemented across native `.ctn` CARTAN source files in `C:\Users\rich-\source\repos\GeoMind\source`.

GeoMind represents a continuous geometric artificial intelligence architecture built on the **248-dimensional $E_8$ Lie Group manifold**, **Finsler-Randers-Sasaki (FRS) metric differential geometry**, an **8-Stream Freudenthal Magic Square Mixture-of-Experts (MoE)**, and **Native CARTAN (.ctn) Memory Primitives**.

---

## Section 1: Original Foundational Vision & Architectural Principles

### 1.1 The 248-Dimensional $E_8$ Manifold Continuum
Traditional deep learning treats representations as flat vectors in Euclidean space ($\mathbb{R}^n$). GeoMind embeds neural parameters directly onto the 248-dimensional continuous manifold of the $E_8$ Lie algebra.
- **240 Root Vectors & Kissing Number**: $E_8$ possesses 240 root vectors of length $\|r\| = \sqrt{2}$ with a kissing number of 240 (56 nearest neighbors per root node).
- **Unimodular Self-Duality ($E_8^* = E_8$)**: Enables tied weights between embedding and coordinate output heads without dimensional distortion.

### 1.2 Virtual Parameter Combinatorics
Rather than expanding parameter count (e.g., 400B+ params), GeoMind utilizes virtual parameters on symmetrical continuous Lie manifolds. High representational capacity is achieved through coordinate precision rather than linear parameter duplication.

### 1.3 Open-Vocabulary Packet Model & Byte Coordinate Encoder (BCEN)
Replaces discrete token dictionaries with continuous byte trajectories via the Byte Coordinate Encoder Network (BCEN). Tokens act as physical packets carrying a geometric coordinate header (position $x$, velocity $\dot{x}$) and a structural payload.

---

## Section 2: System Architecture — The 8-Stream 1984D Engine & 4x4 MoE

```
                  ┌─────────────────────────────────────────────────────────┐
                  │                 Byte Input / Gemma 262k                 │
                  └────────────────────────────┬────────────────────────────┘
                                               │
                                 ┌─────────────▼─────────────┐
                                 │ BCEN / Continuous Embed   │
                                 │    (248D Coordinate x)    │
                                 └─────────────┬─────────────┘
                                               │
                                 ┌─────────────▼─────────────┐
                                 │      Brainstem Router     │
                                 │   (Sasaki Metric x, ẋ)    │
                                 └─────────────┬─────────────┘
                                               │
               ┌───────────────────────────────┴───────────────────────────────┐
               │         1984D Multi-Decomposition Stream Core (8 Streams)      │
               ├──────────────┬──────────────┬──────────────┬──────────────────┤
               │ Stream 0:    │ Stream 1:    │ Stream 2:    │ Stream 3:        │
               │ SO(16)       │ E7 x SU(2)   │ E6 x SU(3)   │ SU(9) Hyperbolic │
               ├──────────────┼──────────────┼──────────────┼──────────────────┤
               │ Stream 4:    │ Stream 5:    │ Stream 6:    │ Stream 7:        │
               │ F4 x G2      │ SO(10)xSU(4) │ SU(5)xSU(5)  │ Loop Homology    │
               │              │ Eikonal Ray  │ Heat Diffusion│ Symplectic       │
               └──────────────┴──────┬───────┴──────────────┴──────────────────┘
                                     │ (Cross-Stream Heralding)
                               ┌─────▼─────┐
                               │ 4x4 MoE   │ (Freudenthal Magic Square)
                               └─────┬─────┘
                                     │
                        ┌────────────▼────────────┐
                        │ Dynamic Decoders Head   │ (Nearest Lattice / SFT Cross-Entropy)
                        └─────────────────────────┘
```

### 2.1 The 8 Geometric Attention Streams (`source/streams.ctn`)
GeoMind decomposes its $1984\text{D}$ core engine across the 8 maximal Lie subgroups of $E_8$:

| Stream Index | Submanifold Symmetry | Algorithmic Stream Type | Key Computation / Mathematical Model |
| :--- | :--- | :--- | :--- |
| **0** | $\text{SO}(16)$ | `CosformerStream` | Register-tiled linear attention with causal max-scaling |
| **1** | $\text{E}_7 \times \text{SU}(2)$ | `SSMStream` | Selective State-Space commutator with cumulative sum (`cumsum_inplace`) |
| **2** | $\text{E}_6 \times \text{SU}(3)$ | `SpectralStream` | Real discrete Fourier transform (DFT) spectral memory filtering |
| **3** | $\text{SU}(9)$ | `PoincareStream` | Poincaré hyperbolic distance: $d_P(u,v) = \text{acosh}\left(1 + 2\frac{\|u-v\|^2}{(1-\|u\|^2)(1-\|v\|^2)}\right)$ |
| **4** | $\text{F}_4 \times \text{G}_2$ | `HomologyStream` | Topological 3-node simplicial complex loop density ($s_{lj} \sum s_{lk} s_{jk} s_{lj}$) |
| **5** | $\text{SO}(10) \times \text{SU}(4)$ | `EikonalStream` | Geodesic ray-tracing optical path length $\tau = \sum \text{speed}[k]$ |
| **6** | $\text{SU}(5) \times \text{SU}(5)$ | `HeatKernelStream` | Discrete Laplacian diffusion: $Y = x - t Z + \frac{1}{2} t^2 D Z$ |
| **7** | $\text{SU}(3)^3$ | `TrialityStream` | Symplectic 3-block cyclic rotation ($80\text{D} \times 3$) |

### 2.2 Freudenthal Magic Square 4x4 MoE (`source/moe.ctn`)
16 expert MLPs arranged on a $4 \times 4$ tensor matrix of division algebra pairs $(\mathbb{R}, \mathbb{C}, \mathbb{H}, \mathbb{O})$:

| Row / Col | $\mathbb{R}$ | $\mathbb{C}$ | $\mathbb{H}$ | $\mathbb{O}$ |
| :--- | :--- | :--- | :--- | :--- |
| **$\mathbb{R}$** | Expert 0: $\mathfrak{so}(3)$ | Expert 1: $\mathfrak{su}(3)$ | Expert 2: $\mathfrak{sp}(3)$ | Expert 3: $\mathfrak{f}_4$ |
| **$\mathbb{C}$** | Expert 4: $\mathfrak{su}(3)$ | Expert 5: $\mathfrak{su}(3)\oplus\mathfrak{su}(3)$ | Expert 6: $\mathfrak{su}(6)$ | Expert 7: $\mathfrak{e}_6$ |
| **$\mathbb{H}$** | Expert 8: $\mathfrak{sp}(3)$ | Expert 9: $\mathfrak{su}(6)$ | Expert 10: $\mathfrak{so}(12)$ | Expert 11: $\mathfrak{e}_7$ |
| **$\mathbb{O}$** | Expert 12: $\mathfrak{f}_4$ | Expert 13: $\mathfrak{e}_6$ | Expert 14: $\mathfrak{e}_7$ | Expert 15: $\mathfrak{e}_8$ |

### 2.3 Sasaki Tangent Bundle Router
The `SasakiRouter` routes inputs across the tangent bundle $TM = M \times T_x M$, evaluating phase-space distance over position $x$ and velocity momentum $v = x_l - x_{l-1}$:
$$d_{\text{Sasaki}}^2(e) = \sum_{d=0}^{14} \left( x_{e,d}^2 + v_{e,d}^2 \right)$$
$$\text{logits}_e = -d_{\text{Sasaki}}^2(e) \cdot \sigma_{\text{Shannon}}$$

---

## Section 3: Differential Geometry & Metric Optimization

### 3.1 Finsler-Randers-Sasaki (FRS) Anisotropic Geometry
GeoMind models distance using an asymmetric Finsler-Randers metric density:
$$F(x, y) = \alpha(x, y) + \beta(x, y) = \sqrt{a_{ij}(x) y^i y^j} + b_i(x) y^i$$
where $a_{ij}(x)$ is the local Riemannian metric tensor lifted onto the tangent bundle, and $b_i(x)$ is the structural anisotropic 1-form drift field ($||b(x)||_a < 1$).

Because $F(x, y) \neq F(x, -y)$ when $b \neq 0$, movement along direction $+y$ experiences dynamic drift assistance or resistance.

### 3.2 Sherman-Morrison Randers Backward Pass
To backpropagating gradients against anisotropic background action drift, GeoMind applies the **Sherman-Morrison inverse metric transform**:
$$g_i' = g_i - \left( \frac{g \cdot b}{1 + \|b\|^2} \right) b_i$$

In `source/geometry.ctn`:
```cartan
fn compute_geodesic_gradient(grad: tensor) -> tensor {
    var beta_sq = drift_vector @ drift_vector;
    var dot_beta = grad @ drift_vector;
    var denom = 1.0 + beta_sq;
    var factor = dot_beta / denom;
    var correction = drift_vector * factor;
    return grad - correction;
}
```

Adaptive Gradient Clipping (AGC) is applied to prevent gradient explosion:
$$\text{clip\_factor} = \min\left(1.0, \frac{\max(0.01 \cdot \|w\|, 0.05)}{\|g'\|}\right)$$
$$w_{t+1} = w_t - \eta \cdot (g' \cdot \text{clip\_factor}) - \eta \cdot \lambda_{\text{wd}} \cdot w_t$$

---

## Section 4: Tokenization & Embedding Memory Reduction

1. **Native Heap Linked-List BPE Engine (`source/tokenizer_full.ctn`)**:
   Tokenization operates natively in CARTAN without C++ string reliance using parallel heap linked-lists (`token_ids`, `next`, `prev`) and binary-searched pair ranks (`search_merge`).
2. **Kronecker-Factored Embeddings**:
   Reduces VRAM embedding footprint by **87.5%** by factoring $W \in \mathbb{R}^{V \times 248}$ into spatial context matrix $W_{\text{context}} \in \mathbb{R}^{V \times 31}$ and algebraic gauge matrix $W_{\text{gauge}} \in \mathbb{R}^{8 \times 8}$:
   $$W[:, 8i : 8(i+1)] = W_{\text{context}}[:, i] \otimes W_{\text{gauge}}[i \bmod 8, :]$$

---

## Section 5: Source Code File Inventory (`source/`)

| File Name | Size (Bytes) | Primary Responsibility |
| :--- | :--- | :--- |
| `geometry.ctn` | 1,609 B | Manifold declarations, Finsler-Randers metric, Sherman-Morrison autograd |
| `engine.ctn` | 1,972 B | `GeoMindHybridEngine`, trajectory processing, Safetensors ingestion |
| `moe.ctn` | 4,800 B | $4 \times 4$ Freudenthal division algebra MoE grid & SasakiRouter |
| `streams.ctn` | 1,174 B | 8 continuous geometric attention streams ($SO(16) \dots SU(3)^3$) |
| `inference.ctn` | 3,149 B | `run_chat` & `run_generate` autoregressive voice box CLI engine |
| `pretrain.ctn` | 2,302 B | `run_causal_pretrain` causal pretraining loop with elastic LR |
| `sft.ctn` | 1,482 B | `run_sft_train` Supervised Fine-Tuning loop with WebScraper ingestion |
| `tokenizer.ctn` | 4,636 B | Native BPE tokenization engine |
| `tokenizer_full.ctn` | 4,661 B | Full heap linked-list BPE engine with binary search merge tables |
| `geomind.ctn` | 3,908 B | Master CLI driver (`--train-causal`, `--train-interactive`, `--chat`) |
| `sleep.ctn` | 395 B | Async background metacognitive sleep memory consolidation loop |
| `server.ctn` | 659 B | Native web server interface |
| `multi_stream_test.ctn` | 2,139 B | Test suite for 8-stream forward/backward auto-diff |

---

## Architectural Synthesis Matrix

| Subsystem | Math / Physical Foundation | Source File (`source/`) | Legacy C++ Kernel (`Archive/csrc/`) |
| :--- | :--- | :--- | :--- |
| **Manifolds** | 248-dim $E_8$ Lie Group | `geometry.ctn` | `geomath.h` (`e8_trace`) |
| **Metric Space** | Finsler-Randers-Sasaki (FRS) | `geometry.ctn` | `kernels.cl.h` (`finsler_geodesic_update`) |
| **Autograd** | Sherman-Morrison Matrix Inversion | `geometry.ctn` | `optimizer.cpp` (`FinslerOptimizer`) |
| **Routing** | Sasaki Tangent Bundle ($TM = M \times T_x M$) | `moe.ctn` | `kernels.cl.h` (`sasaki_routing`) |
| **MoE Grid** | $4 \times 4$ Freudenthal Division Algebra | `moe.ctn` | `kernels.cl.h` (`freudenthal_moe`) |
| **Streams** | 8 Maximal Subgroups of $E_8$ | `streams.ctn` | `kernels.cl.h` (8 stream kernels) |
| **Tokenization** | Kronecker Factored Context $\otimes$ Gauge | `tokenizer_full.ctn` | `kernels.cl.h` (`embedding_kronecker`) |

---
*Document archived in `docs/archive/research_original_geomind_codebase_and_docs_report.md`.*
