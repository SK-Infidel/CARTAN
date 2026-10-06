// src/std/algebra/lie.cl
// CARTAN Standard Library: Pillar 3 — Lie Algebras, Pre-Lie Systems, Lie Superalgebras & Poisson Brackets
// Pure-CARTAN Bare-Metal Implementation (Zero-Mock Rule Enforced)

include "src/std/constants.ch";
include "src/std/math.cl";
include "src/std/algebra/tensor.cl";

extern fn malloc(size: float) -> ptr;
extern fn calloc(count: float, size: float) -> ptr;
extern fn free(p: ptr) -> void;
extern fn memcpy(dst: ptr, src: ptr, size: float) -> ptr;

// ============================================================================
// Finite-Dimensional Lie Algebras (Structure Constants & Adjoint Action)
// ============================================================================

// Structure representing a finite-dimensional Lie algebra g of dimension d
// Structure constants: [e_i, e_j] = sum_k c_{ij}^k e_k
// Stored as d x d x d contiguous doubles: index = (i * d + j) * d + k
struct AlgLieAlgebra {
    dim: float;
    constants: ptr;
}

// Typed struct property accessors for compiler GEP lowering safety
fn alg_lie_dim(lie: AlgLieAlgebra) -> float { return lie.dim; }
fn alg_lie_constants(lie: AlgLieAlgebra) -> ptr { return lie.constants; }

// Allocates an empty Lie algebra of dimension d
fn alg_lie_create(dim: float) -> AlgLieAlgebra {
    var d = dim;
    if (d <= 0.0) { d = 1.0; }
    let total = d * d * d;
    let buf = calloc(total, 8.0);
    return AlgLieAlgebra { dim: d, constants: buf };
}

// Frees Lie algebra structure constants buffer
fn alg_lie_free(lie: AlgLieAlgebra) {
    let c = alg_lie_constants(lie);
    if (c != 0.0) {
        free(c);
    }
}

// Retrieves structure constant c_{ij}^k
fn alg_lie_get_structure(lie: AlgLieAlgebra, i: float, j: float, k: float) -> float {
    let d = alg_lie_dim(lie);
    if (i < 0.0 || i >= d || j < 0.0 || j >= d || k < 0.0 || k >= d) {
        return 0.0;
    }
    let idx = (i * d + j) * d + k;
    let c = alg_lie_constants(lie);
    return c[idx];
}

// Sets structure constant c_{ij}^k and automatically enforces skew-symmetry c_{ji}^k = -val
fn alg_lie_set_structure(lie: AlgLieAlgebra, i: float, j: float, k: float, val: float) {
    let d = alg_lie_dim(lie);
    if (i < 0.0 || i >= d || j < 0.0 || j >= d || k < 0.0 || k >= d) {
        return;
    }
    let c = alg_lie_constants(lie);

    if (i == j) {
        // Skew-symmetry strictly requires [e_i, e_i] = 0
        let idx = (i * d + i) * d + k;
        c[idx] = 0.0;
        return;
    }

    let idx_ij = (i * d + j) * d + k;
    let idx_ji = (j * d + i) * d + k;
    c[idx_ij] = val;
    c[idx_ji] = -val;
}

// Computes the Lie bracket w = [u, v] of two vectors of dimension d
// Output: newly allocated double* array of size d
fn alg_lie_bracket(lie: AlgLieAlgebra, u: ptr, v: ptr) -> ptr {
    let d = alg_lie_dim(lie);
    let out = calloc(d, 8.0);
    let c = alg_lie_constants(lie);

    var i = 0.0;
    while (i < d) {
        let ui = u[i];
        if (fabs(ui) > 0.000000000000001) {
            var j = 0.0;
            while (j < d) {
                let vj = v[j];
                if (fabs(vj) > 0.000000000000001) {
                    let uivj = ui * vj;
                    let base_idx = (i * d + j) * d;
                    var k = 0.0;
                    while (k < d) {
                        out[k] = out[k] + (uivj * c[base_idx + k]);
                        k = k + 1.0;
                    }
                }
                j = j + 1.0;
            }
        }
        i = i + 1.0;
    }
    return out;
}

