// src/std/markov.cl
// CARTAN Standard Library: Non-Euclidean Stochastic Kernels & Information Geometry
// Formalizes Donald Hoffman's Conscious Realism Markov Dynamics on Probability Simplices

include "src/std/math.cl";
include "src/std/tensor.cl";
include "src/std/geom.cl";

// Maps unconstrained real logits to a row-stochastic matrix on the Birkhoff Polytope
fn markov_row_softmax(logits: ptr, rows: float, cols: float, out: ptr) {
    if (logits == 0.0 || out == 0.0 || rows <= 0.0 || cols <= 0.0) { return; }
    var r = 0.0;
    while (r < rows) {
        let r_offset = r * cols;
        // Find row maximum for numerical stability
        var max_v = logits[r_offset];
        var c = 1.0;
        while (c < cols) {
            let v = logits[r_offset + c];
            if (v > max_v) { max_v = v; }
            c = c + 1.0;
        }

        // Exponentiate and sum
        var sum_exp = 0.0;
        c = 0.0;
        while (c < cols) {
            let exp_val = exp(logits[r_offset + c] - max_v);
            out[r_offset + c] = exp_val;
            sum_exp = sum_exp + exp_val;
            c = c + 1.0;
        }

        // Normalize row to sum strictly to 1.0
        if (sum_exp <= 0.0) { sum_exp = 1.0; }
        let inv_sum = 1.0 / sum_exp;
        c = 0.0;
        while (c < cols) {
            out[r_offset + c] = out[r_offset + c] * inv_sum;
            c = c + 1.0;
        }
        r = r + 1.0;
    }
}

// Multiplies two matrices C = A * B with row-stochastic preservation guard
fn markov_matrix_mult(A: ptr, B: ptr, out: ptr, m: float, k: float, n: float) {
    if (A == 0.0 || B == 0.0 || out == 0.0) { return; }
    var r = 0.0;
    while (r < m) {
        let r_offset_a = r * k;
        let r_offset_out = r * n;
        var c = 0.0;
        var row_sum = 0.0;
        while (c < n) {
            var dot = 0.0;
            var p = 0.0;
            while (p < k) {
                dot = dot + A[r_offset_a + p] * B[p * n + c];
                p = p + 1.0;
            }
            out[r_offset_out + c] = dot;
            row_sum = row_sum + dot;
            c = c + 1.0;
        }

        // Ensure row strictly sums to 1.0 (Birkhoff normalization)
        if (row_sum > 0.0 && fabs(row_sum - 1.0) > 0.000001) {
            let inv_s = 1.0 / row_sum;
            c = 0.0;
            while (c < n) {
                out[r_offset_out + c] = out[r_offset_out + c] * inv_s;
                c = c + 1.0;
            }
        }
        r = r + 1.0;
    }
}

// Computes Bhattacharyya spherical geodesic distance on the probability simplex
fn markov_bhattacharyya_distance(p: ptr, q: ptr, len: float) -> float {
    if (p == 0.0 || q == 0.0 || len <= 0.0) { return 0.0; }
    var s = 0.0;
    var i = 0.0;
    while (i < len) {
        let pi = p[i];
        let qi = q[i];
        if (pi > 0.0 && qi > 0.0) {
            s = s + sqrt(pi * qi);
        }
        i = i + 1.0;
    }
    if (s > 1.0) { s = 1.0; }
    if (s < -1.0) { s = -1.0; }
    return 2.0 * acos(s);
}

// Natural gradient projection using the Fisher-Rao Riemannian metric on the simplex
fn markov_fisher_rao_natural_grad(grad: ptr, probs: ptr, rows: float, cols: float, out_nat: ptr) {
    if (grad == 0.0 || probs == 0.0 || out_nat == 0.0) { return; }
    var r = 0.0;
    while (r < rows) {
        let offset = r * cols;
        // Compute expected gradient along row: E[g] = sum_k probs[rk] * grad[rk]
        var mean_g = 0.0;
        var c = 0.0;
        while (c < cols) {
            mean_g = mean_g + probs[offset + c] * grad[offset + c];
            c = c + 1.0;
        }

        // Natural gradient: g_nat = g - E[g]
        c = 0.0;
        while (c < cols) {
            out_nat[offset + c] = grad[offset + c] - mean_g;
            c = c + 1.0;
        }
        r = r + 1.0;
    }
}

// Power iteration solver for the Perron-Frobenius stationary distribution (pi * T = pi)
fn markov_stationary_distribution(T: ptr, pi_out: ptr, dim: float, max_iters: float) -> float {
    if (T == 0.0 || pi_out == 0.0 || dim <= 0.0) { return 0.0; }
    let next_pi = tensor_alloc(dim);
    // Initialize with uniform distribution
    let unif = 1.0 / dim;
    var i = 0.0;
    while (i < dim) {
        pi_out[i] = unif;
        i = i + 1.0;
    }

    var iter = 0.0;
    var final_diff = 1.0;
    while (iter < max_iters) {
        // next_pi = pi_out * T
        var c = 0.0;
        while (c < dim) {
            var dot = 0.0;
            var r = 0.0;
            while (r < dim) {
                dot = dot + pi_out[r] * T[r * dim + c];
                r = r + 1.0;
            }
            next_pi[c] = dot;
            c = c + 1.0;
        }

        // Compute L1 convergence residual
        var diff = 0.0;
        var sum_p = 0.0;
        i = 0.0;
        while (i < dim) {
            diff = diff + fabs(next_pi[i] - pi_out[i]);
            sum_p = sum_p + next_pi[i];
            i = i + 1.0;
        }

        // Normalize
        if (sum_p > 0.0) {
            let inv_sp = 1.0 / sum_p;
            i = 0.0;
            while (i < dim) {
                pi_out[i] = next_pi[i] * inv_sp;
                i = i + 1.0;
            }
        }

        final_diff = diff;
        if (diff < 0.0000001) {
            iter = max_iters + 1.0;
        }
        iter = iter + 1.0;
    }
    free(next_pi);
    return final_diff;
}

