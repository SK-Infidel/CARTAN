// src/std/algebra/tensor.cl
// CARTAN Standard Library: Pillar 1 — Multilinear Tensor Algebra & Matrix Factorizations
// Pure-CARTAN Bare-Metal Implementation (Zero-Mock Rule Enforced)

include "src/std/constants.ch";
include "src/std/math.cl";

extern fn malloc(size: float) -> ptr;
extern fn calloc(count: float, size: float) -> ptr;
extern fn free(p: ptr) -> void;
extern fn memcpy(dst: ptr, src: ptr, size: float) -> ptr;

// ============================================================================
// Structure Definitions
// ============================================================================

// N-Dimensional Strided Tensor (Rank <= 8)
struct AlgTensor {
    ndim: float;
    shape: ptr;
    strides: ptr;
    total_elements: float;
    data: ptr;
}

// 2D Dense Linear Matrix
struct AlgMat {
    rows: float;
    cols: float;
    data: ptr;
}

// ============================================================================
// Core N-Dimensional Tensor Operations
// ============================================================================

// Allocates an N-dimensional tensor with given shape
fn alg_tensor_create(shape: ptr, ndim: float) -> AlgTensor {
    if (ndim <= 0.0 || shape == 0.0) {
        return AlgTensor { ndim: 0.0, shape: 0.0, strides: 0.0, total_elements: 0.0, data: 0.0 };
    }

    let s_buf = calloc(ndim, 8.0);
    let st_buf = calloc(ndim, 8.0);

    // Copy shape and compute total elements
    var total = 1.0;
    var i = 0.0;
    while (i < ndim) {
        let dim = shape[i];
        s_buf[i] = dim;
        total = total * dim;
        i = i + 1.0;
    }

    // Compute row-major strides
    if (ndim > 0.0) {
        st_buf[ndim - 1.0] = 1.0;
        var k = ndim - 2.0;
        while (k >= 0.0) {
            st_buf[k] = st_buf[k + 1.0] * s_buf[k + 1.0];
            k = k - 1.0;
        }
    }

    let d_buf = calloc(total, 8.0);

    return AlgTensor {
        ndim: ndim,
        shape: s_buf,
        strides: st_buf,
        total_elements: total,
        data: d_buf
    };
}

// Allocates an N-dimensional tensor initialized with zeros
fn alg_tensor_zeros(shape: ptr, ndim: float) -> AlgTensor {
    return alg_tensor_create(shape, ndim);
}

// Allocates an N-dimensional tensor initialized with ones
fn alg_tensor_ones(shape: ptr, ndim: float) -> AlgTensor {
    let t = alg_tensor_create(shape, ndim);
    var i = 0.0;
    while (i < t.total_elements) {
        t.data[i] = 1.0;
        i = i + 1.0;
    }
    return t;
}

// Safely deallocates tensor memory buffers
fn alg_tensor_free(t: AlgTensor) {
    if (t.data != 0.0) {
        free(t.data);
    }
    if (t.strides != 0.0) {
        free(t.strides);
    }
    if (t.shape != 0.0) {
        free(t.shape);
    }
}

// Computes flat element offset from multi-dimensional coordinates
fn alg_tensor_offset(t: AlgTensor, indices: ptr) -> float {
    var offset = 0.0;
    var i = 0.0;
    while (i < t.ndim) {
        let idx = indices[i];
        offset = offset + idx * t.strides[i];
        i = i + 1.0;
    }
    return offset;
}

// Retrieves a scalar value at multi-dimensional coordinates
fn alg_tensor_get(t: AlgTensor, indices: ptr) -> float {
    let off = alg_tensor_offset(t, indices);
    return t.data[off];
}

// Stores a scalar value at multi-dimensional coordinates
fn alg_tensor_set(t: AlgTensor, indices: ptr, val: float) {
    let off = alg_tensor_offset(t, indices);
    t.data[off] = val;
}

// Creates an exact deep clone of an N-dimensional tensor
fn alg_tensor_clone(t: AlgTensor) -> AlgTensor {
    let out = alg_tensor_create(t.shape, t.ndim);
    var i = 0.0;
    while (i < t.total_elements) {
        out.data[i] = t.data[i];
        i = i + 1.0;
    }
    return out;
}