// Checks the Jacobi identity across all basis triples:
// J_{ijk}^l = sum_m (c_{jk}^m * c_{im}^l + c_{ki}^m * c_{jm}^l + c_{ij}^m * c_{km}^l) = 0
// Computes direct tensor contraction with O(1) memory allocations
fn alg_lie_jacobi_check(lie: AlgLieAlgebra, tol: float) -> float {
    let d = alg_lie_dim(lie);
    let c = alg_lie_constants(lie);

    var i = 0.0;
    while (i < d) {
        var j = 0.0;
        while (j < d) {
            var k = 0.0;
            while (k < d) {
                var l = 0.0;
                while (l < d) {
                    var sum_jacobi = 0.0;
                    var m = 0.0;
                    while (m < d) {
                        let c_jk_m = c[(j * d + k) * d + m];
                        let c_im_l = c[(i * d + m) * d + l];

                        let c_ki_m = c[(k * d + i) * d + m];
                        let c_jm_l = c[(j * d + m) * d + l];

                        let c_ij_m = c[(i * d + j) * d + m];
                        let c_km_l = c[(k * d + m) * d + l];

                        sum_jacobi = sum_jacobi + (c_jk_m * c_im_l + c_ki_m * c_jm_l + c_ij_m * c_km_l);
                        m = m + 1.0;
                    }

                    if (fabs(sum_jacobi) > tol) {
                        return 0.0; // Jacobi identity violated
                    }
                    l = l + 1.0;
                }
                k = k + 1.0;
            }
            j = j + 1.0;
        }
        i = i + 1.0;
    }
    return 1.0; // Jacobi identity holds across all basis elements
}

// Constructs the d x d adjoint representation matrix ad_u where (ad_u)_{kj} = sum_i u^i c_{ij}^k
fn alg_lie_adjoint_matrix(lie: AlgLieAlgebra, u: ptr) -> AlgMat {
    let d = alg_lie_dim(lie);
    let m = alg_mat_create(d, d);
    let c = alg_lie_constants(lie);
    let m_data = m.data;

    var i = 0.0;
    while (i < d) {
        let ui = u[i];
        if (fabs(ui) > 0.000000000000001) {
            var j = 0.0;
            while (j < d) {
                let base_idx = (i * d + j) * d;
                var k = 0.0;
                while (k < d) {
                    m_data[k * d + j] = m_data[k * d + j] + (ui * c[base_idx + k]);
                    k = k + 1.0;
                }
                j = j + 1.0;
            }
        }
        i = i + 1.0;
    }
    return m;
}

// Computes the d x d Killing metric matrix K_{ij} = Tr(ad_{e_i} ad_{e_j})
// Evaluated via direct contraction: K_{ij} = sum_{a, b} c_{ia}^b * c_{jb}^a
// Single matrix allocation with zero intermediate allocations
fn alg_lie_killing_matrix(lie: AlgLieAlgebra) -> AlgMat {
    let d = alg_lie_dim(lie);
    let k_mat = alg_mat_create(d, d);
    let c = alg_lie_constants(lie);
    let k_data = k_mat.data;

    var i = 0.0;
    while (i < d) {
        var j = 0.0;
        while (j < d) {
            var tr = 0.0;
            var a = 0.0;
            while (a < d) {
                var b = 0.0;
                while (b < d) {
                    let c_ia_b = c[(i * d + a) * d + b];
                    let c_jb_a = c[(j * d + b) * d + a];
                    tr = tr + (c_ia_b * c_jb_a);
                    b = b + 1.0;
                }
                a = a + 1.0;
            }
            k_data[i * d + j] = tr;
            j = j + 1.0;
        }
        i = i + 1.0;
    }
    return k_mat;
}

// Evaluates Killing form scalar B(u, v) = u^T K v
fn alg_lie_killing_form(lie: AlgLieAlgebra, u: ptr, v: ptr) -> float {
    let d = alg_lie_dim(lie);
    let k_mat = alg_lie_killing_matrix(lie);
    let k_data = k_mat.data;

    var sum = 0.0;
    var i = 0.0;
    while (i < d) {
        let ui = u[i];
        if (fabs(ui) > 0.000000000000001) {
            var j = 0.0;
            while (j < d) {
                sum = sum + (ui * v[j] * k_data[i * d + j]);
                j = j + 1.0;
            }
        }
        i = i + 1.0;
    }

    alg_mat_free(k_mat);
    return sum;
}

