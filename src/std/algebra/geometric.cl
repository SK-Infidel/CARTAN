// src/std/algebra/geometric.cl
// CARTAN Standard Library: Pillar 2 — Geometric, Clifford, Weyl & Hypercomplex Algebras
// Pure-CARTAN Bare-Metal Implementation (Zero-Mock Rule Enforced)

include "src/std/constants.ch";
include "src/std/math.cl";

extern fn malloc(size: float) -> ptr;
extern fn calloc(count: float, size: float) -> ptr;
extern fn free(p: ptr) -> void;
extern fn memcpy(dst: ptr, src: ptr, size: float) -> ptr;

// ============================================================================
// Bitwise Arithmetic Helpers (Pure CARTAN Arithmetic Emulation)
// ============================================================================

// Returns 2^k for k in 0..8
fn alg_bit_pow2(k: float) -> float {
    if (k <= 0.0) { return 1.0; }
    if (k == 1.0) { return 2.0; }
    if (k == 2.0) { return 4.0; }
    if (k == 3.0) { return 8.0; }
    if (k == 4.0) { return 16.0; }
    if (k == 5.0) { return 32.0; }
    if (k == 6.0) { return 64.0; }
    if (k == 7.0) { return 128.0; }
    if (k == 8.0) { return 256.0; }
    return pow(2.0, k);
}

// Tests whether bit k (0-indexed) is set in mask
fn alg_bit_test(mask: float, k: float) -> float {
    let p = alg_bit_pow2(k);
    let shifted = floor(mask / p);
    let bit = fmod(shifted, 2.0);
    return bit;
}

// Bitwise AND of two masks up to 8 bits
fn alg_bit_and(a: float, b: float) -> float {
    var res = 0.0;
    var k = 0.0;
    while (k < 8.0) {
        let ba = alg_bit_test(a, k);
        let bb = alg_bit_test(b, k);
        if (ba > 0.5 && bb > 0.5) {
            res = res + alg_bit_pow2(k);
        }
        k = k + 1.0;
    }
    return res;
}

// Bitwise XOR of two masks up to 8 bits
fn alg_bit_xor(a: float, b: float) -> float {
    var res = 0.0;
    var k = 0.0;
    while (k < 8.0) {
        let ba = alg_bit_test(a, k);
        let bb = alg_bit_test(b, k);
        var xor_bit = 0.0;
        if (ba > 0.5 && bb < 0.5) { xor_bit = 1.0; }
        if (ba < 0.5 && bb > 0.5) { xor_bit = 1.0; }
        if (xor_bit > 0.5) {
            res = res + alg_bit_pow2(k);
        }
        k = k + 1.0;
    }
    return res;
}

// Grade popcount: counts number of set bits in mask
fn alg_bit_popcount(mask: float) -> float {
    var cnt = 0.0;
    var k = 0.0;
    while (k < 8.0) {
        if (alg_bit_test(mask, k) > 0.5) {
            cnt = cnt + 1.0;
        }
        k = k + 1.0;
    }
    return cnt;
}

// Computes number of anti-commutation swaps when reordering generators of blade a and blade b
fn alg_blade_swaps(a: float, b: float) -> float {
    var swaps = 0.0;
    var j = 0.0;
    while (j < 8.0) {
        if (alg_bit_test(b, j) > 0.5) {
            // Count set bits in a at positions i > j
            var i = j + 1.0;
            while (i < 8.0) {
                if (alg_bit_test(a, i) > 0.5) {
                    swaps = swaps + 1.0;
                }
                i = i + 1.0;
            }
        }
        j = j + 1.0;
    }
    return swaps;
}

// Computes metric contraction factor for overlapping generators in blade a and blade b
fn alg_blade_metric_factor(a: float, b: float, p: float, q: float, r: float) -> float {
    var factor = 1.0;
    var k = 0.0;
    let n = p + q + r;
    while (k < n) {
        let ba = alg_bit_test(a, k);
        let bb = alg_bit_test(b, k);
        if (ba > 0.5 && bb > 0.5) {
            if (k >= p + q) {
                // Null / degenerate basis: e_k^2 = 0
                return 0.0;
            }
            if (k >= p) {
                // Negative subspace: e_k^2 = -1
                factor = -factor;
            }
            // If k < p: e_k^2 = +1 (factor unchanged)
        }
        k = k + 1.0;
    }
    return factor;
}

// Combined sign of blade product: m_factor * (-1)^swaps
fn alg_blade_product_sign(a: float, b: float, p: float, q: float, r: float) -> float {
    let m_factor = alg_blade_metric_factor(a, b, p, q, r);
    if (m_factor == 0.0) {
        return 0.0;
    }
    let swaps = alg_blade_swaps(a, b);
    var sign = m_factor;
    if (fmod(swaps, 2.0) == 1.0) {
        sign = -sign;
    }
    return sign;
}

// ============================================================================
// Generalized Clifford Algebra Cl(p, q, r)
// ============================================================================

struct AlgMultivector {
    p: float;
    q: float;
    r: float;
    dim: float;        // n = p + q + r (n <= 8)
    num_blades: float; // 2^n
    coeffs: ptr;       // double* array of size 2^n
}

