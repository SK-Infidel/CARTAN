# Sprint 545 Plan: CARTAN Unified Algebraic Taxonomy (Pillar 2: Geometric, Clifford, Weyl & Hypercomplex Algebras)

## 1. Sprint Objective
Implement Pillar 2 of the CARTAN Unified Algebraic Taxonomy in [`src/std/algebra/geometric.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/algebra/geometric.cl) and integrate it into umbrella module [`src/std/algebra.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/algebra.cl). Provide generalized Clifford algebras $Cl(p, q, r)$, Cayley-Dickson hypercomplex structures (complex, dual numbers, split-complex, quaternions, octonions), and the polynomial-differential Weyl algebra $W_n$ with Canonical Commutation Relations, verified by Target 92 with 100% empirical pass.

---

## 2. Technical Architecture & Scope

### 2.1 Generalized Clifford Algebra $Cl(p, q, r)$
- **Structure**: `AlgMultivector` with signature $(p, q, r)$, dimension $n = p + q + r$, total basis blades $2^n$, and double precision coefficient array `coeffs: ptr`.
- **Bitmask Blade Representation**: Blade index $b \in [0, 2^n - 1]$, where bit $k$ denotes basis vector $e_{k+1}$.
  - Grade computation: bitwise population count (popcount).
  - Metric signature evaluation: $e_k^2 = +1$ ($k < p$), $e_k^2 = -1$ ($p \le k < p + q$), $e_k^2 = 0$ ($k \ge p + q$).
  - Canonical blade product with anti-commutation parity swaps $(-1)^{\sum_{i < j} a_j b_i}$.
- **Multivector Algebra**:
  - `alg_mv_create(p, q, r)`: Allocates multivector with initialized zero coefficients.
  - `alg_mv_clone(mv)`: Deep buffer clone.
  - `alg_mv_free(mv)`: Deallocates multivector buffer.
  - `alg_mv_get_blade(mv, mask)` / `alg_mv_set_blade(mv, mask, val)`: Direct blade coefficient access.
  - `alg_mv_grade_project(mv, grade)`: Extracts component multivector of exact grade $k$.
  - `alg_mv_scalar(mv)`: Returns grade-0 scalar part.
  - `alg_mv_add(a, b)`, `alg_mv_sub(a, b)`, `alg_mv_scale(a, s)`.
  - `alg_mv_mul(a, b)`: Geometric product $A B$ under signature $(p, q, r)$.
  - `alg_mv_wedge(a, b)`: Grassmann exterior / wedge product $A \wedge B$.
  - `alg_mv_left_contract(a, b)`: Left contraction $A \rfloor B$.
  - `alg_mv_reverse(mv)`: Reversion $\tilde{A}$ with grade factor $(-1)^{k(k-1)/2}$.
  - `alg_mv_involute(mv)`: Grade involution with factor $(-1)^k$.
  - `alg_mv_rotor_3d(angle, b12, b23, b31)`: Generates rotor $R = \cos(\theta/2) - B \sin(\theta/2)$.
  - `alg_mv_sandwich(r, v)`: Rotor sandwich transformation $v' = R v \tilde{R}$.

### 2.2 Cayley-Dickson Hypercomplex Systems
- **Complex Numbers $\mathbb{C}$ (`AlgComplex`)**:
  - Representation: $\{ \text{re}, \text{im} \}$.
  - Arithmetic: addition, multiplication ($(a+bi)(c+di) = (ac-bd) + (ad+bc)i$), conjugate, norm $|z|$, inverse $z^{-1}$, polar form.
- **Dual Numbers $\mathbb{D}$ (`AlgDual`)**:
  - Representation: $\{ \text{val}, \text{eps} \}$ with $\epsilon^2 = 0$.
  - Exact automatic differentiation: $f(x + \epsilon) = f(x) + f'(x)\epsilon$.
  - Elementary dual functions: `alg_dual_mul`, `alg_dual_div`, `alg_dual_sin`, `alg_dual_cos`, `alg_dual_exp`, `alg_dual_sqrt`.
- **Split-Complex Numbers $\mathbb{H}_{\text{split}}$ (`AlgSplit`)**:
  - Representation: $\{ \text{re}, \text{j} \}$ with $j^2 = +1$.
  - Spacetime hyperbolic interval: $x^2 - t^2$.
- **Quaternions $\mathbb{H}$ (`AlgQuat`)**:
  - Representation: $\{ w, x, y, z \}$.
  - Arithmetic: Hamilton product, conjugate, norm, inverse, normalization, slerp interpolation.