// Reshapes a tensor to a new dimension shape (preserving volume)
fn alg_tensor_reshape(t: AlgTensor, new_shape: ptr, new_ndim: float) -> AlgTensor {
    var new_total = 1.0;
    var i = 0.0;
    while (i < new_ndim) {
        new_total = new_total * new_shape[i];
        i = i + 1.0;
    }

    if (new_total != t.total_elements) {
        // Incompatible shape: return empty tensor
        return AlgTensor { ndim: 0.0, shape: 0.0, strides: 0.0, total_elements: 0.0, data: 0.0 };
    }

    let out = alg_tensor_create(new_shape, new_ndim);
    i = 0.0;
    while (i < t.total_elements) {
        out.data[i] = t.data[i];
        i = i + 1.0;
    }
    return out;
}

// Extracts a sub-tensor slice along a specified axis: [start, end_idx)
fn alg_tensor_slice(t: AlgTensor, axis: float, start: float, end_idx: float) -> AlgTensor {
    if (axis < 0.0 || axis >= t.ndim || start < 0.0 || end_idx > t.shape[axis] || start >= end_idx) {
        return AlgTensor { ndim: 0.0, shape: 0.0, strides: 0.0, total_elements: 0.0, data: 0.0 };
    }

    let slice_len = end_idx - start;
    let new_shape = calloc(t.ndim, 8.0);
    var d = 0.0;
    while (d < t.ndim) {
        if (d == axis) {
            new_shape[d] = slice_len;
        } else {
            new_shape[d] = t.shape[d];
        }
        d = d + 1.0;
    }

    let out = alg_tensor_create(new_shape, t.ndim);
    free(new_shape);

    let cur_idx = calloc(t.ndim, 8.0);
    let src_idx = calloc(t.ndim, 8.0);

    var e = 0.0;
    while (e < out.total_elements) {
        // Compute multi-index in output tensor
        var rem = e;
        d = 0.0;
        while (d < out.ndim) {
            let dim_idx = floor(rem / out.strides[d]);
            cur_idx[d] = dim_idx;
            rem = fmod(rem, out.strides[d]);

            if (d == axis) {
                src_idx[d] = dim_idx + start;
            } else {
                src_idx[d] = dim_idx;
            }
            d = d + 1.0;
        }

        let val = alg_tensor_get(t, src_idx);
        out.data[e] = val;
        e = e + 1.0;
    }

    free(src_idx);
    free(cur_idx);
    return out;
}

// ============================================================================
// Multilinear Contraction & Einsum Operations
// ============================================================================

// Tensor Outer Product: C = A ⊗ B
fn alg_tensor_outer_product(A: AlgTensor, B: AlgTensor) -> AlgTensor {
    let out_ndim = A.ndim + B.ndim;
    let out_shape = calloc(out_ndim, 8.0);

    var i = 0.0;
    while (i < A.ndim) {
        out_shape[i] = A.shape[i];
        i = i + 1.0;
    }

    var j = 0.0;
    while (j < B.ndim) {
        out_shape[A.ndim + j] = B.shape[j];
        j = j + 1.0;
    }

    let out = alg_tensor_create(out_shape, out_ndim);
    free(out_shape);

    var a = 0.0;
    while (a < A.total_elements) {
        let val_a = A.data[a];
        var b = 0.0;
        while (b < B.total_elements) {
            let val_b = B.data[b];
            out.data[a * B.total_elements + b] = val_a * val_b;
            b = b + 1.0;
        }
        a = a + 1.0;
    }

    return out;
}

