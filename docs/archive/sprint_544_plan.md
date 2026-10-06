# Sprint 544 Plan: Foundation of the CARTAN Algebraic Engine (Pillar 1: Multilinear Tensor Algebra & Structural Framework)

## Objective
Establish the directory hierarchy `src/std/algebra/` and umbrella module `src/std/algebra.cl`, then implement Pillar 1: Multilinear Tensor Algebra (`src/std/algebra/tensor.cl`). The module delivers production-grade N-dimensional tensors, multilinear contractions (Einsum), full matrix algebra ($GL(n), SO(n), Sp(n)$, LU determinants, matrix inverses, Householder QR, Jacobi symmetric eigensystems, Padé matrix exponentials), symmetric algebra $S(V)$, and quadratic forms with Sylvester metric signatures $(p, q, r)$—with zero mocking and zero stubs.

---

## Architecture & Interfaces

### 1. Structure Definitions (`src/std/algebra/tensor.cl`)
- `struct AlgTensor`: `ndim: float`, `shape: ptr`, `strides: ptr`, `total_elements: float`, `data: ptr`.
- `struct AlgMat`: `rows: float`, `cols: float`, `data: ptr`.

### 2. Functional Modules
- **Core Tensor Ops**:
  - `alg_tensor_create(shape: ptr, ndim: float) -> ptr`
  - `alg_tensor_zeros(shape: ptr, ndim: float) -> ptr`
  - `alg_tensor_ones(shape: ptr, ndim: float) -> ptr`
  - `alg_tensor_free(t: ptr)`
  - `alg_tensor_get(t: ptr, indices: ptr) -> float`
  - `alg_tensor_set(t: ptr, indices: ptr, val: float)`
  - `alg_tensor_clone(t: ptr) -> ptr`
  - `alg_tensor_reshape(t: ptr, new_shape: ptr, new_ndim: float) -> ptr`
  - `alg_tensor_slice(t: ptr, axis: float, start: float, end_idx: float) -> ptr`
- **Multilinear Contraction & Einsum**:
  - `alg_tensor_outer_product(A: ptr, B: ptr) -> ptr`
  - `alg_tensor_contract(t: ptr, axis1: float, axis2: float) -> ptr`
  - `alg_tensor_einsum_dot(A: ptr, axisA: float, B: ptr, axisB: float) -> ptr`
- **Matrix Algebra $\mathcal{M}_{m \times n}$**:
  - `alg_mat_create(rows: float, cols: float) -> ptr`
  - `alg_mat_identity(n: float) -> ptr`
  - `alg_mat_free(m: ptr)`
  - `alg_mat_get(m: ptr, r: float, c: float) -> float`
  - `alg_mat_set(m: ptr, r: float, c: float, val: float)`
  - `alg_mat_mul(A: ptr, B: ptr) -> ptr`
  - `alg_mat_transpose(m: ptr) -> ptr`
  - `alg_mat_trace(m: ptr) -> float`
  - `alg_mat_determinant(m: ptr) -> float` (LU decomposition with partial pivoting)
  - `alg_mat_inverse(m: ptr) -> ptr` (Gauss-Jordan with partial pivoting)
  - `alg_mat_qr(A: ptr, out_Q: ptr, out_R: ptr)` (Householder reflections)
  - `alg_mat_symmetric_eigenvalues(A: ptr, out_evals: ptr, out_evecs: ptr)` (Jacobi rotation method)
  - `alg_mat_exp(A: ptr, terms: float) -> ptr` (Scaling and squaring with Padé/Taylor series)
- **Symmetric Algebra & Quadratic Forms**:
  - `alg_mat_symmetrize(A: ptr) -> ptr`
  - `alg_quadratic_form(A: ptr, v: ptr) -> float` ($v^T A v$)
  - `alg_bilinear_form(A: ptr, u: ptr, v: ptr) -> float` ($u^T A v$)
  - `alg_sylvester_signature(A: ptr, out_sig: ptr)` (computes positive $p$, negative $q$, null $r$ dimensions)
  - `alg_symplectic_matrix(n: float) -> ptr` (constructs canonical $2n \times 2n$ symplectic form $J$)

### 3. Umbrella Integration (`src/std/algebra.cl`)
- Re-exports `src/std/algebra/tensor.cl` (and subsequent pillars as they come online).

### 4. Regression Target 91 (`Projects/geomind/Testing-scratch/test_stdlib_algebra_tensor.car`)
- Gate 1: N-Dimensional Tensor creation, indexing, reshaping, and slicing.
- Gate 2: Multilinear contractions and outer products.
- Gate 3: Matrix algebra (Matmul, LU Determinant, Matrix Inversion, QR decomposition, Jacobi Eigensystem, Matrix Exponential).
- Gate 4: Quadratic & Bilinear forms, Sylvester metric signature $(p, q, r)$, and Symplectic matrix $J$.