// Typed struct property accessors to guarantee sized GEP lowering in LLVM
fn alg_mv_coeffs(mv: AlgMultivector) -> ptr { return mv.coeffs; }
fn alg_mv_num_blades(mv: AlgMultivector) -> float { return mv.num_blades; }
fn alg_mv_p(mv: AlgMultivector) -> float { return mv.p; }
fn alg_mv_q(mv: AlgMultivector) -> float { return mv.q; }
fn alg_mv_r(mv: AlgMultivector) -> float { return mv.r; }
fn alg_mv_dim(mv: AlgMultivector) -> float { return mv.dim; }

// Allocates an empty multivector with zero-initialized coefficients
fn alg_mv_create(p: float, q: float, r: float) -> AlgMultivector {
    let n = p + q + r;
    var safe_n = n;
    if (safe_n > 8.0) { safe_n = 8.0; }
    let num = alg_bit_pow2(safe_n);
    let buf = calloc(num, 8.0);
    return AlgMultivector {
        p: p,
        q: q,
        r: r,
        dim: safe_n,
        num_blades: num,
        coeffs: buf
    };
}

// Frees multivector coefficient buffer
fn alg_mv_free(mv: AlgMultivector) -> void {
    let buf = alg_mv_coeffs(mv);
    if (buf != 0.0) {
        free(buf);
    }
}

// Clones a multivector
fn alg_mv_clone(mv: AlgMultivector) -> AlgMultivector {
    let copy = alg_mv_create(mv.p, mv.q, mv.r);
    let src_buf = alg_mv_coeffs(mv);
    let dst_buf = alg_mv_coeffs(copy);
    let num = mv.num_blades;
    var i = 0.0;
    while (i < num) {
        dst_buf[i] = src_buf[i];
        i = i + 1.0;
    }
    return copy;
}

// Gets coefficient of blade specified by bitmask
fn alg_mv_get_blade(mv: AlgMultivector, mask: float) -> float {
    if (mask < 0.0 || mask >= mv.num_blades) { return 0.0; }
    let buf = alg_mv_coeffs(mv);
    return buf[mask];
}

// Sets coefficient of blade specified by bitmask
fn alg_mv_set_blade(mv: AlgMultivector, mask: float, val: float) -> void {
    if (mask >= 0.0 && mask < mv.num_blades) {
        let buf = alg_mv_coeffs(mv);
        buf[mask] = val;
    }
}

// Returns the grade-0 scalar part
fn alg_mv_scalar(mv: AlgMultivector) -> float {
    let buf = alg_mv_coeffs(mv);
    return buf[0.0];
}

// Adds two multivectors of matching signature
fn alg_mv_add(a: AlgMultivector, b: AlgMultivector) -> AlgMultivector {
    let res = alg_mv_create(a.p, a.q, a.r);
    let buf_a = alg_mv_coeffs(a);
    let buf_b = alg_mv_coeffs(b);
    let buf_res = alg_mv_coeffs(res);
    let num = a.num_blades;
    var i = 0.0;
    while (i < num) {
        buf_res[i] = buf_a[i] + buf_b[i];
        i = i + 1.0;
    }
    return res;
}

// Subtracts two multivectors of matching signature
fn alg_mv_sub(a: AlgMultivector, b: AlgMultivector) -> AlgMultivector {
    let res = alg_mv_create(a.p, a.q, a.r);
    let buf_a = alg_mv_coeffs(a);
    let buf_b = alg_mv_coeffs(b);
    let buf_res = alg_mv_coeffs(res);
    let num = a.num_blades;
    var i = 0.0;
    while (i < num) {
        buf_res[i] = buf_a[i] - buf_b[i];
        i = i + 1.0;
    }
    return res;
}

// Scales a multivector by a real scalar
fn alg_mv_scale(a: AlgMultivector, s: float) -> AlgMultivector {
    let res = alg_mv_create(a.p, a.q, a.r);
    let buf_a = alg_mv_coeffs(a);
    let buf_res = alg_mv_coeffs(res);
    let num = a.num_blades;
    var i = 0.0;
    while (i < num) {
        buf_res[i] = buf_a[i] * s;
        i = i + 1.0;
    }
    return res;
}

// Computes the geometric product C = A B under signature (p, q, r)
fn alg_mv_mul(a: AlgMultivector, b: AlgMultivector) -> AlgMultivector {
    let res = alg_mv_create(a.p, a.q, a.r);
    let buf_a = alg_mv_coeffs(a);
    let buf_b = alg_mv_coeffs(b);
    let buf_res = alg_mv_coeffs(res);
    let num = a.num_blades;
    let p = a.p;
    let q = a.q;
    let r = a.r;

    var i = 0.0;
    while (i < num) {
        let ca = buf_a[i];
        if (fabs(ca) > 0.000000000000001) {
            var j = 0.0;
            while (j < num) {
                let cb = buf_b[j];
                if (fabs(cb) > 0.000000000000001) {
                    let sign = alg_blade_product_sign(i, j, p, q, r);
                    if (sign != 0.0) {
                        let k = alg_bit_xor(i, j);
                        buf_res[k] = buf_res[k] + (ca * cb * sign);
                    }
                }
                j = j + 1.0;
            }
        }
        i = i + 1.0;
    }
    return res;
}