// Tensor Contraction over two paired axes: sums over axis1 == axis2
fn alg_tensor_contract(t: AlgTensor, axis1: float, axis2: float) -> AlgTensor {
    if (axis1 == axis2 || axis1 >= t.ndim || axis2 >= t.ndim || t.shape[axis1] != t.shape[axis2]) {
        return AlgTensor { ndim: 0.0, shape: 0.0, strides: 0.0, total_elements: 0.0, data: 0.0 };
    }

    var ax_low = axis1;
    var ax_high = axis2;
    if (axis1 > axis2) {
        ax_low = axis2;
        ax_high = axis1;
    }
    let contract_dim = t.shape[axis1];

    if (t.ndim == 2.0) {
        // Trace contraction of a 2D tensor: returns a 1x1 scalar tensor
        let sc_shape = calloc(1.0, 8.0);
        sc_shape[0] = 1.0;
        let out_scalar = alg_tensor_create(sc_shape, 1.0);
        free(sc_shape);

        var tr = 0.0;
        var k = 0.0;
        while (k < contract_dim) {
            let off = k * t.strides[0] + k * t.strides[1];
            tr = tr + t.data[off];
            k = k + 1.0;
        }
        out_scalar.data[0] = tr;
        return out_scalar;
    }

    let out_ndim = t.ndim - 2.0;
    let out_shape = calloc(out_ndim, 8.0);

    var out_d = 0.0;
    var d = 0.0;
    while (d < t.ndim) {
        if (d != ax_low && d != ax_high) {
            out_shape[out_d] = t.shape[d];
            out_d = out_d + 1.0;
        }
        d = d + 1.0;
    }

    let out = alg_tensor_create(out_shape, out_ndim);
    free(out_shape);

    let src_idx = calloc(t.ndim, 8.0);

    var e = 0.0;
    while (e < out.total_elements) {
        // Map output element e to its non-contracted indices
        var rem = e;
        out_d = 0.0;
        d = 0.0;
        while (d < t.ndim) {
            if (d != ax_low && d != ax_high) {
                let dim_idx = floor(rem / out.strides[out_d]);
                src_idx[d] = dim_idx;
                rem = fmod(rem, out.strides[out_d]);
                out_d = out_d + 1.0;
            }
            d = d + 1.0;
        }

        // Sum over contracted dimension
        var sum_val = 0.0;
        var k = 0.0;
        while (k < contract_dim) {
            src_idx[ax_low] = k;
            src_idx[ax_high] = k;
            sum_val = sum_val + alg_tensor_get(t, src_idx);
            k = k + 1.0;
        }

        out.data[e] = sum_val;
        e = e + 1.0;
    }

    free(src_idx);
    return out;
}

// Einsum Dot Contraction: C = A · B contracted along axisA and axisB
fn alg_tensor_einsum_dot(A: AlgTensor, axisA: float, B: AlgTensor, axisB: float) -> AlgTensor {
    let outer = alg_tensor_outer_product(A, B);
    let shifted_axisB = A.ndim + axisB;
    let out = alg_tensor_contract(outer, axisA, shifted_axisB);
    alg_tensor_free(outer);
    return out;
}

// ============================================================================
// Matrix Algebra Primitives (M x N)
// ============================================================================

// Allocates an M x N matrix
fn alg_mat_create(rows: float, cols: float) -> AlgMat {
    if (rows <= 0.0 || cols <= 0.0) {
        return AlgMat { rows: 0.0, cols: 0.0, data: 0.0 };
    }
    let total = rows * cols;
    let d = calloc(total, 8.0);
    return AlgMat { rows: rows, cols: cols, data: d };
}

// Allocates an N x N identity matrix
fn alg_mat_identity(n: float) -> AlgMat {
    let m = alg_mat_create(n, n);
    var i = 0.0;
    while (i < n) {
        m.data[i * n + i] = 1.0;
        i = i + 1.0;
    }
    return m;
}

// Safely deallocates a matrix
fn alg_mat_free(m: AlgMat) {
    if (m.data != 0.0) {
        free(m.data);
    }
}

// Retrieves matrix element (r, c)
fn alg_mat_get(m: AlgMat, r: float, c: float) -> float {
    return m.data[r * m.cols + c];
}

// Sets matrix element (r, c)
fn alg_mat_set(m: AlgMat, r: float, c: float, val: float) {
    m.data[r * m.cols + c] = val;
}