- **Octonions $\mathbb{O}$ (`AlgOctonion`)**:
  - Representation: $\{ e_0, e_1, e_2, e_3, e_4, e_5, e_6, e_7 \}$ (8D Cayley-Dickson division algebra).
  - Arithmetic: Fano plane multiplication, conjugation, norm, inverse.
  - Associator: `alg_octonion_associator(a, b, c) = (ab)c - a(bc)`.
  - Verification of non-associativity ($[e_1, e_2, e_4] \ne 0$) and alternativity ($[a, a, b] = 0$).

### 2.3 Polynomial-Differential Weyl Algebra $W_n$
- **Theoretical Basis**: Bosonic canonical dual to Clifford algebra's fermionic CAR.
  - CCR: $[\partial_i, x_j] = \partial_i x_j - x_j \partial_i = \delta_{ij}$.
- **Representation**: Struct `AlgWeylOp` holding array of monomials in normal order $\sum c_{\alpha,\beta} x^\alpha \partial^\beta$.
- **Monomial Product via Leibniz Rule**:
  - $\partial^k x^m = \sum_{r=0}^{\min(k, m)} \binom{k}{r} \frac{m!}{(m-r)!} x^{m-r} \partial^{k-r}$.
- **Operations**:
  - `alg_weyl_create(max_terms)`, `alg_weyl_add_term(op, coeff, alpha, beta)`, `alg_weyl_free(op)`.
  - `alg_weyl_mul(p, q)`: Product of differential operators in normal order.
  - `alg_weyl_commutator(p, q)`: Lie bracket $[P, Q] = PQ - QP$.
  - `alg_weyl_eval_poly(op, poly_coeffs, poly_deg)`: Real differential action on polynomial $P(x, \partial) f(x)$.

---

## 3. Test Plan: Target 92 (`Projects/geomind/Testing-scratch/test_stdlib_algebra_geometric.car`)
- **Gate 1: Clifford Algebra $Cl(p, q, r)$ Primitives & Products**:
  - Euclidean $Cl(3, 0, 0)$: basis vector squares $e_i^2 = +1$, anti-commutation $e_1 e_2 = -e_2 e_1$.
  - Spacetime $Cl(1, 3, 0)$: timelike $e_0^2 = +1$, spacelike $e_i^2 = -1$.
  - Projective null $Cl(3, 0, 1)$: degenerate $e_0^2 = 0$.
  - Wedge product $e_1 \wedge e_2 = e_{12}$, $e_1 \wedge e_1 = 0$.
  - Left contraction $e_1 \rfloor e_{12} = e_2$.
  - Grade projections and reversion.
- **Gate 2: Rotor & Spinor Sandwich Transformations**:
  - Rotor generation $R = \cos(\pi/4) - e_{12} \sin(\pi/4)$ (90-degree rotation in xy-plane).
  - Transformation $v' = R e_1 \tilde{R} = e_2$.
- **Gate 3: Cayley-Dickson Hypercomplex Systems & Octonion Associators**:
  - Complex arithmetic, conjugate, inverse, modulus.
  - Dual number automatic differentiation: derivative of $f(x) = x^2 + 3x$ at $x = 2$ yields $f'(2) = 7.0$.
  - Split-complex hyperbolic interval.
  - Quaternion Hamilton product and conjugate.
  - Octonion non-associativity: non-zero associator $[e_1, e_2, e_4] \ne 0$, and alternativity $[e_1, e_1, e_2] = 0$.
- **Gate 4: Weyl Algebra Canonical Commutation Relations & Differential Action**:
  - CCR verification: $[\partial, x] = 1$.
  - Product of $\partial$ and $x^2$: $\partial x^2 = x^2 \partial + 2x$.
  - Action on polynomial: $D(x^3) = 3x^2$.
  - Quantum harmonic oscillator commutator $[a, a^\dagger] = 1$.

---

## 4. Definition of Done (DoD)
- [ ] `src/std/algebra/geometric.cl` implemented and integrated into `src/std/algebra.cl`.
- [ ] Target 92 compiles cleanly and passes all test gates (100% assertions PASS).
- [ ] `tools/run_affected_tests.ps1 -Sprint 545` passes 100% targets with zero regressions.
- [ ] `ISSUES.md` updated: `[ISSUE-403]` resolved.
- [ ] `CHANGELOG.md` updated with release entry.
- [ ] `docs/ROADMAP.md` updated with Item 27 under Phase 25.
- [ ] Walkthrough artifact saved to `docs/archive/sprint_545_walkthrough.md`.
