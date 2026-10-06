// src/std/algebra/abstract.cl
// CARTAN Standard Library: Unified Algebraic Architecture
// Pillar 4: Abstract, Jordan, Tropical, Boolean & Universal Algebras
// Named in honor of Élie Cartan (1869–1951)

include "src/std/algebra/tensor.cl";

// -----------------------------------------------------------------------------
// Bitwise Arithmetic Helpers for Multi-Word BitVectors
// Emulates bit operations on 32-bit words using double-precision registers
// -----------------------------------------------------------------------------

fn alg_word_pow2(n: float) -> float {
    var r = 1.0;
    var i = 0.0;
    while (i < n) {
        r = r * 2.0;
        i = i + 1.0;
    }
    return r;
}

fn alg_word_and(w1: float, w2: float) -> float {
    var a = w1;
    var b = w2;
    var p = 1.0;
    var res = 0.0;
    while (a > 0.0 || b > 0.0) {
        var bit_a = fmod(a, 2.0);
        var bit_b = fmod(b, 2.0);
        if (bit_a >= 1.0 && bit_b >= 1.0) {
            res = res + p;
        }
        a = floor(a * 0.5);
        b = floor(b * 0.5);
        p = p * 2.0;
    }
    return res;
}

fn alg_word_or(w1: float, w2: float) -> float {
    var a = w1;
    var b = w2;
    var p = 1.0;
    var res = 0.0;
    while (a > 0.0 || b > 0.0) {
        var bit_a = fmod(a, 2.0);
        var bit_b = fmod(b, 2.0);
        if (bit_a >= 1.0 || bit_b >= 1.0) {
            res = res + p;
        }
        a = floor(a * 0.5);
        b = floor(b * 0.5);
        p = p * 2.0;
    }
    return res;
}

fn alg_word_xor(w1: float, w2: float) -> float {
    var a = w1;
    var b = w2;
    var p = 1.0;
    var res = 0.0;
    while (a > 0.0 || b > 0.0) {
        var bit_a = fmod(a, 2.0);
        var bit_b = fmod(b, 2.0);
        if ((bit_a >= 1.0 && bit_b < 1.0) || (bit_a < 1.0 && bit_b >= 1.0)) {
            res = res + p;
        }
        a = floor(a * 0.5);
        b = floor(b * 0.5);
        p = p * 2.0;
    }
    return res;
}

fn alg_word_popcount(w: float) -> float {
    var rem = w;
    var cnt = 0.0;
    while (rem > 0.0) {
        if (fmod(rem, 2.0) >= 1.0) {
            cnt = cnt + 1.0;
        }
        rem = floor(rem * 0.5);
    }
    return cnt;
}

// =============================================================================
// SECTION 1: Jordan Algebras
// Non-associative commutative algebras satisfying (x . y) . x^2 = x . (y . x^2)
// =============================================================================

// Matrix Jordan Product: A o B = 0.5 * (A * B + B * A)
fn alg_jordan_mat_mul(a: AlgMat, b: AlgMat) -> AlgMat {
    let ab = alg_mat_mul(a, b);
    let ba = alg_mat_mul(b, a);
    let sum_mat = alg_mat_add(ab, ba);
    let res = alg_mat_scale(sum_mat, 0.5);
    alg_mat_free(ab);
    alg_mat_free(ba);
    alg_mat_free(sum_mat);
    return res;
}

// Jordan Triple Product: {A, B, C} = (A o B) o C + (C o B) o A - (A o C) o B
fn alg_jordan_mat_triple(a: AlgMat, b: AlgMat, c: AlgMat) -> AlgMat {
    let ab = alg_jordan_mat_mul(a, b);
    let ab_c = alg_jordan_mat_mul(ab, c);
    alg_mat_free(ab);

    let cb = alg_jordan_mat_mul(c, b);
    let cb_a = alg_jordan_mat_mul(cb, a);
    alg_mat_free(cb);

    let ac = alg_jordan_mat_mul(a, c);
    let ac_b = alg_jordan_mat_mul(ac, b);
    alg_mat_free(ac);

    let sum1 = alg_mat_add(ab_c, cb_a);
    let res = alg_mat_sub(sum1, ac_b);
    alg_mat_free(ab_c);
    alg_mat_free(cb_a);
    alg_mat_free(ac_b);
    alg_mat_free(sum1);
    return res;
}