// Creates a deep copy of a matrix
fn alg_mat_clone(m: AlgMat) -> AlgMat {
    let out = alg_mat_create(m.rows, m.cols);
    var i = 0.0;
    let total = m.rows * m.cols;
    while (i < total) {
        out.data[i] = m.data[i];
        i = i + 1.0;
    }
    return out;
}

// Transposes an M x N matrix to N x M
fn alg_mat_transpose(m: AlgMat) -> AlgMat {
    let out = alg_mat_create(m.cols, m.rows);
    var r = 0.0;
    while (r < m.rows) {
        var c = 0.0;
        while (c < m.cols) {
            out.data[c * m.rows + r] = m.data[r * m.cols + c];
            c = c + 1.0;
        }
        r = r + 1.0;
    }
    return out;
}

// Matrix Multiplication C = A * B using cache-friendly IKJ loop ordering
fn alg_mat_mul(A: AlgMat, B: AlgMat) -> AlgMat {
    if (A.cols != B.rows) {
        return AlgMat { rows: 0.0, cols: 0.0, data: 0.0 };
    }

    let M = A.rows;
    let K = A.cols;
    let N = B.cols;
    let C = alg_mat_create(M, N);

    var i = 0.0;
    while (i < M) {
        var k = 0.0;
        while (k < K) {
            let a_ik = A.data[i * K + k];
            var j = 0.0;
            while (j < N) {
                let off_c = i * N + j;
                C.data[off_c] = C.data[off_c] + a_ik * B.data[k * N + j];
                j = j + 1.0;
            }
            k = k + 1.0;
        }
        i = i + 1.0;
    }

    return C;
}

// Computes the trace of a square matrix
fn alg_mat_trace(m: AlgMat) -> float {
    if (m.rows != m.cols) { return 0.0; }
    var tr = 0.0;
    var i = 0.0;
    while (i < m.rows) {
        tr = tr + m.data[i * m.cols + i];
        i = i + 1.0;
    }
    return tr;
}

// Computes matrix determinant via LU Decomposition with partial row pivoting
fn alg_mat_determinant(m: AlgMat) -> float {
    if (m.rows != m.cols) { return 0.0; }
    let n = m.rows;
    let U = alg_mat_clone(m);

    var det_sign = 1.0;
    var k = 0.0;
    while (k < n) {
        // Find pivot in column k
        var max_val = fabs(U.data[k * n + k]);
        var pivot_row = k;
        var r = k + 1.0;
        while (r < n) {
            let val = fabs(U.data[r * n + k]);
            if (val > max_val) {
                max_val = val;
                pivot_row = r;
            }
            r = r + 1.0;
        }

        // Check for singularity
        if (max_val < 0.000000000001) { // 1e-12
            alg_mat_free(U);
            return 0.0;
        }

        // Swap rows if necessary
        if (pivot_row != k) {
            var c = 0.0;
            while (c < n) {
                let tmp = U.data[k * n + c];
                U.data[k * n + c] = U.data[pivot_row * n + c];
                U.data[pivot_row * n + c] = tmp;
                c = c + 1.0;
            }
            det_sign = -det_sign;
        }

        // Eliminate below pivot
        let pivot = U.data[k * n + k];
        var i = k + 1.0;
        while (i < n) {
            let factor = U.data[i * n + k] / pivot;
            var j = k + 1.0;
            while (j < n) {
                U.data[i * n + j] = U.data[i * n + j] - factor * U.data[k * n + j];
                j = j + 1.0;
            }
            i = i + 1.0;
        }

        k = k + 1.0;
    }

    // Multiply diagonal elements of U
    var det = det_sign;
    var d = 0.0;
    while (d < n) {
        det = det * U.data[d * n + d];
        d = d + 1.0;
    }

    alg_mat_free(U);
    return det;
}

