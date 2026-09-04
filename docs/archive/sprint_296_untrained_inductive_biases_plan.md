# Sprint 296 Implementation Plan: Authentic Untrained Network Inductive Biases (WANN, DIP, ELM, ESN) (`[ISSUE-045]`)

## 1. Objective & Scope
Resolve `[ISSUE-045]` by replacing pseudo-implementations and mock calculations across four neural architecture modules in `src/std/`:
- `src/std/wann.cl`: Weight-Agnostic Neural Networks (WANN) DAG topology and multi-node signal propagation.
- `src/std/dip.cl`: Deep Image Prior (DIP) genuine iterative gradient descent optimization over parameter weights $f_\theta(z)$.
- `src/std/elm.cl`: Extreme Learning Machine (ELM) genuine random projection matrix, Gram matrix formation $H^T H + \alpha I$, and Gaussian elimination pseudo-inverse solve.
- `src/std/esn.cl`: Echo State Network (ESN) genuine 2D recurrent reservoir matrix-vector update $x(t) = \tanh(W_{in} u(t) + W_{res} x(t-1))$ and Ridge readout solve.

---

## 2. Technical Architecture & Algorithms

### A. Weight-Agnostic Neural Networks (`src/std/wann.cl`)
- **Topology SoA**:
  - `num_inputs`, `num_outputs`, `node_count`.
  - Node activation table: `0` (Linear), `1` (Tanh), `2` (ReLU), `3` (Sigmoid), `4` (Sin), `5` (Step).
  - Edges: list of `[src, dst, scale, enabled]`.
- **Node Mutation**: `wann_mutate_add_node` disables target edge and inserts intermediate node with specified activation.
- **Topological Forward Pass**: Multi-pass signal propagation over DAG edges using scalar `shared_w` and genuine node activations.

### B. Deep Image Prior (`src/std/dip.cl`)
- **Untrained Parameter Network $f_\theta(z)$**:
  - Continuous coordinate grid $z_i \in \mathbb{R}^{C_{in}}$.
  - 2-layer parameterized MLP: $W_1 \in \mathbb{R}^{H \times C_{in}}$, $B_1 \in \mathbb{R}^H$, $W_2 \in \mathbb{R}^{1 \times H}$, $B_2 \in \mathbb{R}^1$.
- **Authentic Gradient Descent Optimization**:
  - Forward pass: $h_i = \tanh(W_1 z_i + B_1)$, $\hat{y}_i = W_2 h_i + B_2$.
  - Loss: $\frac{1}{L} \sum (\hat{y}_i - y_i)^2$.
  - Backward pass: exact analytical gradients $\nabla_\theta \mathcal{L}$.
  - Weight updates: $\theta \leftarrow \theta - \eta \nabla_\theta \mathcal{L}$ for `max_iters` iterations.

### C. Extreme Learning Machine (`src/std/elm.cl`)
- **Random Projection**: Frozen random input projection $W_{in} \in \mathbb{R}^{H \times D_{in}}$, bias $B \in \mathbb{R}^H$.
- **Closed-Form Ridge Regression**:
  - Hidden activations $H \in \mathbb{R}^{N \times H}$: $H_{i, j} = \tanh(W_{in} x_i + B)$.
  - Gram matrix $G = H^T H + \alpha I \in \mathbb{R}^{H \times H}$.
  - Target projection $T = H^T Y \in \mathbb{R}^{H \times D_{out}}$.
  - Linear solve via Gaussian elimination with partial pivoting.

### D. Echo State Network (`src/std/esn.cl`)
- **Reservoir Dynamics**:
  - $W_{in} \in \mathbb{R}^{R \times D_{in}}$ (random input projection).
  - $W_{res} \in \mathbb{R}^{R \times R}$ (recurrent connectivity scaled to spectral radius $\rho$).
  - Full state step: $x(t) = \tanh(W_{in} u(t) + W_{res} x(t-1))$.
- **Readout Ridge Regression**: Solves $(S^T S + \alpha I) W_{out} = S^T Y$ using Gaussian elimination.

---

## 3. Verification & Definition of Done
1. Create Target 49: `test/compiler_suite/test_inductive_biases.car` validating WANN DAG topology, DIP denoising convergence, ELM zero-shot analytical fit, and ESN reservoir dynamics.
2. Build candidate compiler and run all 49 regression tests with 100% pass rate.
3. Update `ISSUES.md`, `CHANGELOG.md`, archive sprint retro, and commit to `master`.