// Computes the Grassmann exterior / wedge product C = A ^ B
fn alg_mv_wedge(a: AlgMultivector, b: AlgMultivector) -> AlgMultivector {
    let res = alg_mv_create(a.p, a.q, a.r);
    let buf_a = alg_mv_coeffs(a);
    let buf_b = alg_mv_coeffs(b);
    let buf_res = alg_mv_coeffs(res);
    let num = a.num_blades;

    var i = 0.0;
    while (i < num) {
        let ca = buf_a[i];
        if (fabs(ca) > 0.000000000000001) {
            var j = 0.0;
            while (j < num) {
                let cb = buf_b[j];
                if (fabs(cb) > 0.000000000000001) {
                    // In wedge product, shared generators vanish identically
                    let shared = alg_bit_and(i, j);
                    if (shared == 0.0) {
                        let swaps = alg_blade_swaps(i, j);
                        var sign = 1.0;
                        if (fmod(swaps, 2.0) == 1.0) {
                            sign = -1.0;
                        }
                        let k = alg_bit_xor(i, j);
                        buf_res[k] = buf_res[k] + (ca * cb * sign);
                    }
                }
                j = j + 1.0;
            }
        }
        i = i + 1.0;
    }
    return res;
}

// Computes the left contraction C = A _| B
fn alg_mv_left_contract(a: AlgMultivector, b: AlgMultivector) -> AlgMultivector {
    let res = alg_mv_create(a.p, a.q, a.r);
    let buf_a = alg_mv_coeffs(a);
    let buf_b = alg_mv_coeffs(b);
    let buf_res = alg_mv_coeffs(res);
    let num = a.num_blades;
    let p = a.p;
    let q = a.q;
    let r = a.r;

    var i = 0.0;
    while (i < num) {
        let ca = buf_a[i];
        if (fabs(ca) > 0.000000000000001) {
            var j = 0.0;
            while (j < num) {
                let cb = buf_b[j];
                if (fabs(cb) > 0.000000000000001) {
                    // Left contraction is non-zero iff all generators of blade i are contained in blade j
                    let shared = alg_bit_and(i, j);
                    if (shared == i) {
                        let sign = alg_blade_product_sign(i, j, p, q, r);
                        if (sign != 0.0) {
                            let k = alg_bit_xor(i, j);
                            buf_res[k] = buf_res[k] + (ca * cb * sign);
                        }
                    }
                }
                j = j + 1.0;
            }
        }
        i = i + 1.0;
    }
    return res;
}

// Extracts the multivector component of exact grade k
fn alg_mv_grade_project(mv: AlgMultivector, grade: float) -> AlgMultivector {
    let res = alg_mv_create(mv.p, mv.q, mv.r);
    let src_buf = alg_mv_coeffs(mv);
    let dst_buf = alg_mv_coeffs(res);
    let num = mv.num_blades;
    var i = 0.0;
    while (i < num) {
        if (alg_bit_popcount(i) == grade) {
            dst_buf[i] = src_buf[i];
        }
        i = i + 1.0;
    }
    return res;
}

// Computes the reversion ~A (reversing the order of basis vectors: (-1)^(k(k-1)/2))
fn alg_mv_reverse(mv: AlgMultivector) -> AlgMultivector {
    let res = alg_mv_create(mv.p, mv.q, mv.r);
    let src_buf = alg_mv_coeffs(mv);
    let dst_buf = alg_mv_coeffs(res);
    let num = mv.num_blades;
    var i = 0.0;
    while (i < num) {
        let k = alg_bit_popcount(i);
        let exp_term = floor((k * (k - 1.0)) / 2.0);
        var sign = 1.0;
        if (fmod(exp_term, 2.0) == 1.0) {
            sign = -1.0;
        }
        dst_buf[i] = src_buf[i] * sign;
        i = i + 1.0;
    }
    return res;
}

// Computes the grade involution ^A (replacing v with -v: (-1)^k)
fn alg_mv_involute(mv: AlgMultivector) -> AlgMultivector {
    let res = alg_mv_create(mv.p, mv.q, mv.r);
    let src_buf = alg_mv_coeffs(mv);
    let dst_buf = alg_mv_coeffs(res);
    let num = mv.num_blades;
    var i = 0.0;
    while (i < num) {
        let k = alg_bit_popcount(i);
        var sign = 1.0;
        if (fmod(k, 2.0) == 1.0) {
            sign = -1.0;
        }
        dst_buf[i] = src_buf[i] * sign;
        i = i + 1.0;
    }
    return res;
}

// Sum of squared coefficients
fn alg_mv_norm_sq(mv: AlgMultivector) -> float {
    let buf = alg_mv_coeffs(mv);
    let num = mv.num_blades;
    var sum = 0.0;
    var i = 0.0;
    while (i < num) {
        let c = buf[i];
        sum = sum + (c * c);
        i = i + 1.0;
    }
    return sum;
}

// Multivector norm
fn alg_mv_norm(mv: AlgMultivector) -> float {
    return sqrt(alg_mv_norm_sq(mv));
}