// Computes matrix inverse via Gauss-Jordan elimination with partial row pivoting
fn alg_mat_inverse(m: AlgMat) -> AlgMat {
    if (m.rows != m.cols) {
        return AlgMat { rows: 0.0, cols: 0.0, data: 0.0 };
    }

    let n = m.rows;
    let aug_cols = n * 2.0;
    let aug = alg_mat_create(n, aug_cols);

    // Initialize augmented matrix [A | I]
    var r = 0.0;
    while (r < n) {
        var c = 0.0;
        while (c < n) {
            aug.data[r * aug_cols + c] = m.data[r * n + c];
            c = c + 1.0;
        }
        aug.data[r * aug_cols + n + r] = 1.0;
        r = r + 1.0;
    }

    // Gauss-Jordan elimination
    var k = 0.0;
    while (k < n) {
        // Partial pivoting
        var max_val = fabs(aug.data[k * aug_cols + k]);
        var pivot_row = k;
        var i = k + 1.0;
        while (i < n) {
            let val = fabs(aug.data[i * aug_cols + k]);
            if (val > max_val) {
                max_val = val;
                pivot_row = i;
            }
            i = i + 1.0;
        }

        if (max_val < 0.000000000001) { // 1e-12: Singular
            alg_mat_free(aug);
            return AlgMat { rows: 0.0, cols: 0.0, data: 0.0 };
        }

        // Swap rows
        if (pivot_row != k) {
            var c = 0.0;
            while (c < aug_cols) {
                let tmp = aug.data[k * aug_cols + c];
                aug.data[k * aug_cols + c] = aug.data[pivot_row * aug_cols + c];
                aug.data[pivot_row * aug_cols + c] = tmp;
                c = c + 1.0;
            }
        }

        // Normalize pivot row
        let pivot = aug.data[k * aug_cols + k];
        var c = 0.0;
        while (c < aug_cols) {
            aug.data[k * aug_cols + c] = aug.data[k * aug_cols + c] / pivot;
            c = c + 1.0;
        }

        // Eliminate column in other rows
        i = 0.0;
        while (i < n) {
            if (i != k) {
                let factor = aug.data[i * aug_cols + k];
                c = 0.0;
                while (c < aug_cols) {
                    aug.data[i * aug_cols + c] = aug.data[i * aug_cols + c] - factor * aug.data[k * aug_cols + c];
                    c = c + 1.0;
                }
            }
            i = i + 1.0;
        }

        k = k + 1.0;
    }

    // Extract right half into inverted matrix
    let inv = alg_mat_create(n, n);
    r = 0.0;
    while (r < n) {
        var c = 0.0;
        while (c < n) {
            inv.data[r * n + c] = aug.data[r * aug_cols + n + c];
            c = c + 1.0;
        }
        r = r + 1.0;
    }

    alg_mat_free(aug);
    return inv;
}

// ============================================================================
// Advanced Factorizations: QR, Jacobi Eigensystem & Matrix Exponential
// ============================================================================