// Cartan's Criterion for Semisimplicity:
// A Lie algebra g is semisimple iff the Killing metric K is non-degenerate (det(K) != 0)
fn alg_lie_is_semisimple(lie: AlgLieAlgebra) -> float {
    let k_mat = alg_lie_killing_matrix(lie);
    let det_k = alg_mat_determinant(k_mat);
    alg_mat_free(k_mat);

    if (fabs(det_k) > 0.000001) {
        return 1.0; // Semisimple
    }
    return 0.0;     // Solvable, nilpotent, or degenerate radical
}

// ============================================================================
// Classical Matrix Lie Algebras & Baker-Campbell-Hausdorff (BCH) Formula
// ============================================================================

// Matrix Commutator Lie Bracket: [A, B] = A * B - B * A
fn alg_lie_mat_commutator(a: AlgMat, b: AlgMat) -> AlgMat {
    let ab = alg_mat_mul(a, b);
    let ba = alg_mat_mul(b, a);
    let comm = alg_mat_sub(ab, ba);
    alg_mat_free(ab);
    alg_mat_free(ba);
    return comm;
}

// Generates J_x generator of so(3) (3x3 skew-symmetric matrix)
fn alg_so3_jx() -> AlgMat {
    let m = alg_mat_create(3.0, 3.0);
    alg_mat_set(m, 1.0, 2.0, -1.0);
    alg_mat_set(m, 2.0, 1.0, 1.0);
    return m;
}

// Generates J_y generator of so(3) (3x3 skew-symmetric matrix)
fn alg_so3_jy() -> AlgMat {
    let m = alg_mat_create(3.0, 3.0);
    alg_mat_set(m, 0.0, 2.0, 1.0);
    alg_mat_set(m, 2.0, 0.0, -1.0);
    return m;
}

// Generates J_z generator of so(3) (3x3 skew-symmetric matrix)
fn alg_so3_jz() -> AlgMat {
    let m = alg_mat_create(3.0, 3.0);
    alg_mat_set(m, 0.0, 1.0, -1.0);
    alg_mat_set(m, 1.0, 0.0, 1.0);
    return m;
}

// Validates the symplectic Lie algebra condition for sp(2n):
// M^T * J + J * M = 0 where J is canonical 2n x 2n symplectic matrix
fn alg_sp_is_hamiltonian(m: AlgMat, n: float, tol: float) -> float {
    let j_mat = alg_symplectic_matrix(n);
    let mt = alg_mat_transpose(m);

    let mt_j = alg_mat_mul(mt, j_mat);
    let j_m = alg_mat_mul(j_mat, m);
    let sum_mat = alg_mat_add(mt_j, j_m);

    var max_dev = 0.0;
    let total = sum_mat.rows * sum_mat.cols;
    let s_data = sum_mat.data;
    var i = 0.0;
    while (i < total) {
        let val = fabs(s_data[i]);
        if (val > max_dev) { max_dev = val; }
        i = i + 1.0;
    }

    alg_mat_free(j_mat);
    alg_mat_free(mt);
    alg_mat_free(mt_j);
    alg_mat_free(j_m);
    alg_mat_free(sum_mat);

    if (max_dev <= tol) {
        return 1.0;
    }
    return 0.0;
}

// Computes the Baker-Campbell-Hausdorff (BCH) expansion truncated to order 2:
// Z = X + Y + (1/2)[X, Y] + (1/12)([X, [X, Y]] + [Y, [Y, X]])
// All intermediate matrices are explicitly freed
fn alg_lie_bch_order2(x: AlgMat, y: AlgMat) -> AlgMat {
    let xy_comm = alg_lie_mat_commutator(x, y);

    // [X, [X, Y]]
    let x_xy = alg_lie_mat_commutator(x, xy_comm);
    // [Y, [Y, X]] = -[Y, [X, Y]]
    let y_xy = alg_lie_mat_commutator(y, xy_comm);

    // Term 1: X + Y
    let sum_xy = alg_mat_add(x, y);

    // Term 2: (1/2) * [X, Y]
    let half_comm = alg_mat_scale(xy_comm, 0.5);

    // Term 3: (1/12) * ([X, [X, Y]] - [Y, [X, Y]])
    let diff_nested = alg_mat_sub(x_xy, y_xy);
    let twelfth_term = alg_mat_scale(diff_nested, 1.0 / 12.0);

    // Sum all terms
    let sum_12 = alg_mat_add(sum_xy, half_comm);
    let z = alg_mat_add(sum_12, twelfth_term);

    // Cleanup all intermediate allocations
    alg_mat_free(xy_comm);
    alg_mat_free(x_xy);
    alg_mat_free(y_xy);
    alg_mat_free(sum_xy);
    alg_mat_free(half_comm);
    alg_mat_free(diff_nested);
    alg_mat_free(twelfth_term);
    alg_mat_free(sum_12);

    return z;
}

