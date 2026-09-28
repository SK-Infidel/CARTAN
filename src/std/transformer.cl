// src/std/transformer.cl
// CARTAN Standard Library: Native Causal Transformer Decoder Architecture
// Layer 1 Module: std::transformer
// Implements Gemma-style Causal Transformer Layer: RMSNorm, RoPE, Grouped-Query Attention (GQA), and SwiGLU MLP

include "src/std/math.cl";
include "src/std/collections.cl";
include "src/std/tensor.cl";

extern fn exp(x: float) -> float;
extern fn sqrt(x: float) -> float;
extern fn tanh(x: float) -> float;
extern fn sin(x: float) -> float;
extern fn cos(x: float) -> float;
extern fn pow(base: float, exp: float) -> float;

// -----------------------------------------------------------------------------
// 1. Root Mean Square Layer Normalization (RMSNorm)
// -----------------------------------------------------------------------------
fn cartan_rmsnorm(x: ptr, w: ptr, dim: float, eps: float) -> ptr {
    if (x == 0.0 || dim <= 0.0) { return 0.0; }
    var sum_sq = 0.0;
    var i = 0.0;
    while (i < dim) {
        let val = cartan_vec_get_f32(x, i);
        sum_sq = sum_sq + val * val;
        i = i + 1.0;
    }
    let mean_sq = sum_sq / dim;
    let inv_rms = 1.0 / sqrt(mean_sq + eps);

    let out = cartan_vec_create();
    i = 0.0;
    while (i < dim) {
        let val = cartan_vec_get_f32(x, i);
        var scale = 1.0;
        if (w != 0.0) {
            scale = cartan_vec_get_f32(w, i);
        }
        cartan_vec_push_f32(out, val * inv_rms * scale);
        i = i + 1.0;
    }
    return out;
}

// -----------------------------------------------------------------------------
// 2. Rotary Position Embedding (RoPE)
// -----------------------------------------------------------------------------
fn cartan_rope_apply(vec: ptr, pos: float, head_dim: float, theta_base: float) -> ptr {
    if (vec == 0.0 || head_dim <= 0.0) { return 0.0; }
    let out = cartan_vec_create();
    let half = head_dim / 2.0;
    var k = 0.0;
    while (k < half) {
        let x0 = cartan_vec_get_f32(vec, k * 2.0);
        let x1 = cartan_vec_get_f32(vec, k * 2.0 + 1.0);
        
        let exponent = (k * 2.0) / head_dim;
        var base = theta_base;
        if (base <= 0.0) { base = 10000.0; }
        let freq = 1.0 / pow(base, exponent);
        let theta = pos * freq;
        let c = cos(theta);
        let s = sin(theta);

        let rx0 = x0 * c - x1 * s;
        let rx1 = x0 * s + x1 * c;
        cartan_vec_push_f32(out, rx0);
        cartan_vec_push_f32(out, rx1);
        k = k + 1.0;
    }
    return out;
}

// -----------------------------------------------------------------------------
// 3. Activations: GELU (PyTorch Tanh Approximation) & SiLU
// -----------------------------------------------------------------------------
fn cartan_gelu_tanh(x: float) -> float {
    let sqrt_2_over_pi = 0.7978845608;
    let inner = sqrt_2_over_pi * (x + 0.044715 * x * x * x);
    return 0.5 * x * (1.0 + tanh(inner));
}

fn cartan_silu(x: float) -> float {
    return x / (1.0 + exp(0.0 - x));
}