// Householder QR Factorization: A = Q * R (Q orthogonal, R upper triangular)
fn alg_mat_qr(A: AlgMat, out_Q: AlgMat, out_R: AlgMat) {
    let m = A.rows;
    let n = A.cols;

    // Initialize R = clone(A) and Q = I_m
    var i = 0.0;
    while (i < m * n) {
        out_R.data[i] = A.data[i];
        i = i + 1.0;
    }

    var r = 0.0;
    while (r < m) {
        var c = 0.0;
        while (c < m) {
            if (r == c) {
                out_Q.data[r * m + c] = 1.0;
            } else {
                out_Q.data[r * m + c] = 0.0;
            }
            c = c + 1.0;
        }
        r = r + 1.0;
    }

    var min_dim = n;
    if (m - 1.0 < n) {
        min_dim = m - 1.0;
    }
    let v = calloc(m, 8.0);

    var k = 0.0;
    while (k < min_dim) {
        // Compute norm of column vector R[k:m, k]
        var norm_sq = 0.0;
        i = k;
        while (i < m) {
            let val = out_R.data[i * n + k];
            norm_sq = norm_sq + val * val;
            i = i + 1.0;
        }
        let norm_x = sqrt(norm_sq);

        if (norm_x > 0.000000000001) {
            let x0 = out_R.data[k * n + k];
            var alpha = norm_x;
            if (x0 >= 0.0) {
                alpha = -norm_x;
            }

            // Form reflector vector v
            v[k] = x0 - alpha;
            i = k + 1.0;
            while (i < m) {
                v[i] = out_R.data[i * n + k];
                i = i + 1.0;
            }

            // Normalize v
            var v_norm_sq = 0.0;
            i = k;
            while (i < m) {
                v_norm_sq = v_norm_sq + v[i] * v[i];
                i = i + 1.0;
            }
            let v_norm = sqrt(v_norm_sq);

            if (v_norm > 0.000000000001) {
                i = k;
                while (i < m) {
                    v[i] = v[i] / v_norm;
                    i = i + 1.0;
                }

                // Apply Householder update to R[k:m, k:n]: R <- R - 2 * v * (v^T * R)
                var j = k;
                while (j < n) {
                    var v_dot_Rj = 0.0;
                    i = k;
                    while (i < m) {
                        v_dot_Rj = v_dot_Rj + v[i] * out_R.data[i * n + j];
                        i = i + 1.0;
                    }

                    let factor = 2.0 * v_dot_Rj;
                    i = k;
                    while (i < m) {
                        out_R.data[i * n + j] = out_R.data[i * n + j] - factor * v[i];
                        i = i + 1.0;
                    }
                    j = j + 1.0;
                }

                // Apply Householder update to Q[0:m, k:m]: Q <- Q - 2 * (Q * v) * v^T
                var row = 0.0;
                while (row < m) {
                    var Qrow_dot_v = 0.0;
                    i = k;
                    while (i < m) {
                        Qrow_dot_v = Qrow_dot_v + out_Q.data[row * m + i] * v[i];
                        i = i + 1.0;
                    }

                    let factor = 2.0 * Qrow_dot_v;
                    i = k;
                    while (i < m) {
                        out_Q.data[row * m + i] = out_Q.data[row * m + i] - factor * v[i];
                        i = i + 1.0;
                    }
                    row = row + 1.0;
                }
            }
        }
        k = k + 1.0;
    }

    free(v);

    // Clean numerical noise below diagonal in R
    var row_r = 0.0;
    while (row_r < m) {
        var col_r = 0.0;
        while (col_r < row_r && col_r < n) {
            out_R.data[row_r * n + col_r] = 0.0;
            col_r = col_r + 1.0;
        }
        row_r = row_r + 1.0;
    }
}

// Computes eigenvalues and eigenvectors of a real symmetric matrix via Jacobi rotation method
fn alg_mat_symmetric_eigenvalues(A: AlgMat, out_evals: ptr, out_evecs: AlgMat) {
    let n = A.rows;

    // Working symmetric copy S = 0.5 * (A + A^T)
    let S = alg_mat_create(n, n);
    var i = 0.0;
    while (i < n) {
        var j = 0.0;
        while (j < n) {
            let val = 0.5 * (A.data[i * n + j] + A.data[j * n + i]);
            S.data[i * n + j] = val;
            var init_v = 0.0;
            if (i == j) {
                init_v = 1.0;
            }
            out_evecs.data[i * n + j] = init_v;
            j = j + 1.0;
        }
        i = i + 1.0;
    }

    var sweep = 0.0;
    var changed = 1.0;

    while (sweep < 50.0 && changed == 1.0) {
        changed = 0.0;
        var p = 0.0;
        while (p < n - 1.0) {
            var q = p + 1.0;
            while (q < n) {
                let apq = S.data[p * n + q];
                if (fabs(apq) > 0.000000000001) { // 1e-12
                    changed = 1.0;
                    let app = S.data[p * n + p];
                    let aqq = S.data[q * n + q];
                    let tau = (aqq - app) / (2.0 * apq);
                    var t = -1.0 / (-tau + sqrt(1.0 + tau * tau));
                    if (tau >= 0.0) {
                        t = 1.0 / (tau + sqrt(1.0 + tau * tau));
                    }

                    let c = 1.0 / sqrt(1.0 + t * t);
                    let s = t * c;

                    // Update S diagonal
                    S.data[p * n + p] = app - t * apq;
                    S.data[q * n + q] = aqq + t * apq;
                    S.data[p * n + q] = 0.0;
                    S.data[q * n + p] = 0.0;

                    // Update S off-diagonals
                    var k = 0.0;
                    while (k < n) {
                        if (k != p && k != q) {
                            let akp = S.data[k * n + p];
                            let akq = S.data[k * n + q];
                            let new_kp = c * akp - s * akq;
                            let new_kq = s * akp + c * akq;
                            S.data[k * n + p] = new_kp;
                            S.data[p * n + k] = new_kp;
                            S.data[k * n + q] = new_kq;
                            S.data[q * n + k] = new_kq;
                        }
                        k = k + 1.0;
                    }

                    // Update Eigenvectors matrix V
                    var r = 0.0;
                    while (r < n) {
                        let vrp = out_evecs.data[r * n + p];
                        let vrq = out_evecs.data[r * n + q];
                        out_evecs.data[r * n + p] = c * vrp - s * vrq;
                        out_evecs.data[r * n + q] = s * vrp + c * vrq;
                        r = r + 1.0;
                    }
                }
                q = q + 1.0;
            }
            p = p + 1.0;
        }
        sweep = sweep + 1.0;
    }

    // Extract eigenvalues from S diagonal
    i = 0.0;
    while (i < n) {
        out_evals[i] = S.data[i * n + i];
        i = i + 1.0;
    }

    alg_mat_free(S);
}