// Constructs a 3D rotor R = cos(theta/2) - B * sin(theta/2) in Cl(3, 0, 0)
// Basis bivectors: e12 (mask 3), e23 (mask 6), e31 (mask 5)
fn alg_mv_rotor_3d(angle: float, b12: float, b23: float, b31: float) -> AlgMultivector {
    let r = alg_mv_create(3.0, 0.0, 0.0);
    let b_norm = sqrt(b12 * b12 + b23 * b23 + b31 * b31);
    var u12 = 0.0;
    var u23 = 0.0;
    var u31 = 0.0;
    if (b_norm > 0.0000000001) {
        u12 = b12 / b_norm;
        u23 = b23 / b_norm;
        u31 = b31 / b_norm;
    }

    let half_angle = angle * 0.5;
    let cos_half = cos(half_angle);
    let sin_half = sin(half_angle);

    // Scalar component (mask 0)
    alg_mv_set_blade(r, 0.0, cos_half);
    // Bivector e12 is mask 3 (bit 0 and bit 1)
    alg_mv_set_blade(r, 3.0, -sin_half * u12);
    // Bivector e23 is mask 6 (bit 1 and bit 2)
    alg_mv_set_blade(r, 6.0, -sin_half * u23);
    // Bivector e31 = -e13. Since mask 5 is e13, -sin_half * u31 * e31 = +sin_half * u31 * e13
    alg_mv_set_blade(r, 5.0, sin_half * u31);

    return r;
}

// Computes rotor sandwich rotation v' = R v ~R with zero memory leak
fn alg_mv_sandwich(rotor: AlgMultivector, v: AlgMultivector) -> AlgMultivector {
    let rev_r = alg_mv_reverse(rotor);
    let temp = alg_mv_mul(rotor, v);
    let res = alg_mv_mul(temp, rev_r);

    alg_mv_free(temp);
    alg_mv_free(rev_r);
    return res;
}

// ============================================================================
// Cayley-Dickson & Hypercomplex Systems
// ============================================================================

// --- Complex Numbers C ---
struct AlgComplex {
    re: float;
    im: float;
}

fn alg_complex_create(re: float, im: float) -> AlgComplex {
    return AlgComplex { re: re, im: im };
}

fn alg_complex_add(a: AlgComplex, b: AlgComplex) -> AlgComplex {
    return AlgComplex { re: a.re + b.re, im: a.im + b.im };
}

fn alg_complex_sub(a: AlgComplex, b: AlgComplex) -> AlgComplex {
    return AlgComplex { re: a.re - b.re, im: a.im - b.im };
}

fn alg_complex_mul(a: AlgComplex, b: AlgComplex) -> AlgComplex {
    return AlgComplex {
        re: a.re * b.re - a.im * b.im,
        im: a.re * b.im + a.im * b.re
    };
}

fn alg_complex_conj(a: AlgComplex) -> AlgComplex {
    return AlgComplex { re: a.re, im: -a.im };
}

fn alg_complex_norm_sq(a: AlgComplex) -> float {
    return a.re * a.re + a.im * a.im;
}

fn alg_complex_norm(a: AlgComplex) -> float {
    return sqrt(alg_complex_norm_sq(a));
}

fn alg_complex_inv(a: AlgComplex) -> AlgComplex {
    let d = alg_complex_norm_sq(a);
    if (d == 0.0) { return AlgComplex { re: 0.0, im: 0.0 }; }
    return AlgComplex { re: a.re / d, im: -a.im / d };
}

fn alg_complex_div(a: AlgComplex, b: AlgComplex) -> AlgComplex {
    let inv_b = alg_complex_inv(b);
    return alg_complex_mul(a, inv_b);
}

// --- Dual Numbers D (Automatic Differentiation: eps^2 = 0) ---
struct AlgDual {
    val: float;
    eps: float;
}

fn alg_dual_create(val: float, eps: float) -> AlgDual {
    return AlgDual { val: val, eps: eps };
}

// Creates an active variable with infinitesimal seed eps = 1.0
fn alg_dual_var(val: float) -> AlgDual {
    return AlgDual { val: val, eps: 1.0 };
}

// Creates a constant dual number with eps = 0.0
fn alg_dual_const(val: float) -> AlgDual {
    return AlgDual { val: val, eps: 0.0 };
}

fn alg_dual_add(a: AlgDual, b: AlgDual) -> AlgDual {
    return AlgDual { val: a.val + b.val, eps: a.eps + b.eps };
}

fn alg_dual_sub(a: AlgDual, b: AlgDual) -> AlgDual {
    return AlgDual { val: a.val - b.val, eps: a.eps - b.eps };
}

// (u + u' eps) * (v + v' eps) = uv + (u v' + u' v) eps
fn alg_dual_mul(a: AlgDual, b: AlgDual) -> AlgDual {
    return AlgDual {
        val: a.val * b.val,
        eps: a.val * b.eps + a.eps * b.val
    };
}

// (u + u' eps) / (v + v' eps) = (u / v) + ((u' v - u v') / v^2) eps
fn alg_dual_div(a: AlgDual, b: AlgDual) -> AlgDual {
    let v = b.val;
    let v_sq = v * v;
    if (v_sq == 0.0) { return AlgDual { val: 0.0, eps: 0.0 }; }
    return AlgDual {
        val: a.val / v,
        eps: (a.eps * v - a.val * b.eps) / v_sq
    };
}