// Quadratic Jordan Operator: U_A(B) = 2 * A o (A o B) - A^2 o B == A * B * A
fn alg_jordan_mat_quadratic(a: AlgMat, b: AlgMat) -> AlgMat {
    let ab = alg_jordan_mat_mul(a, b);
    let a_ab = alg_jordan_mat_mul(a, ab);
    alg_mat_free(ab);

    let term1 = alg_mat_scale(a_ab, 2.0);
    alg_mat_free(a_ab);

    let a2 = alg_mat_mul(a, a);
    let term2 = alg_jordan_mat_mul(a2, b);
    alg_mat_free(a2);

    let res = alg_mat_sub(term1, term2);
    alg_mat_free(term1);
    alg_mat_free(term2);
    return res;
}

// Verifies the Jordan identity: (A o B) o A^2 == A o (B o A^2)
fn alg_jordan_mat_identity_check(a: AlgMat, b: AlgMat) -> float {
    let a2 = alg_mat_mul(a, a);

    // Left side: (A o B) o A^2
    let ab = alg_jordan_mat_mul(a, b);
    let lhs = alg_jordan_mat_mul(ab, a2);
    alg_mat_free(ab);

    // Right side: A o (B o A^2)
    let ba2 = alg_jordan_mat_mul(b, a2);
    let rhs = alg_jordan_mat_mul(a, ba2);
    alg_mat_free(ba2);
    alg_mat_free(a2);

    // Compute Frobenius residual ||lhs - rhs||
    var rows = alg_mat_rows(lhs);
    var cols = alg_mat_cols(lhs);
    var r = 0.0;
    var max_diff = 0.0;
    while (r < rows) {
        var c = 0.0;
        while (c < cols) {
            var diff = fabs(alg_mat_get(lhs, r, c) - alg_mat_get(rhs, r, c));
            if (diff > max_diff) {
                max_diff = diff;
            }
            c = c + 1.0;
        }
        r = r + 1.0;
    }
    alg_mat_free(lhs);
    alg_mat_free(rhs);

    if (max_diff < 0.0000001) {
        return 1.0;
    }
    return 0.0;
}

// Formal Finite-Dimensional Jordan Algebra
struct AlgJordanAlgebra {
    dim: float;
    constants: ptr;
}

fn alg_jordan_dim(j: AlgJordanAlgebra) -> float { return j.dim; }
fn alg_jordan_constants(j: AlgJordanAlgebra) -> ptr { return j.constants; }

fn alg_jordan_create(d: float) -> AlgJordanAlgebra {
    var total_entries = d * d * d;
    var p = calloc(total_entries, 8.0);
    let ja = AlgJordanAlgebra {
        dim: d,
        constants: p
    };
    return ja;
}

fn alg_jordan_free(j: AlgJordanAlgebra) -> float {
    var p = alg_jordan_constants(j);
    if (p != 0.0) {
        free(p);
    }
    return 0.0;
}

fn alg_jordan_set_constant(j: AlgJordanAlgebra, i: float, j_idx: float, k: float, v: float) -> float {
    var d = alg_jordan_dim(j);
    var p = alg_jordan_constants(j);
    var idx1 = (i * d + j_idx) * d + k;
    var idx2 = (j_idx * d + i) * d + k;
    p[idx1] = v;
    p[idx2] = v; // Commutativity enforcement: x o y = y o x
    return 0.0;
}

fn alg_jordan_get_constant(j: AlgJordanAlgebra, i: float, j_idx: float, k: float) -> float {
    var d = alg_jordan_dim(j);
    var p = alg_jordan_constants(j);
    var idx = (i * d + j_idx) * d + k;
    return p[idx];
}

// Vector Jordan product: w = u o v = sum_{i,j,k} u_i v_j J_{ij}^k e_k
fn alg_jordan_product(j: AlgJordanAlgebra, u: ptr, v: ptr) -> ptr {
    var d = alg_jordan_dim(j);
    var res = calloc(d, 8.0);
    var i = 0.0;
    while (i < d) {
        var u_i = u[i];
        if (fabs(u_i) > 0.0000000001) {
            var j_idx = 0.0;
            while (j_idx < d) {
                var v_j = v[j_idx];
                if (fabs(v_j) > 0.0000000001) {
                    var factor = u_i * v_j;
                    var k = 0.0;
                    while (k < d) {
                        var c = alg_jordan_get_constant(j, i, j_idx, k);
                        if (fabs(c) > 0.0000000001) {
                            res[k] = res[k] + factor * c;
                        }
                        k = k + 1.0;
                    }
                }
                j_idx = j_idx + 1.0;
            }
        }
        i = i + 1.0;
    }
    return res;
}