// ============================================================================
// Pre-Lie (Vinberg / Left-Symmetric) Algebras
// ============================================================================

// Structure representing a Pre-Lie algebra (V, ·) of dimension d
// Product tensor: e_i · e_j = sum_k T_{ij}^k e_k
// Stored as d x d x d contiguous doubles: index = (i * d + j) * d + k
struct AlgPreLie {
    dim: float;
    data: ptr;
}

fn alg_prelie_dim(pl: AlgPreLie) -> float { return pl.dim; }
fn alg_prelie_tensor(pl: AlgPreLie) -> ptr { return pl.data; }

fn alg_prelie_create(dim: float) -> AlgPreLie {
    var d = dim;
    if (d <= 0.0) { d = 1.0; }
    let total = d * d * d;
    let buf = calloc(total, 8.0);
    return AlgPreLie { dim: d, data: buf };
}

fn alg_prelie_free(pl: AlgPreLie) {
    let t = alg_prelie_tensor(pl);
    if (t != 0.0) {
        free(t);
    }
}

fn alg_prelie_set(pl: AlgPreLie, i: float, j: float, k: float, val: float) {
    let d = alg_prelie_dim(pl);
    if (i >= 0.0 && i < d && j >= 0.0 && j < d && k >= 0.0 && k < d) {
        let t = alg_prelie_tensor(pl);
        let idx = (i * d + j) * d + k;
        t[idx] = val;
    }
}

fn alg_prelie_get(pl: AlgPreLie, i: float, j: float, k: float) -> float {
    let d = alg_prelie_dim(pl);
    if (i < 0.0 || i >= d || j < 0.0 || j >= d || k < 0.0 || k >= d) { return 0.0; }
    let t = alg_prelie_tensor(pl);
    let idx = (i * d + j) * d + k;
    return t[idx];
}

// Multiplies two elements: w = u · v
fn alg_prelie_mul(pl: AlgPreLie, u: ptr, v: ptr) -> ptr {
    let d = alg_prelie_dim(pl);
    let out = calloc(d, 8.0);
    let t = alg_prelie_tensor(pl);

    var i = 0.0;
    while (i < d) {
        let ui = u[i];
        if (fabs(ui) > 0.000000000000001) {
            var j = 0.0;
            while (j < d) {
                let vj = v[j];
                if (fabs(vj) > 0.000000000000001) {
                    let uivj = ui * vj;
                    let base_idx = (i * d + j) * d;
                    var k = 0.0;
                    while (k < d) {
                        out[k] = out[k] + (uivj * t[base_idx + k]);
                        k = k + 1.0;
                    }
                }
                j = j + 1.0;
            }
        }
        i = i + 1.0;
    }
    return out;
}

// Evaluates the associator (u, v, w) = (u · v) · w - u · (v · w)
fn alg_prelie_associator(pl: AlgPreLie, u: ptr, v: ptr, w: ptr) -> ptr {
    let uv = alg_prelie_mul(pl, u, v);
    let uv_w = alg_prelie_mul(pl, uv, w);

    let vw = alg_prelie_mul(pl, v, w);
    let u_vw = alg_prelie_mul(pl, u, vw);

    let d = alg_prelie_dim(pl);
    let res = calloc(d, 8.0);
    var i = 0.0;
    while (i < d) {
        res[i] = uv_w[i] - u_vw[i];
        i = i + 1.0;
    }

    free(uv);
    free(uv_w);
    free(vw);
    free(u_vw);
    return res;
}