fn alg_dual_scale(a: AlgDual, s: float) -> AlgDual {
    return AlgDual { val: a.val * s, eps: a.eps * s };
}

fn alg_dual_sin(a: AlgDual) -> AlgDual {
    return AlgDual {
        val: sin(a.val),
        eps: a.eps * cos(a.val)
    };
}

fn alg_dual_cos(a: AlgDual) -> AlgDual {
    return AlgDual {
        val: cos(a.val),
        eps: -a.eps * sin(a.val)
    };
}

fn alg_dual_exp(a: AlgDual) -> AlgDual {
    let e = exp(a.val);
    return AlgDual {
        val: e,
        eps: a.eps * e
    };
}

fn alg_dual_sqrt(a: AlgDual) -> AlgDual {
    let s = sqrt(a.val);
    if (s == 0.0) { return AlgDual { val: 0.0, eps: 0.0 }; }
    return AlgDual {
        val: s,
        eps: a.eps / (2.0 * s)
    };
}

// --- Split-Complex Numbers H_split (j^2 = +1) ---
struct AlgSplit {
    re: float;
    j: float;
}

fn alg_split_create(re: float, j: float) -> AlgSplit {
    return AlgSplit { re: re, j: j };
}

fn alg_split_add(a: AlgSplit, b: AlgSplit) -> AlgSplit {
    return AlgSplit { re: a.re + b.re, j: a.j + b.j };
}

// (a + bj)(c + dj) = (ac + bd) + (ad + bc)j
fn alg_split_mul(a: AlgSplit, b: AlgSplit) -> AlgSplit {
    return AlgSplit {
        re: a.re * b.re + a.j * b.j,
        j: a.re * b.j + a.j * b.re
    };
}

fn alg_split_conj(a: AlgSplit) -> AlgSplit {
    return AlgSplit { re: a.re, j: -a.j };
}

// Spacetime hyperbolic interval: re^2 - j^2
fn alg_split_interval(a: AlgSplit) -> float {
    return a.re * a.re - a.j * a.j;
}

// --- Quaternions H (Hamilton 4D Division Algebra) ---
struct AlgQuat {
    w: float;
    x: float;
    y: float;
    z: float;
}

fn alg_quat_create(w: float, x: float, y: float, z: float) -> AlgQuat {
    return AlgQuat { w: w, x: x, y: y, z: z };
}

fn alg_quat_identity() -> AlgQuat {
    return AlgQuat { w: 1.0, x: 0.0, y: 0.0, z: 0.0 };
}

fn alg_quat_add(a: AlgQuat, b: AlgQuat) -> AlgQuat {
    return AlgQuat { w: a.w + b.w, x: a.x + b.x, y: a.y + b.y, z: a.z + b.z };
}

fn alg_quat_sub(a: AlgQuat, b: AlgQuat) -> AlgQuat {
    return AlgQuat { w: a.w - b.w, x: a.x - b.x, y: a.y - b.y, z: a.z - b.z };
}

fn alg_quat_mul(a: AlgQuat, b: AlgQuat) -> AlgQuat {
    return AlgQuat {
        w: a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
        x: a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
        y: a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
        z: a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w
    };
}

fn alg_quat_conj(a: AlgQuat) -> AlgQuat {
    return AlgQuat { w: a.w, x: -a.x, y: -a.y, z: -a.z };
}

fn alg_quat_norm_sq(a: AlgQuat) -> float {
    return a.w * a.w + a.x * a.x + a.y * a.y + a.z * a.z;
}

fn alg_quat_norm(a: AlgQuat) -> float {
    return sqrt(alg_quat_norm_sq(a));
}

fn alg_quat_inv(a: AlgQuat) -> AlgQuat {
    let d = alg_quat_norm_sq(a);
    if (d == 0.0) { return alg_quat_identity(); }
    return AlgQuat { w: a.w / d, x: -a.x / d, y: -a.y / d, z: -a.z / d };
}

fn alg_quat_normalize(a: AlgQuat) -> AlgQuat {
    let n = alg_quat_norm(a);
    if (n < 0.0000000001) { return alg_quat_identity(); }
    return AlgQuat { w: a.w / n, x: a.x / n, y: a.y / n, z: a.z / n };
}