// Verifies Jordan identity across all basis element pairs: (e_i o e_j) o e_i^2 == e_i o (e_j o e_i^2)
fn alg_jordan_identity_check(j: AlgJordanAlgebra) -> float {
    var d = alg_jordan_dim(j);

    var e_i = calloc(d, 8.0);
    var e_j = calloc(d, 8.0);

    var i = 0.0;
    while (i < d) {
        // Build e_i
        var k = 0.0;
        while (k < d) {
            e_i[k] = 0.0;
            k = k + 1.0;
        }
        e_i[i] = 1.0;

        // e_i^2 = e_i o e_i
        var ei2 = alg_jordan_product(j, e_i, e_i);

        var j_idx = 0.0;
        while (j_idx < d) {
            // Build e_j
            k = 0.0;
            while (k < d) {
                e_j[k] = 0.0;
                k = k + 1.0;
            }
            e_j[j_idx] = 1.0;

            // Left side: (e_i o e_j) o e_i^2
            var ei_ej = alg_jordan_product(j, e_i, e_j);
            var lhs = alg_jordan_product(j, ei_ej, ei2);
            free(ei_ej);

            // Right side: e_i o (e_j o e_i^2)
            var ej_ei2 = alg_jordan_product(j, e_j, ei2);
            var rhs = alg_jordan_product(j, e_i, ej_ei2);
            free(ej_ei2);

            // Compare lhs and rhs
            k = 0.0;
            while (k < d) {
                var diff = fabs(lhs[k] - rhs[k]);
                if (diff > 0.00001) {
                    free(lhs);
                    free(rhs);
                    free(ei2);
                    free(e_i);
                    free(e_j);
                    return 0.0; // Violation
                }
                k = k + 1.0;
            }
            free(lhs);
            free(rhs);

            j_idx = j_idx + 1.0;
        }
        free(ei2);
        i = i + 1.0;
    }
    free(e_i);
    free(e_j);
    return 1.0; // All basis pairs satisfy Jordan identity
}

// =============================================================================
// SECTION 2: Tropical Semirings (Min-Plus & Max-Plus)
// Additive idempotence (x + x = x) and path optimization over semirings
// =============================================================================

// Tropical Constants
fn alg_tropical_inf() -> float { return 1000000000000000.0; }       // 1.0e15 (additive zero for Min-Plus)
fn alg_tropical_neg_inf() -> float { return -1000000000000000.0; }  // -1.0e15 (additive zero for Max-Plus)
fn alg_tropical_threshold() -> float { return 100000000000000.0; }  // 1.0e14 (absorbing clamp)
fn alg_tropical_zero() -> float { return 0.0; }                     // Multiplicative identity

// Min-Plus Addition: a (+) b = min(a, b)
fn alg_tropical_min_add(a: float, b: float) -> float {
    if (a < b) {
        return a;
    }
    return b;
}

// Min-Plus Multiplication: a (*) b = a + b with absorbing sentinel clamp
fn alg_tropical_min_mul(a: float, b: float) -> float {
    var thresh = alg_tropical_threshold();
    if (a >= thresh || b >= thresh) {
        return alg_tropical_inf();
    }
    return a + b;
}

// Max-Plus Addition: a (+) b = max(a, b)
fn alg_tropical_max_add(a: float, b: float) -> float {
    if (a > b) {
        return a;
    }
    return b;
}

// Max-Plus Multiplication: a (*) b = a + b with absorbing sentinel clamp
fn alg_tropical_max_mul(a: float, b: float) -> float {
    var thresh = alg_tropical_threshold();
    if (a <= -thresh || b <= -thresh) {
        return alg_tropical_neg_inf();
    }
    return a + b;
}

// Tropical Matrix Creation initialized to Min-Plus Infinity
fn alg_tropical_mat_create_inf(rows: float, cols: float) -> AlgMat {
    let m = alg_mat_create(rows, cols);
    var inf_val = alg_tropical_inf();
    var r = 0.0;
    while (r < rows) {
        var c = 0.0;
        while (c < cols) {
            alg_mat_set(m, r, c, inf_val);
            c = c + 1.0;
        }
        r = r + 1.0;
    }
    return m;
}