// Verifies the left-symmetric identity across all basis triples:
// (e_i, e_j, e_k) - (e_j, e_i, e_k) = 0
fn alg_prelie_verify_identity(pl: AlgPreLie, tol: float) -> float {
    let d = alg_prelie_dim(pl);
    let e_i = calloc(d, 8.0);
    let e_j = calloc(d, 8.0);
    let e_k = calloc(d, 8.0);

    var i = 0.0;
    while (i < d) {
        e_i[i] = 1.0;
        var j = 0.0;
        while (j < d) {
            e_j[j] = 1.0;
            var k = 0.0;
            while (k < d) {
                e_k[k] = 1.0;

                let assoc_ijk = alg_prelie_associator(pl, e_i, e_j, e_k);
                let assoc_jik = alg_prelie_associator(pl, e_j, e_i, e_k);

                var m = 0.0;
                while (m < d) {
                    let diff = fabs(assoc_ijk[m] - assoc_jik[m]);
                    if (diff > tol) {
                        free(assoc_ijk);
                        free(assoc_jik);
                        free(e_i);
                        free(e_j);
                        free(e_k);
                        return 0.0; // Left-symmetry failed
                    }
                    m = m + 1.0;
                }

                free(assoc_ijk);
                free(assoc_jik);
                e_k[k] = 0.0;
                k = k + 1.0;
            }
            e_j[j] = 0.0;
            j = j + 1.0;
        }
        e_i[i] = 0.0;
        i = i + 1.0;
    }

    free(e_i);
    free(e_j);
    free(e_k);
    return 1.0; // Left-symmetric identity holds identically
}

// Computes the induced Lie bracket [u, v] = u · v - v · u
// By the Fundamental Theorem of Pre-Lie Algebras, this bracket satisfies the Jacobi identity!
fn alg_prelie_induced_bracket(pl: AlgPreLie, u: ptr, v: ptr) -> ptr {
    let uv = alg_prelie_mul(pl, u, v);
    let vu = alg_prelie_mul(pl, v, u);
    let d = alg_prelie_dim(pl);
    let out = calloc(d, 8.0);

    var i = 0.0;
    while (i < d) {
        out[i] = uv[i] - vu[i];
        i = i + 1.0;
    }

    free(uv);
    free(vu);
    return out;
}

// ============================================================================
// Graded Lie Superalgebras & Classical Poisson Phase Space
// ============================================================================

// Graded Lie superalgebra g = g_0 ⊕ g_1 (dim = dim0 + dim1)
// Stored as d x d x d doubles: [e_i, e_j] = sum_k c_{ij}^k e_k
struct AlgLieSuper {
    dim0: float; // Bosonic subspace dimension (parity 0)
    dim1: float; // Fermionic subspace dimension (parity 1)
    dim: float;  // Total dimension
    constants: ptr;
}

fn alg_super_dim0(ls: AlgLieSuper) -> float { return ls.dim0; }
fn alg_super_dim1(ls: AlgLieSuper) -> float { return ls.dim1; }
fn alg_super_dim(ls: AlgLieSuper) -> float { return ls.dim; }
fn alg_super_constants(ls: AlgLieSuper) -> ptr { return ls.constants; }

// Returns the Z_2 grading parity: 0.0 for boson, 1.0 for fermion
fn alg_super_parity(ls: AlgLieSuper, idx: float) -> float {
    if (idx < ls.dim0) { return 0.0; }
    return 1.0;
}

fn alg_super_create(dim0: float, dim1: float) -> AlgLieSuper {
    let d = dim0 + dim1;
    let total = d * d * d;
    let buf = calloc(total, 8.0);
    return AlgLieSuper { dim0: dim0, dim1: dim1, dim: d, constants: buf };
}

fn alg_super_free(ls: AlgLieSuper) {
    let c = alg_super_constants(ls);
    if (c != 0.0) {
        free(c);
    }
}