// Spherical Linear Interpolation (slerp) with shortest-path and domain clamping
fn alg_quat_slerp(q1: AlgQuat, q2: AlgQuat, t: float) -> AlgQuat {
    var cos_omega = q1.w * q2.w + q1.x * q2.x + q1.y * q2.y + q1.z * q2.z;
    var sign = 1.0;

    // Shortest path wrapping
    if (cos_omega < 0.0) {
        cos_omega = -cos_omega;
        sign = -1.0;
    }

    // Domain clamp for acos stability
    if (cos_omega > 1.0) { cos_omega = 1.0; }

    let t_w = q2.w * sign;
    let t_x = q2.x * sign;
    let t_y = q2.y * sign;
    let t_z = q2.z * sign;

    // Small angle threshold fallback to normalized lerp
    if (cos_omega > 0.9995) {
        let w = q1.w + t * (t_w - q1.w);
        let x = q1.x + t * (t_x - q1.x);
        let y = q1.y + t * (t_y - q1.y);
        let z = q1.z + t * (t_z - q1.z);
        return alg_quat_normalize(AlgQuat { w: w, x: x, y: y, z: z });
    }

    let omega = acos(cos_omega);
    let sin_omega = sin(omega);
    let scale1 = sin((1.0 - t) * omega) / sin_omega;
    let scale2 = sin(t * omega) / sin_omega;

    return AlgQuat {
        w: scale1 * q1.w + scale2 * t_w,
        x: scale1 * q1.x + scale2 * t_x,
        y: scale1 * q1.y + scale2 * t_y,
        z: scale1 * q1.z + scale2 * t_z
    };
}

// --- Octonions O (8D Cayley-Dickson Division Algebra) ---
struct AlgOctonion {
    e0: float; // Real scalar part
    e1: float; // Imaginary units e1..e7
    e2: float;
    e3: float;
    e4: float;
    e5: float;
    e6: float;
    e7: float;
}

fn alg_octonion_create(e0: float, e1: float, e2: float, e3: float, e4: float, e5: float, e6: float, e7: float) -> AlgOctonion {
    return AlgOctonion {
        e0: e0, e1: e1, e2: e2, e3: e3,
        e4: e4, e5: e5, e6: e6, e7: e7
    };
}

fn alg_octonion_basis(idx: float) -> AlgOctonion {
    if (idx == 0.0) { return AlgOctonion { e0: 1.0, e1: 0.0, e2: 0.0, e3: 0.0, e4: 0.0, e5: 0.0, e6: 0.0, e7: 0.0 }; }
    if (idx == 1.0) { return AlgOctonion { e0: 0.0, e1: 1.0, e2: 0.0, e3: 0.0, e4: 0.0, e5: 0.0, e6: 0.0, e7: 0.0 }; }
    if (idx == 2.0) { return AlgOctonion { e0: 0.0, e1: 0.0, e2: 1.0, e3: 0.0, e4: 0.0, e5: 0.0, e6: 0.0, e7: 0.0 }; }
    if (idx == 3.0) { return AlgOctonion { e0: 0.0, e1: 0.0, e2: 0.0, e3: 1.0, e4: 0.0, e5: 0.0, e6: 0.0, e7: 0.0 }; }
    if (idx == 4.0) { return AlgOctonion { e0: 0.0, e1: 0.0, e2: 0.0, e3: 0.0, e4: 1.0, e5: 0.0, e6: 0.0, e7: 0.0 }; }
    if (idx == 5.0) { return AlgOctonion { e0: 0.0, e1: 0.0, e2: 0.0, e3: 0.0, e4: 0.0, e5: 1.0, e6: 0.0, e7: 0.0 }; }
    if (idx == 6.0) { return AlgOctonion { e0: 0.0, e1: 0.0, e2: 0.0, e3: 0.0, e4: 0.0, e5: 0.0, e6: 1.0, e7: 0.0 }; }
    if (idx == 7.0) { return AlgOctonion { e0: 0.0, e1: 0.0, e2: 0.0, e3: 0.0, e4: 0.0, e5: 0.0, e6: 0.0, e7: 1.0 }; }
    return AlgOctonion { e0: 0.0, e1: 0.0, e2: 0.0, e3: 0.0, e4: 0.0, e5: 0.0, e6: 0.0, e7: 0.0 };
}

fn alg_octonion_add(a: AlgOctonion, b: AlgOctonion) -> AlgOctonion {
    return AlgOctonion {
        e0: a.e0 + b.e0, e1: a.e1 + b.e1, e2: a.e2 + b.e2, e3: a.e3 + b.e3,
        e4: a.e4 + b.e4, e5: a.e5 + b.e5, e6: a.e6 + b.e6, e7: a.e7 + b.e7
    };
}

fn alg_octonion_sub(a: AlgOctonion, b: AlgOctonion) -> AlgOctonion {
    return AlgOctonion {
        e0: a.e0 - b.e0, e1: a.e1 - b.e1, e2: a.e2 - b.e2, e3: a.e3 - b.e3,
        e4: a.e4 - b.e4, e5: a.e5 - b.e5, e6: a.e6 - b.e6, e7: a.e7 - b.e7
    };
}

fn alg_octonion_conj(a: AlgOctonion) -> AlgOctonion {
    return AlgOctonion {
        e0: a.e0, e1: -a.e1, e2: -a.e2, e3: -a.e3,
        e4: -a.e4, e5: -a.e5, e6: -a.e6, e7: -a.e7
    };
}

fn alg_octonion_norm_sq(a: AlgOctonion) -> float {
    return a.e0 * a.e0 + a.e1 * a.e1 + a.e2 * a.e2 + a.e3 * a.e3 +
           a.e4 * a.e4 + a.e5 * a.e5 + a.e6 * a.e6 + a.e7 * a.e7;
}

fn alg_octonion_norm(a: AlgOctonion) -> float {
    return sqrt(alg_octonion_norm_sq(a));
}

