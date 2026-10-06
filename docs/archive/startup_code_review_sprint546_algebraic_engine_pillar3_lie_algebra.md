# Startup Code Review: Sprint 546 — CARTAN Unified Algebraic Taxonomy (Pillar 3: Lie Algebras, Pre-Lie Systems, Lie Superalgebras & Poisson Brackets)

## 1. Executive Summary & Purpose
In accordance with Rule `[user_global]`, a comprehensive startup code review was conducted prior to beginning Sprint 546. Sprint 546 advances the CARTAN unified standard algebraic taxonomy into **Pillar 3: Lie Algebras, Pre-Lie Systems, Lie Superalgebras & Poisson Brackets** (`src/std/algebra/lie.cl`), building directly upon Pillar 1 multilinear tensors/matrices (`src/std/algebra/tensor.cl`) and Pillar 2 geometric/Clifford/Weyl algebras (`src/std/algebra/geometric.cl`).

This review evaluates:
1. Codebase health and clean commit baseline (`3854eff`).
2. The logical dependency tree across compiler, stdlib, and algebra modules.
3. Open technical debt and issue registration (`[ISSUE-404]`).
4. Read-ahead mathematical and architectural considerations for structure constants $c_{ij}^k$, adjoint matrix representations, Killing forms, Cartan semisimplicity criteria, Baker-Campbell-Hausdorff (BCH) series expansions, pre-Lie left-symmetric associators, graded Lie superbrackets, and canonical phase space Poisson brackets.

---

## 2. Logical Dependency Tree

```
CARTAN Language Core (cartanc.exe)
  │
  ├── src/std/constants.ch & src/std/math.cl
  │     │
  │     ├── src/std/algebra/tensor.cl [Pillar 1: Multilinear Tensor & Matrix Engine]
  │     │     │
  │     │     ├── src/std/algebra/geometric.cl [Pillar 2: Clifford, Weyl & Hypercomplex]
  │     │     │
  │     │     └── src/std/algebra/lie.cl [Pillar 3: Lie, Pre-Lie, Superalgebra & Poisson] (Sprint 546)
  │     │           ├── Structure Constants & Adjoint Matrices (ad_X)_kj = c_{ij}^k
  │     │           ├── Jacobi Identity Checker: [[X,Y],Z] + [[Y,Z],X] + [[Z,X],Y] = 0
  │     │           ├── Killing Metric Form B(X, Y) = Tr(ad_X ad_Y) & Cartan Semisimplicity (det(K) != 0)
  │     │           ├── Classical Matrix Lie Algebras: so(3) rotation generators & BCH Series
  │     │           ├── Pre-Lie (Vinberg) Left-Symmetric Algebras (x, y, z) = (y, x, z)
  │     │           ├── Graded Lie Superalgebras: [a, b] = -(-1)^{|a||b|} [b, a] & Super-Jacobi
  │     │           └── Classical Poisson Phase Space Algebra: {f, g} & Hamilton Derivations
  │     │
  │     └── [Direct Consumer]: src/std/algebra.cl (Umbrella Entrypoint: Pillars 1, 2, 3)
  │
  └── Projects/geomind/Testing-scratch/
        ├── Target 91: test_stdlib_algebra_tensor.car (35/35 PASS)
        ├── Target 92: test_stdlib_algebra_geometric.car (43/43 PASS)
        └── Target 93: test_stdlib_algebra_lie.car (Sprint 546 Target)
```

---

## 3. Findings & Mathematical Structure Analysis

### 3.1 Verification of Existing Baseline
- Commits `3adf628` (Sprint 544) and `3854eff` (Sprint 545) are clean.
- `tools/run_affected_tests.ps1` runs 14 targets in 23s with 100% pass rate.
- Matrix routines in `src/std/algebra/tensor.cl` (`alg_mat_mul`, `alg_mat_trace`, `alg_mat_det`) are directly consumable by `src/std/algebra/lie.cl`.