// -----------------------------------------------------------------------------
// 4. SwiGLU / GeGLU Feedforward MLP
// FFN(x) = (SiLU(x * W_gate) * (x * W_up)) * W_down
// -----------------------------------------------------------------------------
fn cartan_swiglu_mlp_forward(x: ptr, gate_w: ptr, up_w: ptr, down_w: ptr, in_dim: float, inter_dim: float) -> ptr {
    if (x == 0.0 || in_dim <= 0.0 || inter_dim <= 0.0) { return 0.0; }
    if (gate_w == 0.0 || up_w == 0.0 || down_w == 0.0) { return 0.0; }
    
    // 1. Compute gate and up projections: [inter_dim]
    let hidden_act = cartan_vec_create();
    var j = 0.0;
    while (j < inter_dim) {
        var dot_gate = 0.0;
        var dot_up = 0.0;
        var i = 0.0;
        let row_off = j * in_dim;
        while (i < in_dim) {
            let xi = cartan_vec_get_f32(x, i);
            dot_gate = dot_gate + xi * cartan_vec_get_f32(gate_w, row_off + i);
            dot_up = dot_up + xi * cartan_vec_get_f32(up_w, row_off + i);
            i = i + 1.0;
        }
        let act = cartan_silu(dot_gate) * dot_up;
        cartan_vec_push_f32(hidden_act, act);
        j = j + 1.0;
    }

    // 2. Compute down projection back to in_dim: [in_dim]
    let out = cartan_vec_create();
    var d = 0.0;
    while (d < in_dim) {
        var dot_down = 0.0;
        j = 0.0;
        let down_row_off = d * inter_dim;
        while (j < inter_dim) {
            let act_j = cartan_vec_get_f32(hidden_act, j);
            dot_down = dot_down + act_j * cartan_vec_get_f32(down_w, down_row_off + j);
            j = j + 1.0;
        }
        cartan_vec_push_f32(out, dot_down);
        d = d + 1.0;
    }
    cartan_vec_free(hidden_act);
    return out;
}

// -----------------------------------------------------------------------------
// 5. Grouped-Query Causal Attention (GQA)
// 8 Query Heads mapped to 2 KV Heads (4:1 head sharing) with head_dim 256
// -----------------------------------------------------------------------------
fn cartan_gqa_causal_attention(q_proj: ptr, k_cache: ptr, v_cache: ptr, seq_len: float, q_heads: float, kv_heads: float, head_dim: float) -> ptr {
    if (q_proj == 0.0 || k_cache == 0.0 || v_cache == 0.0 || seq_len <= 0.0) { return 0.0; }
    
    let total_q_dim = q_heads * head_dim;
    let heads_per_kv = q_heads / kv_heads;
    let inv_scale = 1.0 / sqrt(head_dim);
    let out = cartan_vec_create();

    var qh = 0.0;
    while (qh < q_heads) {
        let kvh = floor(qh / heads_per_kv);
        let q_off = qh * head_dim;
        
        // Compute causal attention scores across sequence history: scores[t] = q · k_t / sqrt(d)
        let scores = cartan_vec_create();
        var max_score = -1000000.0;
        var t = 0.0;
        while (t < seq_len) {
            var dot = 0.0;
            var d = 0.0;
            let k_off = (t * kv_heads + kvh) * head_dim;
            while (d < head_dim) {
                let q_val = cartan_vec_get_f32(q_proj, q_off + d);
                let k_val = cartan_vec_get_f32(k_cache, k_off + d);
                dot = dot + q_val * k_val;
                d = d + 1.0;
            }
            let s = dot * inv_scale;
            if (s > max_score) { max_score = s; }
            cartan_vec_push_f32(scores, s);
            t = t + 1.0;
        }

        // Softmax with numerical stabilization: p_t = exp(s_t - max) / sum(exp(s - max))
        var sum_exp = 0.0;
        t = 0.0;
        while (t < seq_len) {
            let s = cartan_vec_get_f32(scores, t);
            let ep = exp(s - max_score);
            cartan_vec_set_f32(scores, t, ep);
            sum_exp = sum_exp + ep;
            t = t + 1.0;
        }
        if (sum_exp <= 0.0) { sum_exp = 1.0; }

        // Context weighted sum: context_d = sum_t (p_t * v_t,d)
        var cd = 0.0;
        while (cd < head_dim) {
            var weighted_val = 0.0;
            t = 0.0;
            while (t < seq_len) {
                let p_t = cartan_vec_get_f32(scores, t) / sum_exp;
                let v_off = (t * kv_heads + kvh) * head_dim;
                let v_val = cartan_vec_get_f32(v_cache, v_off + cd);
                weighted_val = weighted_val + p_t * v_val;
                t = t + 1.0;
            }
            cartan_vec_push_f32(out, weighted_val);
            cd = cd + 1.0;
        }
        cartan_vec_free(scores);
        qh = qh + 1.0;
    }
    return out;
}

