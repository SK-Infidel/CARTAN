# Architecture Blueprint: Pure Native CARTAN WebGPU Causal Training Engine

## 1. Executive Summary
This document specifies the migration of the GeoMind training pipeline from legacy C/OpenCL streaming into a 100% pure native CARTAN architecture executing on **WebGPU / WGSL** via [`src/std/gpu.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/gpu.cl). 

By replacing end-of-sequence vector pooling with native 2D causal triangular masked attention in WGSL, every token position $t$ predicts $t+1$ simultaneously, eliminating the 98% supervision waste while dispatching the 8 Lie cortical submanifolds natively to GPU hardware.

---

## 2. Core Architecture Components

### A. WebGPU Causal Autoregressive Sequence Attention (`test/geomind/webgpu_causal_engine.cl`)
- **Native Input Shape**: Matrix $X \in \mathbb{R}^{T \times D}$ where $T$ is sequence length ($64$ or $128$) and $D = 2,560$.
- **WGSL Compute Pipeline**:
  - Computes $Q = X W_Q^T$, $K = X W_K^T$, $V = X W_V^T$.
  - Generates causal attention matrix $A_{i, j} = \frac{Q_i \cdot K_j}{\sqrt{d_k}}$ for $j \le i$ ($-\infty$ for $j > i$).
  - Evaluates row-wise softmax and value accumulation: $\text{Head}_i = \sum_{j=0}^i S_{i, j} V_j$.
- **Full Sequence Supervision**:
  - Target vector $Y = [t_1, t_2, \dots, t_T]$ where position $i$ is supervised on token $i+1$.
  - Loss calculation: $\mathcal{L} = -\frac{1}{T-1} \sum_{i=0}^{T-2} \text{IC}(t_{i+1}) \cdot \log P(t_{i+1})$.

### B. 8-Stream Lie Cortical Submanifold WGSL Dispatch
The 2,560-dimensional hidden vector is partitioned into 8 contiguous slices of 320 dimensions, each routed through its specialized Lie group operator in a single fused WGSL kernel:
1. **$SO(16)$ Cosformer**: Causal cosine attention modulation ($\text{dims } 0 \dots 319$).
2. **$E_7 \times SU(2)$ SSM**: Selective state-space cumulative recurrence ($\text{dims } 320 \dots 639$).
3. **$E_6 \times SU(3)$ Spectral**: Harmonic Fourier frequency filtering ($\text{dims } 640 \dots 959$).
4. **$SU(9)$ Poincaré**: Hyperbolic metric contraction ($\text{dims } 960 \dots 1279$).
5. **$F_4 \times G_2$ Homology**: 3-node simplicial cycle density ($\text{dims } 1280 \dots 1599$).
6. **$SO(10) \times SU(4)$ Eikonal**: Optical wavefront travel time ray tracing ($\text{dims } 1600 \dots 1919$).
7. **$SU(5) \times SU(5)$ Heat Kernel**: Discrete Riemannian manifold Laplacian diffusion ($\text{dims } 1920 \dots 2239$).
8. **$SU(3)^3$ Triality**: Cyclic quaternionic/octonionic phase rotation ($\text{dims } 2240 \dots 2559$).

### C. Continuous Hopfield Resonance Integration
- Queries active attractor basins from [`src/std/resonator.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/resonator.cl) prior to the 42-layer manifold forward pass.
- Ingests verified AZR solutions directly as permanent attractor basins without backprop.

---

## 3. Implementation Plan & Milestones

1. **Milestone 1**: Author native WGSL shader source for Causal Multi-Head Self-Attention in pure CARTAN (`test/geomind/webgpu_causal_engine.cl`).
2. **Milestone 2**: Implement the 8 Lie Subgroup stream kernels in WGSL and link via [`src/std/gpu.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/gpu.cl).
3. **Milestone 3**: Connect the WebGPU training pipeline to `--train-cloze`, `--train-ce`, and `--train-sft` in [`test/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car).
4. **Milestone 4**: Empirically verify 100% causal sequence gradient flow on physical GPU hardware.