// Cayley-Dickson multiplication of octonions using quaternion pairs
// A = (a1, a2), B = (b1, b2)
// A * B = (a1 * b1 - b2_conj * a2, b2 * a1 + a2 * b1_conj)
fn alg_octonion_mul(a: AlgOctonion, b: AlgOctonion) -> AlgOctonion {
    let a1 = AlgQuat { w: a.e0, x: a.e1, y: a.e2, z: a.e3 };
    let a2 = AlgQuat { w: a.e4, x: a.e5, y: a.e6, z: a.e7 };
    let b1 = AlgQuat { w: b.e0, x: b.e1, y: b.e2, z: b.e3 };
    let b2 = AlgQuat { w: b.e4, x: b.e5, y: b.e6, z: b.e7 };

    let a1_b1 = alg_quat_mul(a1, b1);
    let b2_conj = alg_quat_conj(b2);
    let b2_conj_a2 = alg_quat_mul(b2_conj, a2);
    let c1 = alg_quat_sub(a1_b1, b2_conj_a2);

    let b2_a1 = alg_quat_mul(b2, a1);
    let b1_conj = alg_quat_conj(b1);
    let a2_b1_conj = alg_quat_mul(a2, b1_conj);
    let c2 = alg_quat_add(b2_a1, a2_b1_conj);

    return AlgOctonion {
        e0: c1.w, e1: c1.x, e2: c1.y, e3: c1.z,
        e4: c2.w, e5: c2.x, e6: c2.y, e7: c2.z
    };
}

// Computes the octonion associator: [a, b, c] = (a * b) * c - a * (b * c)
// For non-associative algebras, [a, b, c] is generally non-zero!
fn alg_octonion_associator(a: AlgOctonion, b: AlgOctonion, c: AlgOctonion) -> AlgOctonion {
    let ab = alg_octonion_mul(a, b);
    let ab_c = alg_octonion_mul(ab, c);

    let bc = alg_octonion_mul(b, c);
    let a_bc = alg_octonion_mul(a, bc);

    return alg_octonion_sub(ab_c, a_bc);
}

// ============================================================================
// Polynomial-Differential Weyl Algebra W_n (Bosonic Dual to Clifford)
// ============================================================================

// Single-generator Weyl Algebra W_1 = R[x, d] with [d, x] = 1
// Represented as a dense 2D coefficient grid: sum_{alpha, beta} c(alpha, beta) * x^alpha * d^beta
// Degree bounded by max_deg (default 8)
struct AlgWeylOp {
    max_deg: float;
    coeffs: ptr; // Size: (max_deg + 1) * (max_deg + 1) doubles
}

// Typed struct accessor
fn alg_weyl_coeffs(op: AlgWeylOp) -> ptr { return op.coeffs; }

fn alg_weyl_create(max_deg: float) -> AlgWeylOp {
    var deg = max_deg;
    if (deg <= 0.0) { deg = 8.0; }
    let side = deg + 1.0;
    let total = side * side;
    let buf = calloc(total, 8.0);
    return AlgWeylOp { max_deg: deg, coeffs: buf };
}

fn alg_weyl_free(op: AlgWeylOp) -> void {
    let buf = alg_weyl_coeffs(op);
    if (buf != 0.0) {
        free(buf);
    }
}

// Gets coefficient of x^alpha * d^beta
fn alg_weyl_get(op: AlgWeylOp, alpha: float, beta: float) -> float {
    if (alpha < 0.0 || alpha > op.max_deg || beta < 0.0 || beta > op.max_deg) {
        return 0.0;
    }
    let side = op.max_deg + 1.0;
    let idx = alpha * side + beta;
    let buf = alg_weyl_coeffs(op);
    return buf[idx];
}

// Sets coefficient of x^alpha * d^beta
fn alg_weyl_set(op: AlgWeylOp, alpha: float, beta: float, val: float) -> void {
    if (alpha >= 0.0 && alpha <= op.max_deg && beta >= 0.0 && beta <= op.max_deg) {
        let side = op.max_deg + 1.0;
        let idx = alpha * side + beta;
        let buf = alg_weyl_coeffs(op);
        buf[idx] = val;
    }
}

// Adds val to coefficient of x^alpha * d^beta
fn alg_weyl_add_term(op: AlgWeylOp, alpha: float, beta: float, val: float) -> void {
    if (alpha >= 0.0 && alpha <= op.max_deg && beta >= 0.0 && beta <= op.max_deg) {
        let side = op.max_deg + 1.0;
        let idx = alpha * side + beta;
        let buf = alg_weyl_coeffs(op);
        buf[idx] = buf[idx] + val;
    }
}

// Creates the position coordinate operator x (x^1 * d^0)
fn alg_weyl_pos(max_deg: float) -> AlgWeylOp {
    let op = alg_weyl_create(max_deg);
    alg_weyl_set(op, 1.0, 0.0, 1.0);
    return op;
}

// Creates the momentum / derivative operator d (x^0 * d^1)
fn alg_weyl_der(max_deg: float) -> AlgWeylOp {
    let op = alg_weyl_create(max_deg);
    alg_weyl_set(op, 0.0, 1.0, 1.0);
    return op;
}