// -----------------------------------------------------------------------------
// 6. Complete Causal Transformer Decoder Layer Forward Step
// h_1 = h + Attention(RMSNorm(h))
// h_2 = h_1 + MLP(RMSNorm(h_1))
// -----------------------------------------------------------------------------
fn cartan_transformer_layer_forward(
    h: ptr,
    w_q: ptr, w_k: ptr, w_v: ptr, w_o: ptr,
    norm_attn_w: ptr, norm_ffn_w: ptr,
    gate_w: ptr, up_w: ptr, down_w: ptr,
    pos: float, seq_len: float, dim: float, inter_dim: float,
    q_heads: float, kv_heads: float, head_dim: float,
    k_cache: ptr, v_cache: ptr
) -> ptr {
    if (h == 0.0 || dim <= 0.0) { return 0.0; }
    if (w_q == 0.0 || w_o == 0.0) { return 0.0; }
    if (gate_w == 0.0 || up_w == 0.0 || down_w == 0.0) { return 0.0; }

    // 1. Pre-Attention RMSNorm
    let normed_h1 = cartan_rmsnorm(h, norm_attn_w, dim, 0.000001);

    // 2. Project to Q, K, V
    let q_raw = cartan_vec_create();
    let q_dim = q_heads * head_dim;
    var q_i = 0.0;
    while (q_i < q_dim) {
        var dot_q = 0.0;
        var r = 0.0;
        let q_row = q_i * dim;
        while (r < dim) {
            let x_r = cartan_vec_get_f32(normed_h1, r);
            dot_q = dot_q + x_r * cartan_vec_get_f32(w_q, q_row + r);
            r = r + 1.0;
        }
        cartan_vec_push_f32(q_raw, dot_q);
        q_i = q_i + 1.0;
    }

    // Apply RoPE on Query heads
    let q_rot = cartan_vec_create();
    var qh = 0.0;
    while (qh < q_heads) {
        let single_head = cartan_vec_create();
        var hd = 0.0;
        let head_off = qh * head_dim;
        while (hd < head_dim) {
            cartan_vec_push_f32(single_head, cartan_vec_get_f32(q_raw, head_off + hd));
            hd = hd + 1.0;
        }
        let rot_head = cartan_rope_apply(single_head, pos, head_dim, 10000.0);
        hd = 0.0;
        while (hd < head_dim) {
            cartan_vec_push_f32(q_rot, cartan_vec_get_f32(rot_head, hd));
            hd = hd + 1.0;
        }
        cartan_vec_free(single_head);
        cartan_vec_free(rot_head);
        qh = qh + 1.0;
    }
    cartan_vec_free(q_raw);

    // 3. Multi-Head GQA Attention
    let attn_heads_out = cartan_gqa_causal_attention(q_rot, k_cache, v_cache, seq_len, q_heads, kv_heads, head_dim);
    cartan_vec_free(q_rot);

    // 4. Output projection W_o: [q_dim] -> [dim] & Residual Addition
    let h1 = cartan_vec_create();
    var d = 0.0;
    while (d < dim) {
        var dot_o = 0.0;
        var c = 0.0;
        let o_row = d * q_dim;
        while (c < q_dim) {
            let ac = cartan_vec_get_f32(attn_heads_out, c);
            dot_o = dot_o + ac * cartan_vec_get_f32(w_o, o_row + c);
            c = c + 1.0;
        }
        let orig = cartan_vec_get_f32(h, d);
        cartan_vec_push_f32(h1, orig + dot_o);
        d = d + 1.0;
    }
    cartan_vec_free(normed_h1);
    cartan_vec_free(attn_heads_out);

    // 5. Pre-FFN RMSNorm
    let normed_h2 = cartan_rmsnorm(h1, norm_ffn_w, dim, 0.000001);

    // 6. SwiGLU MLP & Residual Addition
    let ffn_out = cartan_swiglu_mlp_forward(normed_h2, gate_w, up_w, down_w, dim, inter_dim);
    cartan_vec_free(normed_h2);

    let h2 = cartan_vec_create();
    d = 0.0;
    while (d < dim) {
        let val1 = cartan_vec_get_f32(h1, d);
        let ffn_val = cartan_vec_get_f32(ffn_out, d);
        cartan_vec_push_f32(h2, val1 + ffn_val);
        d = d + 1.0;
    }
    cartan_vec_free(h1);
    cartan_vec_free(ffn_out);

    return h2;
}