// Tropical Identity Matrix: 0.0 on diagonal, +Inf on off-diagonal
fn alg_tropical_mat_identity(n: float) -> AlgMat {
    let m = alg_mat_create(n, n);
    var inf_val = alg_tropical_inf();
    var r = 0.0;
    while (r < n) {
        var c = 0.0;
        while (c < n) {
            if (r == c) {
                alg_mat_set(m, r, c, 0.0);
            } else {
                alg_mat_set(m, r, c, inf_val);
            }
            c = c + 1.0;
        }
        r = r + 1.0;
    }
    return m;
}

// Tropical Min-Plus Matrix Multiplication: (A o B)_{ij} = min_k (A_{ik} + B_{kj})
fn alg_tropical_min_mat_mul(a: AlgMat, b: AlgMat) -> AlgMat {
    var r1 = alg_mat_rows(a);
    var c1 = alg_mat_cols(a);
    var c2 = alg_mat_cols(b);

    let res = alg_mat_create(r1, c2);
    var i = 0.0;
    while (i < r1) {
        var j = 0.0;
        while (j < c2) {
            var min_val = alg_tropical_inf();
            var k = 0.0;
            while (k < c1) {
                var term = alg_tropical_min_mul(alg_mat_get(a, i, k), alg_mat_get(b, k, j));
                min_val = alg_tropical_min_add(min_val, term);
                k = k + 1.0;
            }
            alg_mat_set(res, i, j, min_val);
            j = j + 1.0;
        }
        i = i + 1.0;
    }
    return res;
}

// Tropical Max-Plus Matrix Multiplication: (A o B)_{ij} = max_k (A_{ik} + B_{kj})
fn alg_tropical_max_mat_mul(a: AlgMat, b: AlgMat) -> AlgMat {
    var r1 = alg_mat_rows(a);
    var c1 = alg_mat_cols(a);
    var c2 = alg_mat_cols(b);

    let res = alg_mat_create(r1, c2);
    var i = 0.0;
    while (i < r1) {
        var j = 0.0;
        while (j < c2) {
            var max_val = alg_tropical_neg_inf();
            var k = 0.0;
            while (k < c1) {
                var term = alg_tropical_max_mul(alg_mat_get(a, i, k), alg_mat_get(b, k, j));
                max_val = alg_tropical_max_add(max_val, term);
                k = k + 1.0;
            }
            alg_mat_set(res, i, j, max_val);
            j = j + 1.0;
        }
        i = i + 1.0;
    }
    return res;
}

// Tropical Kleene Star Closure A* = I (+) A (+) A^2 (+) ... (+) A^{n-1}
// Solves all-pairs shortest paths via closed-semiring Floyd-Warshall (single allocation, zero intermediate leak)
fn alg_tropical_kleene_star(adj: AlgMat) -> AlgMat {
    var n = alg_mat_rows(adj);
    let res = alg_mat_clone(adj);

    // Enforce diagonal <= 0.0
    var i = 0.0;
    while (i < n) {
        var diag = alg_mat_get(res, i, i);
        if (diag > 0.0) {
            alg_mat_set(res, i, i, 0.0);
        }
        i = i + 1.0;
    }

    // Triple-nested Floyd-Warshall dynamic programming
    var k = 0.0;
    while (k < n) {
        i = 0.0;
        while (i < n) {
            var r_ik = alg_mat_get(res, i, k);
            if (r_ik < alg_tropical_threshold()) {
                var j = 0.0;
                while (j < n) {
                    var r_kj = alg_mat_get(res, k, j);
                    if (r_kj < alg_tropical_threshold()) {
                        var path_via_k = r_ik + r_kj;
                        var curr = alg_mat_get(res, i, j);
                        if (path_via_k < curr) {
                            alg_mat_set(res, i, j, path_via_k);
                        }
                    }
                    j = j + 1.0;
                }
            }
            i = i + 1.0;
        }
        k = k + 1.0;
    }
    return res;
}

// =============================================================================
// SECTION 3: Boolean Algebras, Stone Boolean Rings & BitVectors
// Lattice structure (meet, join, complement) isomorphic to Boolean Ring (XOR, AND)
// =============================================================================

// Scalar Boolean Lattice Operations
fn alg_bool_meet(a: float, b: float) -> float {
    if (a > 0.5 && b > 0.5) { return 1.0; }
    return 0.0;
}

