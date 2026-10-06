# Sprint 546 Plan: CARTAN Unified Algebraic Taxonomy (Pillar 3: Lie Algebras, Pre-Lie Systems, Lie Superalgebras & Poisson Brackets)

## 1. Sprint Objective
Implement Pillar 3 of the CARTAN Unified Algebraic Taxonomy in [`src/std/algebra/lie.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/algebra/lie.cl) and integrate it into umbrella module [`src/std/algebra.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/algebra.cl). Provide abstract and matrix Lie algebras with structure constants, Jacobi identity verification, adjoint representations, Killing forms, Cartan semisimplicity criteria, Baker-Campbell-Hausdorff (BCH) series expansions, pre-Lie left-symmetric systems, graded Lie superalgebras, and classical phase-space Poisson brackets, empirically verified by Target 93 with 100% assertions PASS.

---

## 2. Technical Architecture & Scope

### 2.1 Finite-Dimensional Lie Algebras (`AlgLieAlgebra`)
- **Structure**:
  ```cartan
  struct AlgLieAlgebra {
      dim: float;        // Dimension d
      constants: ptr;    // d x d x d doubles: c(i, j, k) where [e_i, e_j] = sum c(i,j,k) e_k
  }
  ```
- **Operations**:
  - `alg_lie_create(dim)`: Allocates structure constant tensor initialized to zero.
  - `alg_lie_free(lie)`: Frees memory buffer.
  - `alg_lie_set_structure(lie, i, j, k, val)`: Sets $c_{ij}^k$ enforcing anti-symmetry $c_{ji}^k = -val$.
  - `alg_lie_get_structure(lie, i, j, k)`: Gets $c_{ij}^k$.
  - `alg_lie_bracket(lie, v1, v2)`: Evaluates vector Lie bracket $[V_1, V_2]^k = \sum_{i, j} V_1^i V_2^j c_{ij}^k$.
  - `alg_lie_jacobi_check(lie, tol)`: Thoroughly validates the Jacobi identity for all basis triples $(i, j, k)$:
    $$[e_i, [e_j, e_k]] + [e_j, [e_k, e_i]] + [e_k, [e_i, e_j]] = 0$$
    Returns $1.0$ if Jacobi holds within tolerance $\text{tol}$, $0.0$ otherwise.
  - `alg_lie_adjoint_matrix(lie, v)`: Constructs the $d \times d$ adjoint matrix $(\text{ad}_V)_{kj} = \sum_i V^i c_{ij}^k$.
  - `alg_lie_killing_matrix(lie)`: Computes the $d \times d$ Killing metric matrix $K_{ij} = \text{Tr}(\text{ad}_{e_i} \circ \text{ad}_{e_j})$.
  - `alg_lie_killing_form(lie, v1, v2)`: Evaluates scalar $B(V_1, V_2) = V_1^T K V_2$.
  - `alg_lie_is_semisimple(lie)`: Evaluates Cartan's semisimplicity criterion: computes $\det(K)$ via LU decomposition from Pillar 1; returns $1.0 \iff |\det(K)| > 10^{-6}$.