// Computes the spectral gap gamma = 1 - |lambda_2| via deflated power iteration
fn markov_spectral_gap(T: ptr, pi_stat: ptr, dim: float, temp_v: ptr, temp_out: ptr) -> float {
    if (T == 0.0 || pi_stat == 0.0 || temp_v == 0.0 || temp_out == 0.0 || dim <= 1.0) { return 0.0; }
    // Initialize random-like orthogonalized test vector
    var i = 0.0;
    while (i < dim) {
        temp_v[i] = sin((i + 1.0) * 1.61803398);
        i = i + 1.0;
    }

    // Orthogonalize against stationary state: v = v - (sum v_i) * pi_stat
    var sum_v = 0.0;
    i = 0.0;
    while (i < dim) {
        sum_v = sum_v + temp_v[i];
        i = i + 1.0;
    }
    i = 0.0;
    while (i < dim) {
        temp_v[i] = temp_v[i] - sum_v * pi_stat[i];
        i = i + 1.0;
    }

    // Power iterations on deflated operator: T_def = T - 1 * pi_stat
    var iter = 0.0;
    var lambda2 = 0.0;
    while (iter < 30.0) {
        var c = 0.0;
        while (c < dim) {
            var dot = 0.0;
            var r = 0.0;
            while (r < dim) {
                // T_def[r, c] = T[r, c] - pi_stat[c]
                let t_def = T[r * dim + c] - pi_stat[c];
                dot = dot + temp_v[r] * t_def;
                r = r + 1.0;
            }
            temp_out[c] = dot;
            c = c + 1.0;
        }

        // Rayleigh quotient approximation
        var num = 0.0;
        var den = 0.0;
        i = 0.0;
        while (i < dim) {
            num = num + temp_v[i] * temp_out[i];
            den = den + temp_v[i] * temp_v[i];
            i = i + 1.0;
        }
        if (den > 0.0) { lambda2 = num / den; }

        // Normalize temp_out to temp_v
        var norm = 0.0;
        i = 0.0;
        while (i < dim) {
            norm = norm + temp_out[i] * temp_out[i];
            i = i + 1.0;
        }
        norm = sqrt(norm);
        if (norm > 0.0) {
            let inv_n = 1.0 / norm;
            i = 0.0;
            while (i < dim) {
                temp_v[i] = temp_out[i] * inv_n;
                i = i + 1.0;
            }
        }
        iter = iter + 1.0;
    }

    let mag = fabs(lambda2);
    if (mag > 1.0) { return 0.0; }
    return 1.0 - mag;
}

// Derives emergent 3D spatial embedding coordinates (x, y, z) from diffusion eigenvectors
fn markov_diffusion_coordinates(T: ptr, pi_stat: ptr, dim: float, coords_out: ptr) {
    if (T == 0.0 || pi_stat == 0.0 || coords_out == 0.0 || dim <= 0.0) { return; }
    // Generates 3 independent orthogonal diffusion projections
    let v_buf = tensor_alloc(dim);
    let v_out = tensor_alloc(dim);

    var coord_idx = 0.0;
    while (coord_idx < 3.0) {
        // Initialize harmonic seed
        var i = 0.0;
        while (i < dim) {
            v_buf[i] = cos((i + 1.0) * (coord_idx + 1.0) * 1.41421356);
            i = i + 1.0;
        }
        // Orthogonalize against stationary vacuum
        var sum_v = 0.0;
        i = 0.0;
        while (i < dim) {
            sum_v = sum_v + v_buf[i];
            i = i + 1.0;
        }
        i = 0.0;
        while (i < dim) {
            v_buf[i] = v_buf[i] - sum_v * pi_stat[i];
            i = i + 1.0;
        }

        // Apply 3 diffusion steps T^3
        var step = 0.0;
        while (step < 3.0) {
            var c = 0.0;
            while (c < dim) {
                var dot = 0.0;
                var r = 0.0;
                while (r < dim) {
                    dot = dot + v_buf[r] * (T[r * dim + c] - pi_stat[c]);
                    r = r + 1.0;
                }
                v_out[c] = dot;
                c = c + 1.0;
            }
            i = 0.0;
            while (i < dim) {
                v_buf[i] = v_out[i];
                i = i + 1.0;
            }
            step = step + 1.0;
        }

        // Store into coords_out (dim x 3)
        i = 0.0;
        while (i < dim) {
            coords_out[i * 3.0 + coord_idx] = v_buf[i];
            i = i + 1.0;
        }
        coord_idx = coord_idx + 1.0;
    }
    free(v_buf);
    free(v_out);
}