fn alg_bool_join(a: float, b: float) -> float {
    if (a > 0.5 || b > 0.5) { return 1.0; }
    return 0.0;
}

fn alg_bool_not(a: float) -> float {
    if (a > 0.5) { return 0.0; }
    return 1.0;
}

// Stone Boolean Ring Isomorphism:
// Ring Addition: a + b = a XOR b = (a AND NOT b) OR (NOT a AND b)
fn alg_bool_ring_add(a: float, b: float) -> float {
    var bit_a = 0.0;
    var bit_b = 0.0;
    if (a > 0.5) { bit_a = 1.0; }
    if (b > 0.5) { bit_b = 1.0; }
    if (bit_a != bit_b) { return 1.0; }
    return 0.0;
}

// Ring Multiplication: a * b = a AND b
fn alg_bool_ring_mul(a: float, b: float) -> float {
    return alg_bool_meet(a, b);
}

// Arbitrary-Width BitVector Engine (using 32-bit exact chunks)
struct AlgBitVector {
    num_bits: float;
    num_words: float;
    data: ptr;
}

fn alg_bitvec_bits(bv: AlgBitVector) -> float { return bv.num_bits; }
fn alg_bitvec_words(bv: AlgBitVector) -> float { return bv.num_words; }
fn alg_bitvec_data(bv: AlgBitVector) -> ptr { return bv.data; }

fn alg_bitvec_create(n_bits: float) -> AlgBitVector {
    var n_words = ceil(n_bits / 32.0);
    if (n_words < 1.0) { n_words = 1.0; }
    var p = calloc(n_words, 8.0);
    let bv = AlgBitVector {
        num_bits: n_bits,
        num_words: n_words,
        data: p
    };
    return bv;
}

fn alg_bitvec_free(bv: AlgBitVector) -> float {
    var p = alg_bitvec_data(bv);
    if (p != 0.0) {
        free(p);
    }
    return 0.0;
}

fn alg_bitvec_set_bit(bv: AlgBitVector, idx: float, val: float) -> float {
    var n_bits = alg_bitvec_bits(bv);
    if (idx < 0.0 || idx >= n_bits) { return 0.0; }
    var w_idx = floor(idx / 32.0);
    var b_off = fmod(idx, 32.0);
    var p = alg_bitvec_data(bv);
    var curr_word = p[w_idx];
    var bit_mask = alg_word_pow2(b_off);

    var has_bit = alg_word_and(curr_word, bit_mask);
    if (val > 0.5) {
        if (has_bit < 0.5) {
            p[w_idx] = curr_word + bit_mask;
        }
    } else {
        if (has_bit > 0.5) {
            p[w_idx] = curr_word - bit_mask;
        }
    }
    return 0.0;
}

fn alg_bitvec_get_bit(bv: AlgBitVector, idx: float) -> float {
    var n_bits = alg_bitvec_bits(bv);
    if (idx < 0.0 || idx >= n_bits) { return 0.0; }
    var w_idx = floor(idx / 32.0);
    var b_off = fmod(idx, 32.0);
    var p = alg_bitvec_data(bv);
    var curr_word = p[w_idx];
    var bit_mask = alg_word_pow2(b_off);
    if (alg_word_and(curr_word, bit_mask) > 0.5) {
        return 1.0;
    }
    return 0.0;
}

fn alg_bitvec_and(a: AlgBitVector, b: AlgBitVector) -> AlgBitVector {
    var n_bits = alg_bitvec_bits(a);
    var n_words = alg_bitvec_words(a);
    let res = alg_bitvec_create(n_bits);
    var p_a = alg_bitvec_data(a);
    var p_b = alg_bitvec_data(b);
    var p_res = alg_bitvec_data(res);

    var i = 0.0;
    while (i < n_words) {
        var w_a = p_a[i];
        var w_b = p_b[i];
        p_res[i] = alg_word_and(w_a, w_b);
        i = i + 1.0;
    }
    return res;
}

fn alg_bitvec_or(a: AlgBitVector, b: AlgBitVector) -> AlgBitVector {
    var n_bits = alg_bitvec_bits(a);
    var n_words = alg_bitvec_words(a);
    let res = alg_bitvec_create(n_bits);
    var p_a = alg_bitvec_data(a);
    var p_b = alg_bitvec_data(b);
    var p_res = alg_bitvec_data(res);

    var i = 0.0;
    while (i < n_words) {
        var w_a = p_a[i];
        var w_b = p_b[i];
        p_res[i] = alg_word_or(w_a, w_b);
        i = i + 1.0;
    }
    return res;
}