### 2.2 Classical Matrix Lie Algebras & BCH Series
- **Matrix Commutator**: `alg_lie_mat_commutator(a, b) = A B - B A$ using `alg_mat_mul` and `alg_mat_sub`.
- **Classical Algebras**:
  - $\mathfrak{so}(3)$: 3D rotation Lie algebra generators $J_x, J_y, J_z$.
  - $\mathfrak{sp}(2n)$: Hamiltonian symplectic condition $M^T J + J M = 0$ using symplectic matrix $J$ from Pillar 1.
- **Baker-Campbell-Hausdorff (BCH) Formula**:
  - `alg_lie_bch_order2(x, y)`: Evaluates the series expansion $Z = X + Y + \frac{1}{2}[X, Y] + \frac{1}{12}([X, [X, Y]] + [Y, [Y, X]])$ with intermediate matrix cleanup.

### 2.3 Pre-Lie (Vinberg) Left-Symmetric Algebras
- **Definition**: Non-associative algebra $(V, \cdot)$ with left-symmetric associator:
  $$(x, y, z) - (y, x, z) = 0 \iff (x \cdot y) \cdot z - x \cdot (y \cdot z) = (y \cdot x) \cdot z - y \cdot (x \cdot z)$$
- **Structure**: `AlgPreLie` with 3D product tensor $T_{ij}^k$ representing $e_i \cdot e_j = \sum_k T_{ij}^k e_k$.
- **Operations**:
  - `alg_prelie_create(dim)`, `alg_prelie_free`, `alg_prelie_mul(pl, u, v)`.
  - `alg_prelie_associator(pl, x, y, z) = (x . y) . z - x . (y . z)`.
  - `alg_prelie_verify_identity(pl, tol)`: Validates that $(x, y, z) = (y, x, z)$ for all basis triples.
  - `alg_prelie_induced_bracket(pl, x, y) = x . y - y . x`: Computes the induced Lie bracket, proving the Fundamental Theorem of Pre-Lie Algebras.

### 2.4 Graded Lie Superalgebras & Poisson Phase Space
- **Lie Superalgebra (`AlgLieSuper`)**:
  - Direct sum $\mathfrak{g} = \mathfrak{g}_0 \oplus \mathfrak{g}_1$ with bosonic dimension $d_0$ and fermionic dimension $d_1$.
  - Graded bracket $[a, b] = -(-1)^{|a||b|} [b, a]$.
  - Super-Jacobi identity: $(-1)^{|a||c|} [a, [b, c]] + \text{cyc} = 0$.
  - Validates fermionic anticommutation $\{f_1, f_2\} \in \mathfrak{g}_0$.
- **Poisson Phase Space Algebra (`AlgPoisson`)**:
  - Classical canonical symplectic bracket on $(q_1, \dots, q_n, p_1, \dots, p_n)$:
    $$\{f, g\} = \sum_k \left( \frac{\partial f}{\partial q_k} \frac{\partial g}{\partial p_k} - \frac{\partial f}{\partial p_k} \frac{\partial g}{\partial q_k} \right)$$
  - Verifies canonical commutation relations $\{q_i, p_j\} = \delta_{ij}, \{q_i, q_j\} = 0, \{p_i, p_j\} = 0$.
  - Validates Leibniz derivation identity: $\{f, g \cdot h\} = \{f, g\} \cdot h + g \cdot \{f, h\}$.

---

## 3. Test Plan: Target 93 (`Projects/geomind/Testing-scratch/test_stdlib_algebra_lie.car`)
- **Gate 1: Finite-Dimensional Lie Algebras, Structure Constants, Jacobi & Killing Form**:
  - Instantiate $\mathfrak{so}(3)$ via structure constants: $c_{12}^3 = 1, c_{23}^1 = 1, c_{31}^2 = 1$.
  - Verify anti-symmetry: $c_{21}^3 = -1$.
  - Verify Jacobi identity across all 27 basis triples (100% PASS).
  - Compute adjoint matrices $\text{ad}_{e_1}, \text{ad}_{e_2}, \text{ad}_{e_3}$.
  - Compute Killing metric matrix: $K = -2 I_3$.
  - Verify Cartan's semisimplicity criterion: $\det(K) = (-2)^3 = -8 \ne 0 \implies \mathfrak{so}(3)$ is semisimple!
- **Gate 2: Classical Matrix Lie Algebras & BCH Formula**:
  - Construct matrix generators of $\mathfrak{so}(3)$: $J_x, J_y, J_z$.
  - Assert $[J_x, J_y] = J_z, [J_y, J_z] = J_x, [J_z, J_x] = J_y$.
  - Symplectic Lie algebra condition: verify $M^T J + J M = 0$.
  - Evaluate order-2 BCH series for commuting matrices $X, Y$ ($[X, Y] = 0 \implies Z = X + Y$) and non-commuting matrices.
- **Gate 3: Pre-Lie (Vinberg) Left-Symmetric Algebras**:
  - Construct pre-Lie structure and evaluate associator $(x, y, z)$.
  - Verify left-symmetric identity $(x, y, z) - (y, x, z) = 0$.
  - Verify that induced commutator $[x, y] = x \cdot y - y \cdot x$ satisfies the Jacobi identity.
- **Gate 4: Graded Lie Superalgebras & Poisson Phase Space**:
  - Construct Lie superalgebra $\mathfrak{osp}(1|2)$ or 2D superalgebra with bosonic $b$ and fermionic $f$.
  - Verify fermionic anticommutation: $[f, f] = 2 f^2 = b \in \mathfrak{g}_0$.
  - Verify super-Jacobi identity.
  - Phase space Poisson bracket: $\{q, p\} = 1.0, \{q, q\} = 0.0$.
  - Verify Leibniz derivation: $\{q, p^2\} = 2p$.

---

## 4. Definition of Done (DoD)
- [ ] `src/std/algebra/lie.cl` implemented and integrated into `src/std/algebra.cl`.
- [ ] Target 93 compiles cleanly and passes all 4 test gates (100% assertions PASS).
- [ ] `tools/run_affected_tests.ps1 -Sprint 546` passes 100% targets with zero regressions.
- [ ] `ISSUES.md` updated: `[ISSUE-404]` resolved.
- [ ] `CHANGELOG.md` updated with release entry `[8.502.0]`.
- [ ] `docs/ROADMAP.md` updated with Item 28 under Phase 25.
- [ ] Walkthrough artifact saved to `docs/archive/sprint_546_walkthrough.md`.
