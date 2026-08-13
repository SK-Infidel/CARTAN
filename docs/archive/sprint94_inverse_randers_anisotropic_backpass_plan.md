# Sprint 94 Implementation Plan: Inverse Randers Anisotropic Backward Pass Engine

## 1. Core Objective
- **Objective**: Implement Dual Inverse Randers Metric ($F^*(x, y) = \alpha(x, y) - \beta(x, y)$) in `test/geomind/geometry.car` and `test/geomind/sft_train.car`.
- **Mathematical Rationale**: Because an FRS (Finsler-Randers-Sasaki) manifold is anisotropic ($F(x, y) \neq F(x, -y)$), backpropagating gradients against the forward action drift vector $\mathbf{b}_{\text{drift}}$ requires applying the Dual Inverse Randers Metric $F^*(x, \nabla \mathcal{L}) = \sqrt{a^{ij} \partial_i \mathcal{L} \partial_j \mathcal{L}} - b^i \partial_i \mathcal{L}$ to ensure least-cost action updates during fine-tuning.

---

## 2. Implementation Steps
1. **`test/geomind/geometry.car`**:
   - Implement `geomind_inverse_randers_backward_project(metric, x, y)` evaluating dual metric $F^*(x, y) = \alpha - \beta \cdot \lambda$.
2. **`test/geomind/sft_train.car`**:
   - Integrate Dual Inverse Randers Metric into the SFT backpropagation update loop.
3. **Rebuild & Verification**:
   - Rebuild `geomind.exe` with `cartanc.exe` and run `geomind.exe --train-sft`.
4. **Documentation**:
   - Log Sprint 94 in `CHANGELOG.md` and update `docs/ROADMAP.md`.