fn alg_bitvec_xor(a: AlgBitVector, b: AlgBitVector) -> AlgBitVector {
    var n_bits = alg_bitvec_bits(a);
    var n_words = alg_bitvec_words(a);
    let res = alg_bitvec_create(n_bits);
    var p_a = alg_bitvec_data(a);
    var p_b = alg_bitvec_data(b);
    var p_res = alg_bitvec_data(res);

    var i = 0.0;
    while (i < n_words) {
        var w_a = p_a[i];
        var w_b = p_b[i];
        p_res[i] = alg_word_xor(w_a, w_b);
        i = i + 1.0;
    }
    return res;
}

fn alg_bitvec_not(a: AlgBitVector) -> AlgBitVector {
    var n_bits = alg_bitvec_bits(a);
    var n_words = alg_bitvec_words(a);
    let res = alg_bitvec_create(n_bits);
    var p_a = alg_bitvec_data(a);
    var p_res = alg_bitvec_data(res);
    var max_word = 4294967295.0; // 2^32 - 1

    var i = 0.0;
    while (i < n_words) {
        var w_a = p_a[i];
        p_res[i] = max_word - w_a;
        i = i + 1.0;
    }

    // Mask unused padding bits of the highest word
    var rem = fmod(n_bits, 32.0);
    if (rem > 0.0) {
        var mask = alg_word_pow2(rem) - 1.0;
        var last_idx = n_words - 1.0;
        var last_w = p_res[last_idx];
        p_res[last_idx] = alg_word_and(last_w, mask);
    }

    return res;
}

// Population count (Hamming weight) across all bits
fn alg_bitvec_popcount(bv: AlgBitVector) -> float {
    var n_words = alg_bitvec_words(bv);
    var p = alg_bitvec_data(bv);
    var total = 0.0;
    var i = 0.0;
    while (i < n_words) {
        var w = p[i];
        total = total + alg_word_popcount(w);
        i = i + 1.0;
    }
    return total;
}

// Hamming metric: dist(u, v) = popcount(u XOR v)
fn alg_bitvec_hamming_dist(a: AlgBitVector, b: AlgBitVector) -> float {
    let xor_bv = alg_bitvec_xor(a, b);
    var d = alg_bitvec_popcount(xor_bv);
    alg_bitvec_free(xor_bv);
    return d;
}

// Lattice subset ordering: a <= b iff a AND b == a
fn alg_bitvec_is_subset(a: AlgBitVector, b: AlgBitVector) -> float {
    var n_words = alg_bitvec_words(a);
    var p_a = alg_bitvec_data(a);
    var p_b = alg_bitvec_data(b);
    var i = 0.0;
    while (i < n_words) {
        var w_a = p_a[i];
        var w_b = p_b[i];
        var meet_w = alg_word_and(w_a, w_b);
        if (meet_w != w_a) {
            return 0.0; // Subset violation
        }
        i = i + 1.0;
    }
    return 1.0; // a <= b holds everywhere
}

// =============================================================================
// SECTION 4: Universal Algebra & General Structural Taxonomy
// Cayley operation tables, axiomatic taxonomy (Magma -> Field), and homomorphisms
// =============================================================================

struct AlgCayleyTable {
    size: float;
    table: ptr;
}

fn alg_cayley_size(ct: AlgCayleyTable) -> float { return ct.size; }
fn alg_cayley_table(ct: AlgCayleyTable) -> ptr { return ct.table; }

fn alg_cayley_create(n: float) -> AlgCayleyTable {
    var p = calloc(n * n, 8.0);
    let ct = AlgCayleyTable {
        size: n,
        table: p
    };
    return ct;
}

fn alg_cayley_free(ct: AlgCayleyTable) -> float {
    var p = alg_cayley_table(ct);
    if (p != 0.0) {
        free(p);
    }
    return 0.0;
}

fn alg_cayley_set(ct: AlgCayleyTable, a: float, b: float, res: float) -> float {
    var n = alg_cayley_size(ct);
    var p = alg_cayley_table(ct);
    var idx = a * n + b;
    p[idx] = res;
    return 0.0;
}

fn alg_cayley_get(ct: AlgCayleyTable, a: float, b: float) -> float {
    var n = alg_cayley_size(ct);
    var p = alg_cayley_table(ct);
    var idx = a * n + b;
    return p[idx];
}