// Returns the raw float buffer pointer of a matrix
fn alg_mat_data(m: AlgMat) -> ptr {
    return m.data;
}

// Matrix Exponential exp(A) via Higham Scaling and Squaring with 12-term Taylor series
fn alg_mat_exp(A: AlgMat, order: float) -> AlgMat {
    let n = A.rows;

    // 1. Compute infinity norm ||A||_inf = max_i sum_j |A_ij|
    var norm_inf = 0.0;
    var i = 0.0;
    while (i < n) {
        var row_sum = 0.0;
        var j = 0.0;
        while (j < n) {
            row_sum = row_sum + fabs(A.data[i * n + j]);
            j = j + 1.0;
        }
        if (row_sum > norm_inf) {
            norm_inf = row_sum;
        }
        i = i + 1.0;
    }

    // 2. Determine scaling factor s such that ||A / 2^s|| <= 0.5
    var s = 0.0;
    var scaled_norm = norm_inf;
    while (scaled_norm > 0.5) {
        scaled_norm = scaled_norm * 0.5;
        s = s + 1.0;
    }

    let scale_factor = pow(2.0, s);
    let A_scaled = alg_mat_create(n, n);
    var idx = 0.0;
    while (idx < n * n) {
        A_scaled.data[idx] = A.data[idx] / scale_factor;
        idx = idx + 1.0;
    }

    // 3. Compute Taylor series for exp(A_scaled): sum_{k=0}^{order} (A_scaled)^k / k!
    var series_terms = order;
    if (series_terms <= 0.0) { series_terms = 12.0; }

    var E = alg_mat_identity(n);
    var cur_pow = alg_mat_identity(n);
    var factorial = 1.0;

    var k = 1.0;
    while (k <= series_terms) {
        factorial = factorial * k;
        let next_pow = alg_mat_mul(cur_pow, A_scaled);
        alg_mat_free(cur_pow);
        cur_pow = next_pow;

        let cur_data = alg_mat_data(cur_pow);
        let e_data = alg_mat_data(E);

        // E = E + (1 / k!) * cur_pow
        var el = 0.0;
        while (el < n * n) {
            e_data[el] = e_data[el] + cur_data[el] / factorial;
            el = el + 1.0;
        }

        k = k + 1.0;
    }

    alg_mat_free(cur_pow);
    alg_mat_free(A_scaled);

    // 4. Repeated squaring s times
    var sq = 0.0;
    while (sq < s) {
        let E_next = alg_mat_mul(E, E);
        alg_mat_free(E);
        E = E_next;
        sq = sq + 1.0;
    }

    return E;
}

// ============================================================================
// Symmetric Algebra S(V), Quadratic Forms & Symplectic Geometry
// ============================================================================