// Sets graded bracket [e_i, e_j] = sum_k c_{ij}^k e_k
// Enforces graded skew-symmetry: [e_j, e_i] = -(-1)^{|i||j|} [e_i, e_j]
fn alg_super_set(ls: AlgLieSuper, i: float, j: float, k: float, val: float) {
    let d = alg_super_dim(ls);
    if (i < 0.0 || i >= d || j < 0.0 || j >= d || k < 0.0 || k >= d) { return; }
    let c = alg_super_constants(ls);

    let p_i = alg_super_parity(ls, i);
    let p_j = alg_super_parity(ls, j);

    var sign = -1.0;
    if (p_i == 1.0 && p_j == 1.0) {
        sign = 1.0; // Fermion-fermion bracket is symmetric anticommutator: [f1, f2] = +[f2, f1]
    }

    let idx_ij = (i * d + j) * d + k;
    let idx_ji = (j * d + i) * d + k;

    c[idx_ij] = val;
    c[idx_ji] = sign * val;
}

fn alg_super_get(ls: AlgLieSuper, i: float, j: float, k: float) -> float {
    let d = alg_super_dim(ls);
    if (i < 0.0 || i >= d || j < 0.0 || j >= d || k < 0.0 || k >= d) { return 0.0; }
    let c = alg_super_constants(ls);
    let idx = (i * d + j) * d + k;
    return c[idx];
}

// Evaluates the graded super-Jacobi identity:
// (-1)^{|a||c|} [a, [b, c]] + (-1)^{|b||a|} [b, [c, a]] + (-1)^{|c||b|} [c, [a, b]] = 0
fn alg_super_jacobi_check(ls: AlgLieSuper, tol: float) -> float {
    let d = alg_super_dim(ls);
    let c = alg_super_constants(ls);

    var i = 0.0;
    while (i < d) {
        let p_i = alg_super_parity(ls, i);
        var j = 0.0;
        while (j < d) {
            let p_j = alg_super_parity(ls, j);
            var k = 0.0;
            while (k < d) {
                let p_k = alg_super_parity(ls, k);

                // Sign exponents: (-1)^{p_i * p_k}, (-1)^{p_j * p_i}, (-1)^{p_k * p_j}
                var s1 = 1.0;
                if (p_i == 1.0 && p_k == 1.0) { s1 = -1.0; }
                var s2 = 1.0;
                if (p_j == 1.0 && p_i == 1.0) { s2 = -1.0; }
                var s3 = 1.0;
                if (p_k == 1.0 && p_j == 1.0) { s3 = -1.0; }

                var l = 0.0;
                while (l < d) {
                    var sum_super = 0.0;
                    var m = 0.0;
                    while (m < d) {
                        let c_jk_m = c[(j * d + k) * d + m];
                        let c_im_l = c[(i * d + m) * d + l];

                        let c_ki_m = c[(k * d + i) * d + m];
                        let c_jm_l = c[(j * d + m) * d + l];

                        let c_ij_m = c[(i * d + j) * d + m];
                        let c_km_l = c[(k * d + m) * d + l];

                        sum_super = sum_super + (s1 * c_jk_m * c_im_l + s2 * c_ki_m * c_jm_l + s3 * c_ij_m * c_km_l);
                        m = m + 1.0;
                    }

                    if (fabs(sum_super) > tol) {
                        return 0.0; // Super-Jacobi violated
                    }
                    l = l + 1.0;
                }
                k = k + 1.0;
            }
            j = j + 1.0;
        }
        i = i + 1.0;
    }
    return 1.0;
}

// --- Classical Poisson Phase Space Algebra ---
struct AlgPoisson {
    n_dof: float; // Degrees of freedom n (phase space dimension = 2 * n_dof)
}

fn alg_poisson_create(n_dof: float) -> AlgPoisson {
    return AlgPoisson { n_dof: n_dof };
}

// Canonical Poisson bracket {f, g} for observables defined by their phase space gradients:
// grad = [df/dq_0, ..., df/dq_{n-1}, df/dp_0, ..., df/dp_{n-1}]
// {f, g} = sum_{k=0}^{n-1} (df/dq_k * dg/dp_k - df/dp_k * dg/dq_k)
fn alg_poisson_bracket(ps: AlgPoisson, grad_f: ptr, grad_g: ptr) -> float {
    let n = ps.n_dof;
    var sum = 0.0;
    var k = 0.0;
    while (k < n) {
        let df_dq = grad_f[k];
        let df_dp = grad_f[n + k];

        let dg_dq = grad_g[k];
        let dg_dp = grad_g[n + k];

        sum = sum + (df_dq * dg_dp - df_dp * dg_dq);
        k = k + 1.0;
    }
    return sum;
}