// Verifies closure: forall a, b in S, T(a, b) in S
fn alg_cayley_is_closed(ct: AlgCayleyTable) -> float {
    var n = alg_cayley_size(ct);
    var a = 0.0;
    while (a < n) {
        var b = 0.0;
        while (b < n) {
            var v = alg_cayley_get(ct, a, b);
            if (v < 0.0 || v >= n || floor(v) != v) {
                return 0.0;
            }
            b = b + 1.0;
        }
        a = a + 1.0;
    }
    return 1.0;
}

// Verifies associativity: forall a, b, c in S, T(T(a, b), c) == T(a, T(b, c))
fn alg_cayley_is_associative(ct: AlgCayleyTable) -> float {
    var n = alg_cayley_size(ct);
    var a = 0.0;
    while (a < n) {
        var b = 0.0;
        while (b < n) {
            var ab = alg_cayley_get(ct, a, b);
            var c = 0.0;
            while (c < n) {
                var bc = alg_cayley_get(ct, b, c);
                var lhs = alg_cayley_get(ct, ab, c);
                var rhs = alg_cayley_get(ct, a, bc);
                if (lhs != rhs) {
                    return 0.0;
                }
                c = c + 1.0;
            }
            b = b + 1.0;
        }
        a = a + 1.0;
    }
    return 1.0;
}

// Searches for a two-sided neutral element e in S such that e * a = a * e = a
fn alg_cayley_find_identity(ct: AlgCayleyTable) -> float {
    var n = alg_cayley_size(ct);
    var cand = 0.0;
    while (cand < n) {
        var is_id = 1.0;
        var a = 0.0;
        while (a < n) {
            var left = alg_cayley_get(ct, cand, a);
            var right = alg_cayley_get(ct, a, cand);
            if (left != a || right != a) {
                is_id = 0.0;
            }
            a = a + 1.0;
        }
        if (is_id > 0.5) {
            return cand; // Found unique identity element
        }
        cand = cand + 1.0;
    }
    return -1.0; // No identity
}

// Verifies that every element a in S has a two-sided inverse a^{-1}
fn alg_cayley_has_inverses(ct: AlgCayleyTable, id_elem: float) -> float {
    if (id_elem < 0.0) { return 0.0; }
    var n = alg_cayley_size(ct);
    var a = 0.0;
    while (a < n) {
        var has_inv = 0.0;
        var b = 0.0;
        while (b < n) {
            var left = alg_cayley_get(ct, a, b);
            var right = alg_cayley_get(ct, b, a);
            if (left == id_elem && right == id_elem) {
                has_inv = 1.0;
            }
            b = b + 1.0;
        }
        if (has_inv < 0.5) {
            return 0.0;
        }
        a = a + 1.0;
    }
    return 1.0;
}

// Verifies commutativity: forall a, b in S, T(a, b) == T(b, a)
fn alg_cayley_is_commutative(ct: AlgCayleyTable) -> float {
    var n = alg_cayley_size(ct);
    var a = 0.0;
    while (a < n) {
        var b = a + 1.0;
        while (b < n) {
            var ab = alg_cayley_get(ct, a, b);
            var ba = alg_cayley_get(ct, b, a);
            if (ab != ba) {
                return 0.0;
            }
            b = b + 1.0;
        }
        a = a + 1.0;
    }
    return 1.0;
}

// Verifies distributivity of multiplication over addition:
// a * (b + c) = (a * b) + (a * c) AND (b + c) * a = (b * a) + (c * a)
fn alg_cayley_is_distributive(add_ct: AlgCayleyTable, mul_ct: AlgCayleyTable) -> float {
    var n = alg_cayley_size(add_ct);
    var a = 0.0;
    while (a < n) {
        var b = 0.0;
        while (b < n) {
            var c = 0.0;
            while (c < n) {
                var b_plus_c = alg_cayley_get(add_ct, b, c);

                // Left distributivity: a * (b + c) == (a * b) + (a * c)
                var lhs_left = alg_cayley_get(mul_ct, a, b_plus_c);
                var ab = alg_cayley_get(mul_ct, a, b);
                var ac = alg_cayley_get(mul_ct, a, c);
                var rhs_left = alg_cayley_get(add_ct, ab, ac);
                if (lhs_left != rhs_left) {
                    return 0.0;
                }

                // Right distributivity: (b + c) * a == (b * a) + (c * a)
                var lhs_right = alg_cayley_get(mul_ct, b_plus_c, a);
                var ba = alg_cayley_get(mul_ct, b, a);
                var ca = alg_cayley_get(mul_ct, c, a);
                var rhs_right = alg_cayley_get(add_ct, ba, ca);
                if (lhs_right != rhs_right) {
                    return 0.0;
                }

                c = c + 1.0;
            }
            b = b + 1.0;
        }
        a = a + 1.0;
    }
    return 1.0;
}

