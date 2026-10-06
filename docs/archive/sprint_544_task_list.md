# Sprint 544 Task List: Foundation of the CARTAN Algebraic Engine (Pillar 1: Multilinear Tensor Algebra & Structural Framework)

- [x] Task 1: Create directory `src/std/algebra/` and umbrella module `src/std/algebra.cl`.
- [x] Task 2: Implement N-dimensional tensor layout, creation, strided access, reshape, and slice in `src/std/algebra/tensor.cl`.
- [x] Task 3: Implement multilinear tensor operations: outer products, index contractions, and general einsum in `src/std/algebra/tensor.cl`.
- [x] Task 4: Implement Matrix Algebra: `alg_mat_*` (mul, transpose, trace, LU determinant with pivoting, inverse with Gauss-Jordan).
- [x] Task 5: Implement advanced Matrix Factorizations: Householder QR, Jacobi symmetric eigensystem, and Padé matrix exponential.
- [x] Task 6: Implement Symmetric Algebra & Quadratic Forms: quadratic forms $v^T A v$, bilinear forms $u^T A v$, Sylvester metric signature $(p, q, r)$, and canonical symplectic form $J$.
- [x] Task 7: Author Target 91 regression suite `Projects/geomind/Testing-scratch/test_stdlib_algebra_tensor.car` covering all 4 gates.
- [x] Task 8: Register Target 91 and Preset 544 in `tools/run_affected_tests.ps1`.
- [x] Task 9: Compile and execute Target 91, verifying 100% assertions PASS.
- [x] Task 10: Run the full affected regression runner (`tools/run_affected_tests.ps1 -Sprint 544`).
- [x] Task 11: Register `[ISSUE-402]` in `ISSUES.md`.
- [x] Task 12: Update `CHANGELOG.md` ([`8.500.0`]) and append item 26 to Phase 25 in `docs/ROADMAP.md`.
- [x] Task 13: Author and save Walkthrough artifact to `docs/archive/sprint_544_walkthrough.md`.
