# Sprint 546 Task List: CARTAN Unified Algebraic Taxonomy (Pillar 3: Lie Algebras, Pre-Lie Systems, Lie Superalgebras & Poisson Brackets)

- [x] Task 1: Create `src/std/algebra/lie.cl` implementing finite-dimensional Lie algebra `AlgLieAlgebra`, structure constants $c_{ij}^k$, bracket $[X, Y]$, and anti-symmetry enforcement.
- [x] Task 2: Implement Lie algebra analysis tools: Jacobi identity checker, adjoint matrix representation $\text{ad}_X$, Killing metric matrix $K_{ij} = \text{Tr}(\text{ad}_{e_i} \text{ad}_{e_j})$, and Cartan semisimplicity criterion.
- [x] Task 3: Implement classical matrix Lie algebra operations: matrix commutator $[A, B] = AB - BA$, $\mathfrak{so}(3)$ generator algebra, symplectic $\mathfrak{sp}(2n)$ Hamiltonian condition, and order-2 Baker-Campbell-Hausdorff (BCH) expansion.
- [x] Task 4: Implement Pre-Lie (Vinberg) left-symmetric algebras `AlgPreLie`, associator $(x, y, z)$, left-symmetry verification, and induced Lie commutator bracket.
- [x] Task 5: Implement Graded Lie Superalgebra `AlgLieSuper`, parity-graded bracket $[a, b] = -(-1)^{|a||b|} [b, a]$, and super-Jacobi identity checker.
- [x] Task 6: Implement Classical Poisson Phase Space Algebra `AlgPoisson`, canonical symplectic bracket $\{f, g\}$, and Leibniz derivation verification.
- [x] Task 7: Re-export `src/std/algebra/lie.cl` in `src/std/algebra.cl`.
- [x] Task 8: Author Target 93 regression suite `Projects/geomind/Testing-scratch/test_stdlib_algebra_lie.car` covering all 4 gates.
- [x] Task 9: Register Target 93 and Preset 546 in `tools/run_affected_tests.ps1`.
- [x] Task 10: Compile and execute Target 93, verifying 100% assertions PASS.
- [x] Task 11: Run full affected regression runner (`tools/run_affected_tests.ps1 -Sprint 546`).
- [x] Task 12: Resolve `[ISSUE-404]` in `ISSUES.md`.
- [x] Task 13: Update `CHANGELOG.md` ([`8.502.0`]) and append Item 28 to Phase 25 in `docs/ROADMAP.md`.
- [x] Task 14: Author and save Walkthrough artifact to `docs/archive/sprint_546_walkthrough.md`.