// Full Universal Classification Pipeline for a Single Binary Operation:
// 0.0 = Not a magma (unclosed)
// 1.0 = Magma (closed)
// 2.0 = Semigroup (associative magma)
// 3.0 = Monoid (semigroup + identity)
// 4.0 = Group (monoid + inverses)
// 5.0 = Abelian Group (group + commutativity)
fn alg_cayley_classify(ct: AlgCayleyTable) -> float {
    if (alg_cayley_is_closed(ct) < 0.5) {
        return 0.0;
    }
    if (alg_cayley_is_associative(ct) < 0.5) {
        return 1.0; // Magma
    }
    var id_elem = alg_cayley_find_identity(ct);
    if (id_elem < 0.0) {
        return 2.0; // Semigroup
    }
    if (alg_cayley_has_inverses(ct, id_elem) < 0.5) {
        return 3.0; // Monoid
    }
    if (alg_cayley_is_commutative(ct) < 0.5) {
        return 4.0; // Group (non-abelian)
    }
    return 5.0; // Abelian Group
}

// Verifies whether (S, +, *) is a Ring (with identity 1)
fn alg_cayley_is_ring(add_ct: AlgCayleyTable, mul_ct: AlgCayleyTable) -> float {
    // (S, +) must be an abelian group (classification == 5.0)
    if (alg_cayley_classify(add_ct) < 4.5) {
        return 0.0;
    }
    // (S, *) must be at least a monoid (classification >= 3.0)
    if (alg_cayley_classify(mul_ct) < 2.5) {
        return 0.0;
    }
    // Multiplication must distribute over addition
    if (alg_cayley_is_distributive(add_ct, mul_ct) < 0.5) {
        return 0.0;
    }
    return 1.0;
}

// Verifies whether (S, +, *) is a Field (commutative division ring)
fn alg_cayley_is_field(add_ct: AlgCayleyTable, mul_ct: AlgCayleyTable) -> float {
    if (alg_cayley_is_ring(add_ct, mul_ct) < 0.5) {
        return 0.0;
    }
    // Multiplication must be commutative
    if (alg_cayley_is_commutative(mul_ct) < 0.5) {
        return 0.0;
    }

    // Additive zero element
    var zero_elem = alg_cayley_find_identity(add_ct);
    var one_elem = alg_cayley_find_identity(mul_ct);
    if (zero_elem == one_elem) {
        return 0.0; // Non-trivial field requires 0 != 1
    }

    // Every non-zero element must have a multiplicative inverse
    var n = alg_cayley_size(mul_ct);
    var a = 0.0;
    while (a < n) {
        if (a != zero_elem) {
            var has_inv = 0.0;
            var b = 0.0;
            while (b < n) {
                if (alg_cayley_get(mul_ct, a, b) == one_elem) {
                    has_inv = 1.0;
                }
                b = b + 1.0;
            }
            if (has_inv < 0.5) {
                return 0.0;
            }
        }
        a = a + 1.0;
    }
    return 1.0;
}

// Universal Homomorphism Verifier: phi(a * b) == phi(a) . phi(b)
fn alg_cayley_is_homomorphism(ct1: AlgCayleyTable, ct2: AlgCayleyTable, phi_map: ptr) -> float {
    var n1 = alg_cayley_size(ct1);
    var a = 0.0;
    while (a < n1) {
        var phi_a = phi_map[a];
        var b = 0.0;
        while (b < n1) {
            var phi_b = phi_map[b];
            var prod_ab = alg_cayley_get(ct1, a, b);
            var phi_prod_ab = phi_map[prod_ab];
            var target_prod = alg_cayley_get(ct2, phi_a, phi_b);
            if (phi_prod_ab != target_prod) {
                return 0.0; // Homomorphism failure
            }
            b = b + 1.0;
        }
        a = a + 1.0;
    }
    return 1.0;
}