// Matrix Symmetrization: A_sym = 0.5 * (A + A^T)
fn alg_mat_symmetrize(A: AlgMat) -> AlgMat {
    let n = A.rows;
    let out = alg_mat_create(n, n);
    var r = 0.0;
    while (r < n) {
        var c = 0.0;
        while (c < n) {
            let val = 0.5 * (A.data[r * n + c] + A.data[c * n + r]);
            out.data[r * n + c] = val;
            c = c + 1.0;
        }
        r = r + 1.0;
    }
    return out;
}

// Quadratic Form Evaluation: Q(v) = v^T * A * v
fn alg_quadratic_form(A: AlgMat, v: ptr) -> float {
    let n = A.rows;
    var sum = 0.0;
    var i = 0.0;
    while (i < n) {
        let vi = v[i];
        var j = 0.0;
        while (j < n) {
            sum = sum + vi * A.data[i * n + j] * v[j];
            j = j + 1.0;
        }
        i = i + 1.0;
    }
    return sum;
}

// Bilinear Form Evaluation: B(u, v) = u^T * A * v
fn alg_bilinear_form(A: AlgMat, u: ptr, v: ptr) -> float {
    let n = A.rows;
    var sum = 0.0;
    var i = 0.0;
    while (i < n) {
        let ui = u[i];
        var j = 0.0;
        while (j < n) {
            sum = sum + ui * A.data[i * n + j] * v[j];
            j = j + 1.0;
        }
        i = i + 1.0;
    }
    return sum;
}

// Computes Sylvester Metric Signature (p, q, r): positive, negative, and null/degenerate dimensions
fn alg_sylvester_signature(A: AlgMat, out_sig: ptr) {
    let n = A.rows;
    let evals = calloc(n, 8.0);
    let evecs = alg_mat_create(n, n);

    alg_mat_symmetric_eigenvalues(A, evals, evecs);

    var pos = 0.0;
    var neg = 0.0;
    var zero_dim = 0.0;

    var i = 0.0;
    while (i < n) {
        let ev = evals[i];
        if (ev > 0.000000001) {       // > 1e-9: Positive definite
            pos = pos + 1.0;
        } else if (ev < -0.000000001) { // < -1e-9: Negative definite
            neg = neg + 1.0;
        } else {                       // Null / degenerate
            zero_dim = zero_dim + 1.0;
        }
        i = i + 1.0;
    }

    out_sig[0] = pos;
    out_sig[1] = neg;
    out_sig[2] = zero_dim;

    free(evals);
    alg_mat_free(evecs);
}

// Constructs the 2N x 2N canonical Symplectic matrix J = [[0, I], [-I, 0]]
fn alg_symplectic_matrix(n: float) -> AlgMat {
    let dim = n * 2.0;
    let J = alg_mat_create(dim, dim);

    var i = 0.0;
    while (i < n) {
        // Upper-right block: J[i, n + i] = 1.0
        J.data[i * dim + (n + i)] = 1.0;
        // Lower-left block: J[n + i, i] = -1.0
        J.data[(n + i) * dim + i] = -1.0;
        i = i + 1.0;
    }

    return J;
}

// ============================================================================
// Matrix <-> Tensor Bridge Adapters
// ============================================================================

// Converts a 2D AlgMat to a 2D AlgTensor
fn alg_mat_to_tensor(m: AlgMat) -> AlgTensor {
    let sh = calloc(2.0, 8.0);
    sh[0] = m.rows;
    sh[1] = m.cols;
    let t = alg_tensor_create(sh, 2.0);
    free(sh);

    var i = 0.0;
    let total = m.rows * m.cols;
    while (i < total) {
        t.data[i] = m.data[i];
        i = i + 1.0;
    }
    return t;
}

// Converts a 2D AlgTensor to an AlgMat
fn alg_tensor_to_mat(t: AlgTensor) -> AlgMat {
    if (t.ndim != 2.0) {
        return AlgMat { rows: 0.0, cols: 0.0, data: 0.0 };
    }
    let rows = t.shape[0];
    let cols = t.shape[1];
    let m = alg_mat_create(rows, cols);

    var i = 0.0;
    let total = rows * cols;
    while (i < total) {
        m.data[i] = t.data[i];
        i = i + 1.0;
    }
    return m;
}