### 3.2 Analysis of Lie Theory & Continuous Symmetry Primitives
1. **Finite-Dimensional Lie Algebra (`AlgLieAlgebra`)**:
   - Dimension $d$.
   - Structure constants tensor $C$ of size $d \times d \times d$, where $[e_i, e_j] = \sum_k c_{ij}^k e_k$.
   - Skew-symmetry: $c_{ij}^k = -c_{ji}^k$.
   - Adjoint matrix $\text{ad}_{e_i}$ is a $d \times d$ matrix with entry $(k, j)$ equal to $c_{ij}^k$.
   - Killing metric matrix $K_{ij} = \text{Tr}(\text{ad}_{e_i} \text{ad}_{e_j})$.
   - Cartan Semisimplicity Criterion: $\mathfrak{g}$ is semisimple $\iff \det(K) \ne 0$. For compact semisimple Lie algebras like $\mathfrak{so}(3)$, the Killing form is negative definite ($K_{ij} = -2 \delta_{ij}$).
2. **Classical Matrix Lie Algebras & BCH Formula**:
   - $\mathfrak{so}(3)$: 3D rotation Lie algebra spanned by skew-symmetric $3 \times 3$ matrices:
     $$J_x = \begin{pmatrix} 0 & 0 & 0 \\ 0 & 0 & -1 \\ 0 & 1 & 0 \end{pmatrix}, \quad J_y = \begin{pmatrix} 0 & 0 & 1 \\ 0 & 0 & 0 \\ -1 & 0 & 0 \end{pmatrix}, \quad J_z = \begin{pmatrix} 0 & -1 & 0 \\ 1 & 0 & 0 \\ 0 & 0 & 0 \end{pmatrix}$$
     Commutation relations: $[J_x, J_y] = J_z, [J_y, J_z] = J_x, [J_z, J_x] = J_y$.
   - Matrix commutator bracket: $[A, B] = A B - B A$.
   - Baker-Campbell-Hausdorff (BCH) order-2 truncation: $Z = X + Y + \frac{1}{2}[X, Y] + \frac{1}{12}([X, [X, Y]] + [Y, [Y, X]])$.
3. **Pre-Lie (Vinberg) Left-Symmetric Algebras**:
   - Vector space with bilinear product $x \cdot y$.
   - Associator $(x, y, z) = (x \cdot y) \cdot z - x \cdot (y \cdot z)$.
   - Left-symmetry identity: $(x, y, z) - (y, x, z) = 0$.
   - Induced Lie bracket $[x, y] = x \cdot y - y \cdot x$ automatically satisfies the Jacobi identity!
4. **Graded Lie Superalgebras**:
   - Graded vector space $\mathfrak{g} = \mathfrak{g}_0 \oplus \mathfrak{g}_1$ with parity degree $|a| \in \{0, 1\}$.
   - Graded bracket $[a, b] = -(-1)^{|a||b|} [b, a]$.
   - Boson-boson: $[a_0, b_0] = -[b_0, a_0] \in \mathfrak{g}_0$.
   - Boson-fermion: $[a_0, b_1] = -[b_1, a_0] \in \mathfrak{g}_1$.
   - Fermion-fermion: $[a_1, b_1] = +[b_1, a_1] = \{a_1, b_1\} \in \mathfrak{g}_0$.
5. **Poisson Phase Space Algebra**:
   - Symplectic manifold phase space $(q_1, \dots, q_n, p_1, \dots, p_n)$.
   - Bracket: $\{f, g\} = \sum_k \left( \frac{\partial f}{\partial q_k} \frac{\partial g}{\partial p_k} - \frac{\partial f}{\partial p_k} \frac{\partial g}{\partial q_k} \right)$.
   - Canonical relations: $\{q_i, p_j\} = \delta_{ij}, \{q_i, q_j\} = 0, \{p_i, p_j\} = 0$.
   - Leibniz derivation rule: $\{f, g \cdot h\} = \{f, g\} \cdot h + g \cdot \{f, h\}$.

---

## 4. Identified Technical Debt & Compiler Guardrails
- `src/std/algebra.cl` line 12 has a commented-out include for `lie.cl`. It will be uncommented during this sprint.
- Strict adherence to compiler rules:
  - Avoid mutable struct variable reassignment inside loops.
  - Provide typed struct property accessors (`alg_lie_*`, `alg_mat_*`).
  - Strict Zero-Mock rule: all Killing metrics, commutators, Jacobi sums, and Poisson brackets must be computed via real arithmetic.