// Creates the scalar identity operator 1 (x^0 * d^0)
fn alg_weyl_identity(max_deg: float) -> AlgWeylOp {
    let op = alg_weyl_create(max_deg);
    alg_weyl_set(op, 0.0, 0.0, 1.0);
    return op;
}

// Multiplies two differential operators using normal ordering Leibniz expansion:
// d^b1 * x^a2 = sum_{r=0}^{min(b1, a2)} binom(b1, r) * (a2! / (a2 - r)!) * x^(a2 - r) * d^(b1 - r)
fn alg_weyl_mul(p: AlgWeylOp, q: AlgWeylOp) -> AlgWeylOp {
    var deg = p.max_deg;
    if (q.max_deg > deg) { deg = q.max_deg; }
    let res = alg_weyl_create(deg);

    let side_p = p.max_deg + 1.0;
    let side_q = q.max_deg + 1.0;
    let buf_p = alg_weyl_coeffs(p);
    let buf_q = alg_weyl_coeffs(q);

    var a1 = 0.0;
    while (a1 <= p.max_deg) {
        var b1 = 0.0;
        while (b1 <= p.max_deg) {
            let cp = buf_p[a1 * side_p + b1];
            if (fabs(cp) > 0.000000000000001) {
                var a2 = 0.0;
                while (a2 <= q.max_deg) {
                    var b2 = 0.0;
                    while (b2 <= q.max_deg) {
                        let cq = buf_q[a2 * side_q + b2];
                        if (fabs(cq) > 0.000000000000001) {
                            // Expand d^b1 * x^a2 via Leibniz formula
                            var min_r = b1;
                            if (a2 < min_r) { min_r = a2; }

                            var r = 0.0;
                            var w = 1.0; // r = 0 term weight is 1.0
                            while (r <= min_r) {
                                if (r > 0.0) {
                                    // w(r) = w(r-1) * (b1 - r + 1) * (a2 - r + 1) / r
                                    w = w * (b1 - r + 1.0) * (a2 - r + 1.0) / r;
                                }
                                let out_alpha = a1 + a2 - r;
                                let out_beta = b1 + b2 - r;
                                if (out_alpha <= deg && out_beta <= deg) {
                                    alg_weyl_add_term(res, out_alpha, out_beta, cp * cq * w);
                                }
                                r = r + 1.0;
                            }
                        }
                        b2 = b2 + 1.0;
                    }
                    a2 = a2 + 1.0;
                }
            }
            b1 = b1 + 1.0;
        }
        a1 = a1 + 1.0;
    }
    return res;
}

// Computes the operator commutator bracket [P, Q] = P * Q - Q * P
fn alg_weyl_commutator(p: AlgWeylOp, q: AlgWeylOp) -> AlgWeylOp {
    let pq = alg_weyl_mul(p, q);
    let qp = alg_weyl_mul(q, p);

    var deg = pq.max_deg;
    let res = alg_weyl_create(deg);
    let side = deg + 1.0;
    let buf_pq = alg_weyl_coeffs(pq);
    let buf_qp = alg_weyl_coeffs(qp);
    let buf_res = alg_weyl_coeffs(res);

    var i = 0.0;
    let total = side * side;
    while (i < total) {
        buf_res[i] = buf_pq[i] - buf_qp[i];
        i = i + 1.0;
    }

    alg_weyl_free(pq);
    alg_weyl_free(qp);
    return res;
}

// Evaluates the action of differential operator P(x, d) on a test polynomial f(x)
// Input: poly_in double* array of size poly_deg + 1 (coeffs of 1, x, x^2, ..., x^poly_deg)
// Output: newly allocated double* array of size out_deg + 1
fn alg_weyl_apply_poly(op: AlgWeylOp, poly_in: ptr, in_deg: float, out_deg: float) -> ptr {
    let out_len = out_deg + 1.0;
    let poly_out = calloc(out_len, 8.0);
    let side = op.max_deg + 1.0;
    let buf = alg_weyl_coeffs(op);

    var alpha = 0.0;
    while (alpha <= op.max_deg) {
        var beta = 0.0;
        while (beta <= op.max_deg) {
            let c_op = buf[alpha * side + beta];
            if (fabs(c_op) > 0.000000000000001) {
                // Apply x^alpha * d^beta to each term a_k * x^k of poly_in
                var k = beta;
                while (k <= in_deg) {
                    let a_k = poly_in[k];
                    if (fabs(a_k) > 0.000000000000001) {
                        // Compute d^beta(x^k) = k * (k - 1) * ... * (k - beta + 1) * x^(k - beta)
                        var falling_fact = 1.0;
                        var m = 0.0;
                        while (m < beta) {
                            falling_fact = falling_fact * (k - m);
                            m = m + 1.0;
                        }
                        let target_power = k - beta + alpha;
                        if (target_power <= out_deg) {
                            poly_out[target_power] = poly_out[target_power] + (c_op * a_k * falling_fact);
                        }
                    }
                    k = k + 1.0;
                }
            }
            beta = beta + 1.0;
        }
        alpha = alpha + 1.0;
    }
    return poly_out;
}
