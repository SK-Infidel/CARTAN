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
extern fn fmod(x: float, y: float) -> float;
extern fn floor(x: float) -> float;

extern fn calloc(count: float, size: float) -> ptr;
extern fn malloc(size: float) -> ptr;
extern fn free(p: ptr);
extern fn fopen(path: string, mode: string) -> ptr;
extern fn fclose(file: ptr) -> float;
extern fn _fseeki64(file: ptr, offset: float, origin: float) -> float;
extern fn fread(buffer: ptr, size: float, count: float, file: ptr) -> float;
extern fn cartan_mmap_file(path: string) -> ptr;
extern fn cartan_munmap_file(view: ptr) -> float;

// 42-Layer Pinned Contiguous KV Cache Arena in pure CARTAN heap
var g_k_cache_arena: ptr = 0.0;
var g_v_cache_arena: ptr = 0.0;
var g_native_emb_buf: ptr = 0.0;
var g_ple_mmap_ptr: ptr = 0.0;
var g_ple_file_handle: ptr = 0.0;
var s_ple_tok_buf: ptr = 0.0;
var g_ple_model_proj_ptr: ptr = 0.0;
var g_ple_proj_norm_ptr: ptr = 0.0;
var s_cached_pli: ptr = 0.0;
var s_cached_proj_all: ptr = 0.0;
var s_cached_pli_token: float = -1.0;

fn cartan_kv_cache_init() -> float {
    if (g_k_cache_arena == 0.0) {
        let total_floats = 88080384.0; // 42 layers * 2048 positions * 1024 floats
        g_k_cache_arena = calloc(total_floats, 4.0);
        g_v_cache_arena = calloc(total_floats, 4.0);
    }
    if (s_cached_pli == 0.0) {
        s_cached_pli = calloc(10752.0, 4.0); // 42 layers * 256 floats
        s_cached_proj_all = calloc(10752.0, 4.0);
    }
    if (g_k_cache_arena != 0.0 && g_v_cache_arena != 0.0) {
        return 1.0;
    }
    return 0.0;
}

fn cartan_kv_cache_reset() -> float {
    cartan_kv_cache_init();
    s_cached_pli_token = -1.0;
    return 1.0;
}

fn cartan_kv_cache_get_k(layer_idx: float) -> ptr {
    if (g_k_cache_arena == 0.0 || layer_idx < 0.0 || layer_idx >= 42.0) { return 0.0; }
    return cartan_f32_ptr_add(g_k_cache_arena, layer_idx * 2097152.0);
}

fn cartan_kv_cache_get_v(layer_idx: float) -> ptr {
    if (g_v_cache_arena == 0.0 || layer_idx < 0.0 || layer_idx >= 42.0) { return 0.0; }
    return cartan_f32_ptr_add(g_v_cache_arena, layer_idx * 2097152.0);
}

fn cartan_set_embedding_buffer(buf: ptr) -> float {
    g_native_emb_buf = buf;
    return 1.0;
}

fn cartan_mmap_ple(path: string) -> float {
    if (g_ple_file_handle != 0.0) { return 1.0; }
    let f = fopen(path, "rb");
    if (f != 0.0) {
        g_ple_file_handle = f;
        if (s_ple_tok_buf == 0.0) {
            s_ple_tok_buf = malloc(43008.0);
        }
        return 1.0;
    }
    return 0.0;
}

fn cartan_set_ple_mmap_ptr(p: ptr) {
    g_ple_mmap_ptr = p;
}

fn cartan_mmap_ple_projection(proj_path: string, norm_path: string) -> float {
    if (g_ple_model_proj_ptr == 0.0 && proj_path != "") {
        g_ple_model_proj_ptr = cartan_mmap_file(proj_path);
    }
    if (g_ple_proj_norm_ptr == 0.0 && norm_path != "") {
        g_ple_proj_norm_ptr = cartan_mmap_file(norm_path);
    }
    if (g_ple_model_proj_ptr != 0.0 && g_ple_proj_norm_ptr != 0.0) {
        return 1.0;
    }
    return 0.0;
}

fn cartan_update_pli_cache_if_needed(tok_id: float) {
    if (tok_id == s_cached_pli_token) { return; }
    s_cached_pli_token = tok_id;
    if (tok_id < 0.0 || tok_id >= 262144.0) { return; }
    if (s_cached_pli == 0.0) {
        s_cached_pli = calloc(10752.0, 4.0);
        s_cached_proj_all = calloc(10752.0, 4.0);
    }

    var ple_tok_row: ptr = 0.0;
    if (g_ple_mmap_ptr != 0.0) {
        ple_tok_row = cartan_f32_ptr_add(g_ple_mmap_ptr, tok_id * 10752.0);
    } else if (g_ple_file_handle != 0.0 && s_ple_tok_buf != 0.0) {
        let byte_offset = tok_id * 43008.0;
        _fseeki64(g_ple_file_handle, byte_offset, 0.0);
        fread(s_ple_tok_buf, 4.0, 10752.0, g_ple_file_handle);
        ple_tok_row = s_ple_tok_buf;
    }
    if (ple_tok_row == 0.0) { return; }

    if (g_ple_model_proj_ptr != 0.0 && g_ple_proj_norm_ptr != 0.0 && g_native_emb_buf != 0.0) {
        let emb_row = cartan_f32_ptr_add(g_native_emb_buf, tok_id * 2560.0);
        var j = 0.0;
        while (j < 10752.0) {
            let p_row = cartan_f32_ptr_add(g_ple_model_proj_ptr, j * 2560.0);
            let dot = cartan_simd_dot_f32(p_row, emb_row, 2560.0);
            cartan_set_f32(s_cached_proj_all, j, dot);
            j = j + 1.0;
        }

        var l = 0.0;
        while (l < 42.0) {
            let p_layer = cartan_f32_ptr_add(s_cached_proj_all, l * 256.0);
            var sq = 0.0;
            var p = 0.0;
            while (p < 256.0) {
                let pv = cartan_f32_at(p_layer, p);
                sq = sq + pv * pv;
                p = p + 1.0;
            }
            let inv_rms = 1.0 / sqrt((sq / 256.0) + 0.000001);
            let pli_layer = cartan_f32_ptr_add(s_cached_pli, l * 256.0);
            let tok_layer = cartan_f32_ptr_add(ple_tok_row, l * 256.0);
            p = 0.0;
            while (p < 256.0) {
                let pv = cartan_f32_at(p_layer, p);
                let norm_val = cartan_f32_at(g_ple_proj_norm_ptr, p);
                let norm_proj = pv * inv_rms * norm_val;
                let tok_ident = cartan_f32_at(tok_layer, p) * 16.0;
                cartan_set_f32(pli_layer, p, (norm_proj + tok_ident) * 0.70710678118);
                p = p + 1.0;
            }
            l = l + 1.0;
        }
    } else {
        var i = 0.0;
        while (i < 10752.0) {
            let tv = cartan_f32_at(ple_tok_row, i);
            cartan_set_f32(s_cached_pli, i, tv * 16.0);
            i = i + 1.0;
        }
    }
}

fn cartan_get_cached_pli(layer_idx: float, tok_id: float) -> ptr {
    cartan_update_pli_cache_if_needed(tok_id);
    if (s_cached_pli == 0.0 || layer_idx < 0.0 || layer_idx >= 42.0) { return 0.0; }
    return cartan_f32_ptr_add(s_cached_pli, layer_idx * 256.0);
}

var g_current_ple_vec: ptr = 0.0;
fn cartan_gemma_layer_set_ple_vec(ple: ptr) {
    g_current_ple_vec = ple;
}

var g_current_token_id: float = -1.0;
fn cartan_gemma_layer_set_current_token(tok: float) {
    g_current_token_id = tok;
}

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
    let out = cartan_tensor_alloc(head_dim);
    let half = head_dim / 2.0;
    var k = 0.0;
    while (k < half) {
        let x0 = cartan_vec_get_f32(vec, k);
        let x1 = cartan_vec_get_f32(vec, k + half);
        
        let exponent = (k * 2.0) / head_dim;
        var base = theta_base;
        if (base <= 0.0) { base = 10000.0; }
        let freq = 1.0 / pow(base, exponent);
        let theta = pos * freq;
        let c = cos(theta);
        let s = sin(theta);

        // Canonical Gemma / HuggingFace rotate_half:
        // out[k] = x0 * cos - x1 * sin
        // out[k + half] = x1 * cos + x0 * sin
        let rx0 = x0 * c - x1 * s;
        let rx1 = x1 * c + x0 * s;
        cartan_vec_set_f32(out, k, rx0);
        cartan_vec_set_f32(out, k + half, rx1);
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

// -----------------------------------------------------------------------------
// 7. Gemma Per-Head RMSNorm (QK-Norm)
// Normalizes each of the num_heads slices of size head_dim independently
// -----------------------------------------------------------------------------
fn cartan_rmsnorm_head(vec: ptr, w: ptr, num_heads: float, head_dim: float, eps: float) -> ptr {
    if (vec == 0.0 || num_heads <= 0.0 || head_dim <= 0.0) { return 0.0; }
    let total_dim = num_heads * head_dim;
    let out = cartan_vec_create();
    var h = 0.0;
    while (h < num_heads) {
        let head_off = h * head_dim;
        var sum_sq = 0.0;
        var d = 0.0;
        while (d < head_dim) {
            let val = cartan_vec_get_f32(vec, head_off + d);
            sum_sq = sum_sq + val * val;
            d = d + 1.0;
        }
        let inv_rms = 1.0 / sqrt((sum_sq / head_dim) + eps);
        d = 0.0;
        while (d < head_dim) {
            let val = cartan_vec_get_f32(vec, head_off + d);
            var scale = 1.0;
            if (w != 0.0) {
                scale = cartan_vec_get_f32(w, d);
            }
            cartan_vec_push_f32(out, val * inv_rms * scale);
            d = d + 1.0;
        }
        h = h + 1.0;
    }
    return out;
}

// -----------------------------------------------------------------------------
// 8. GeGLU Feedforward MLP (Gemma 4 Standard Activation)
// FFN(x) = (GELU_tanh(x * W_gate) * (x * W_up)) * W_down
// -----------------------------------------------------------------------------
fn cartan_geglu_mlp_forward(x: ptr, gate_w: ptr, up_w: ptr, down_w: ptr, in_dim: float, inter_dim: float) -> ptr {
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
        let act = cartan_gelu_tanh(dot_gate) * dot_up;
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
// 9. Per-Layer Embedding (PLE) Gating Block (Gemma 4 Architecture)
// gate = GELU_tanh(W_ple_gate * h) * ple_vec
// h_out = h + RMSNorm(W_ple_proj * gate, norm_w)
// -----------------------------------------------------------------------------
fn cartan_ple_gate_forward(h: ptr, ple_vec: ptr, gate_w: ptr, proj_w: ptr, norm_w: ptr, dim: float, ple_dim: float) -> ptr {
    if (h == 0.0 || ple_vec == 0.0 || dim <= 0.0 || ple_dim <= 0.0) { return h; }
    if (gate_w == 0.0 || proj_w == 0.0) { return h; }

    // 1. Project h to PLE dimension: [ple_dim]
    let act_ple = cartan_vec_create();
    var p = 0.0;
    while (p < ple_dim) {
        var dot_gate = 0.0;
        var d = 0.0;
        let row_off = p * dim;
        while (d < dim) {
            let hd = cartan_vec_get_f32(h, d);
            dot_gate = dot_gate + hd * cartan_vec_get_f32(gate_w, row_off + d);
            d = d + 1.0;
        }
        let ple_val = cartan_vec_get_f32(ple_vec, p);
        let act = cartan_gelu_tanh(dot_gate) * ple_val;
        cartan_vec_push_f32(act_ple, act);
        p = p + 1.0;
    }

    // 2. Project back to hidden dimension: [dim]
    let raw_proj = cartan_vec_create();
    var d_out = 0.0;
    while (d_out < dim) {
        var dot_proj = 0.0;
        p = 0.0;
        let proj_row = d_out * ple_dim;
        while (p < ple_dim) {
            let ap = cartan_vec_get_f32(act_ple, p);
            dot_proj = dot_proj + ap * cartan_vec_get_f32(proj_w, proj_row + p);
            p = p + 1.0;
        }
        cartan_vec_push_f32(raw_proj, dot_proj);
        d_out = d_out + 1.0;
    }
    cartan_vec_free(act_ple);

    // 3. Post-PLE RMSNorm
    let normed_proj = cartan_rmsnorm(raw_proj, norm_w, dim, 0.000001);
    cartan_vec_free(raw_proj);

    // 4. Residual Addition
    let out = cartan_vec_create();
    d_out = 0.0;
    while (d_out < dim) {
        let orig = cartan_vec_get_f32(h, d_out);
        let add_val = cartan_vec_get_f32(normed_proj, d_out);
        cartan_vec_push_f32(out, orig + add_val);
        d_out = d_out + 1.0;
    }
    cartan_vec_free(normed_proj);
    return out;
}

// -----------------------------------------------------------------------------
// 10. Logit Soft-Capping (Gemma 4 Standard: cap = 30.0)
// capped_logit = cap * tanh(logit / cap)
// -----------------------------------------------------------------------------
fn cartan_logit_softcap(logits: ptr, cap: float) -> ptr {
    if (logits == 0.0 || cap <= 0.0) { return logits; }
    let len = cartan_vec_len(logits);
    var i = 0.0;
    let inv_cap = 1.0 / cap;
    while (i < len) {
        let val = cartan_vec_get_f32(logits, i);
        let capped = cap * tanh(val * inv_cap);
        cartan_vec_set_f32(logits, i, capped);
        i = i + 1.0;
    }
    return logits;
}

// -----------------------------------------------------------------------------
// 11. Complete Gemma 4 Causal Transformer Decoder Layer Forward Step
// Supports per-head QK-Norm, sliding (d_head=256) and global (d_head=512) attention,
// dual-theta RoPE, GeGLU MLP, PLE gating, and layer scalar multiplication.
// -----------------------------------------------------------------------------
fn cartan_gemma_layer_forward(
    h: ptr,
    w_q: ptr, w_k: ptr, w_v: ptr, w_o: ptr,
    q_norm_w: ptr, k_norm_w: ptr,
    norm_attn_w: ptr, norm_ffn_w: ptr,
    post_attn_norm_w: ptr, post_ffn_norm_w: ptr,
    gate_w: ptr, up_w: ptr, down_w: ptr,
    ple_vec: ptr, ple_gate_w: ptr, ple_proj_w: ptr, ple_norm_w: ptr,
    layer_scalar: float,
    pos: float, seq_len: float, dim: float, inter_dim: float,
    q_heads: float, kv_heads: float, head_dim: float, rope_theta: float,
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

    // 3. Per-Head Q-Norm
    let q_normed = cartan_rmsnorm_head(q_raw, q_norm_w, q_heads, head_dim, 0.000001);
    cartan_vec_free(q_raw);

    // 4. Apply RoPE on Query heads with dynamic rope_theta
    let q_rot = cartan_vec_create();
    var qh = 0.0;
    while (qh < q_heads) {
        let single_head = cartan_vec_create();
        var hd = 0.0;
        let head_off = qh * head_dim;
        while (hd < head_dim) {
            cartan_vec_push_f32(single_head, cartan_vec_get_f32(q_normed, head_off + hd));
            hd = hd + 1.0;
        }
        var theta_val = rope_theta;
        if (theta_val <= 0.0) { theta_val = 10000.0; }
        let rot_head = cartan_rope_apply(single_head, pos, head_dim, theta_val);
        hd = 0.0;
        while (hd < head_dim) {
            cartan_vec_push_f32(q_rot, cartan_vec_get_f32(rot_head, hd));
            hd = hd + 1.0;
        }
        cartan_vec_free(single_head);
        cartan_vec_free(rot_head);
        qh = qh + 1.0;
    }
    cartan_vec_free(q_normed);

    // 5. Multi-Head GQA Attention
    let attn_heads_out = cartan_gqa_causal_attention(q_rot, k_cache, v_cache, seq_len, q_heads, kv_heads, head_dim);
    cartan_vec_free(q_rot);

    // 6. Output projection W_o: [q_dim] -> [dim] & Post-Attention RMSNorm
    let o_raw = cartan_vec_create();
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
        cartan_vec_push_f32(o_raw, dot_o);
        d = d + 1.0;
    }
    cartan_vec_free(normed_h1);
    cartan_vec_free(attn_heads_out);

    var o_normed = o_raw;
    if (post_attn_norm_w != 0.0) {
        o_normed = cartan_rmsnorm(o_raw, post_attn_norm_w, dim, 0.000001);
        cartan_vec_free(o_raw);
    }

    // Residual Addition: h1 = h + o_normed
    let h1 = cartan_vec_create();
    d = 0.0;
    while (d < dim) {
        let orig = cartan_vec_get_f32(h, d);
        let add_o = cartan_vec_get_f32(o_normed, d);
        cartan_vec_push_f32(h1, orig + add_o);
        d = d + 1.0;
    }
    cartan_vec_free(o_normed);

    // 7. Pre-FFN RMSNorm
    let normed_h2 = cartan_rmsnorm(h1, norm_ffn_w, dim, 0.000001);

    // 8. GeGLU MLP & Post-FFN RMSNorm
    let ffn_raw = cartan_geglu_mlp_forward(normed_h2, gate_w, up_w, down_w, dim, inter_dim);
    cartan_vec_free(normed_h2);

    var ffn_normed = ffn_raw;
    if (post_ffn_norm_w != 0.0) {
        ffn_normed = cartan_rmsnorm(ffn_raw, post_ffn_norm_w, dim, 0.000001);
        cartan_vec_free(ffn_raw);
    }

    // Residual Addition: h2 = h1 + ffn_normed
    let h2 = cartan_vec_create();
    d = 0.0;
    while (d < dim) {
        let val1 = cartan_vec_get_f32(h1, d);
        let ffn_val = cartan_vec_get_f32(ffn_normed, d);
        cartan_vec_push_f32(h2, val1 + ffn_val);
        d = d + 1.0;
    }
    cartan_vec_free(h1);
    cartan_vec_free(ffn_normed);

    // 9. Per-Layer Embedding (PLE) Gating
    var h3 = h2;
    if (ple_vec != 0.0 && ple_gate_w != 0.0 && ple_proj_w != 0.0) {
        h3 = cartan_ple_gate_forward(h2, ple_vec, ple_gate_w, ple_proj_w, ple_norm_w, dim, 256.0);
        cartan_vec_free(h2);
    }

    // 10. Layer Scalar Multiplier
    var scalar_val = layer_scalar;
    if (scalar_val == 0.0) { scalar_val = 1.0; }
    let h_out = cartan_vec_create();
    d = 0.0;
    while (d < dim) {
        let v = cartan_vec_get_f32(h3, d);
        cartan_vec_push_f32(h_out, v * scalar_val);
        d = d + 1.0;
    }
    cartan_vec_free(h3);

    return h_out;
}

// -----------------------------------------------------------------------------
// 12. Ultra-Fast In-Place Gemma 4 Transformer Decoder Layer Forward from Raw Binary Buffer
// -----------------------------------------------------------------------------
// Pure Native CARTAN Fast GELU Tanh Activation
// -----------------------------------------------------------------------------
fn cartan_fast_gelu_tanh(x: float) -> float {
    let x3 = x * x * x;
    let inner = 0.79788456 * (x + 0.044715 * x3);
    return 0.5 * x * (1.0 + tanh(inner));
}

// -----------------------------------------------------------------------------
// Pinned Zero-Allocation Scratch Buffers for Pure Native CARTAN Decoder
// -----------------------------------------------------------------------------
var g_trans_scratch_init: float = 0.0;
var g_trans_x_buf: ptr = 0.0;
var g_trans_norm_h1: ptr = 0.0;
var g_trans_q_raw: ptr = 0.0;
var g_trans_q_norm: ptr = 0.0;
var g_trans_q_rot: ptr = 0.0;
var g_trans_k_raw: ptr = 0.0;
var g_trans_k_norm: ptr = 0.0;
var g_trans_k_rot: ptr = 0.0;
var g_trans_v_raw: ptr = 0.0;
var g_trans_attn_out: ptr = 0.0;
var g_trans_scores: ptr = 0.0;
var g_trans_o_raw: ptr = 0.0;
var g_trans_h1: ptr = 0.0;
var g_trans_norm_h2: ptr = 0.0;
var g_trans_act_buf: ptr = 0.0;
var g_trans_ffn_raw: ptr = 0.0;
var g_trans_h2: ptr = 0.0;
var g_trans_ple_act: ptr = 0.0;
var g_trans_ple_proj: ptr = 0.0;
var g_trans_h3: ptr = 0.0;

fn cartan_init_transformer_scratch_buffers() -> float {
    if (g_trans_scratch_init == 1.0) { return 1.0; }
    g_trans_x_buf = malloc(4096.0 * 4.0);
    g_trans_norm_h1 = malloc(4096.0 * 4.0);
    g_trans_q_raw = malloc(4096.0 * 4.0);
    g_trans_q_norm = malloc(4096.0 * 4.0);
    g_trans_q_rot = malloc(4096.0 * 4.0);
    g_trans_k_raw = malloc(1024.0 * 4.0);
    g_trans_k_norm = malloc(1024.0 * 4.0);
    g_trans_k_rot = malloc(1024.0 * 4.0);
    g_trans_v_raw = malloc(1024.0 * 4.0);
    g_trans_attn_out = malloc(4096.0 * 4.0);
    g_trans_scores = malloc(4096.0 * 4.0);
    g_trans_o_raw = malloc(4096.0 * 4.0);
    g_trans_h1 = malloc(4096.0 * 4.0);
    g_trans_norm_h2 = malloc(4096.0 * 4.0);
    g_trans_act_buf = malloc(16384.0 * 4.0);
    g_trans_ffn_raw = malloc(4096.0 * 4.0);
    g_trans_h2 = malloc(4096.0 * 4.0);
    g_trans_ple_act = malloc(512.0 * 4.0);
    g_trans_ple_proj = malloc(4096.0 * 4.0);
    g_trans_h3 = malloc(4096.0 * 4.0);
    g_trans_scratch_init = 1.0;
    return 1.0;
}

// -----------------------------------------------------------------------------
// Pure Native CARTAN Gemma Decoder Layer Forward Kernel
// Direct AVX2 SIMD FMA execution with zero intermediate allocations
// -----------------------------------------------------------------------------
fn cartan_gemma_layer_forward_native(
    h_out_vec: ptr,
    h_in_vec: ptr,
    layer_buf: ptr,
    pos: float,
    seq_len: float,
    tok_id: float
) -> float {
    if (h_out_vec == 0.0 || h_in_vec == 0.0 || layer_buf == 0.0) { return 0.0; }
    cartan_init_transformer_scratch_buffers();
    cartan_kv_cache_init();

    let layer_idx = cartan_f32_at(layer_buf, 1.0);
    var head_dim = cartan_f32_at(layer_buf, 2.0);
    if (head_dim <= 0.0) { head_dim = 256.0; }
    var rope_theta = cartan_f32_at(layer_buf, 3.0);
    if (rope_theta <= 0.0) { rope_theta = 10000.0; }
    var layer_scalar = cartan_f32_at(layer_buf, 4.0);
    if (layer_scalar == 0.0) { layer_scalar = 1.0; }
    let has_ple = cartan_f32_at(layer_buf, 5.0);
    let dim = cartan_f32_at(layer_buf, 6.0);
    let inter_dim = cartan_f32_at(layer_buf, 7.0);
    let q_dim = cartan_f32_at(layer_buf, 8.0);
    let kv_dim = cartan_f32_at(layer_buf, 9.0);
    let ple_dim = cartan_f32_at(layer_buf, 10.0);

    let q_heads = q_dim / head_dim;
    var kv_heads = kv_dim / head_dim;
    if (kv_heads <= 0.0) { kv_heads = 1.0; }
    let heads_per_kv = q_heads / kv_heads;

    let off_in_norm = 16.0;
    let off_w_q = 2576.0;
    let off_w_k = off_w_q + q_dim * dim;
    let off_w_v = off_w_k + kv_dim * dim;
    let off_w_o = off_w_v + kv_dim * dim;
    let off_q_norm = off_w_o + dim * q_dim;
    let off_k_norm = off_q_norm + 512.0;
    let off_post_attn_norm = off_k_norm + 512.0;
    let off_pre_ffn_norm = off_post_attn_norm + dim;
    let off_gate_proj = off_pre_ffn_norm + dim;
    let off_up_proj = off_gate_proj + inter_dim * dim;
    let off_down_proj = off_up_proj + inter_dim * dim;
    let off_post_ffn_norm = off_down_proj + dim * inter_dim;
    let off_ple_gate = off_post_ffn_norm + dim;
    let off_ple_proj = off_ple_gate + ple_dim * dim;
    let off_ple_norm = off_ple_proj + dim * ple_dim;

    let w_in_norm = cartan_f32_ptr_add(layer_buf, off_in_norm);
    let w_q = cartan_f32_ptr_add(layer_buf, off_w_q);
    let w_k = cartan_f32_ptr_add(layer_buf, off_w_k);
    let w_v = cartan_f32_ptr_add(layer_buf, off_w_v);
    let w_o = cartan_f32_ptr_add(layer_buf, off_w_o);
    let w_q_norm = cartan_f32_ptr_add(layer_buf, off_q_norm);
    let w_k_norm = cartan_f32_ptr_add(layer_buf, off_k_norm);
    let w_post_attn = cartan_f32_ptr_add(layer_buf, off_post_attn_norm);
    let w_pre_ffn = cartan_f32_ptr_add(layer_buf, off_pre_ffn_norm);
    let w_gate = cartan_f32_ptr_add(layer_buf, off_gate_proj);
    let w_up = cartan_f32_ptr_add(layer_buf, off_up_proj);
    let w_down = cartan_f32_ptr_add(layer_buf, off_down_proj);
    let w_post_ffn = cartan_f32_ptr_add(layer_buf, off_post_ffn_norm);
    let w_ple_gate = cartan_f32_ptr_add(layer_buf, off_ple_gate);
    let w_ple_proj = cartan_f32_ptr_add(layer_buf, off_ple_proj);
    let w_ple_norm = cartan_f32_ptr_add(layer_buf, off_ple_norm);

    // Extract input vector into scratch float buffer
    var d = 0.0;
    while (d < dim) {
        cartan_set_f32(g_trans_x_buf, d, cartan_vec_get_f32(h_in_vec, d));
        d = d + 1.0;
    }

    // 1. Pre-Attention RMSNorm: bar(h)_1 = RMSNorm(h, w_in_norm)
    var sum_sq = 0.0;
    d = 0.0;
    while (d < dim) {
        let val = cartan_f32_at(g_trans_x_buf, d);
        sum_sq = sum_sq + val * val;
        d = d + 1.0;
    }
    let inv_rms1 = 1.0 / sqrt((sum_sq / dim) + 0.000001);
    d = 0.0;
    while (d < dim) {
        let val = cartan_f32_at(g_trans_x_buf, d);
        let w = cartan_f32_at(w_in_norm, d);
        cartan_set_f32(g_trans_norm_h1, d, val * inv_rms1 * w);
        d = d + 1.0;
    }

    // 2. Q Projections (AVX2 GEMV)
    var qi = 0.0;
    while (qi < q_dim) {
        let q_row = cartan_f32_ptr_add(w_q, qi * dim);
        let dot = cartan_simd_dot_f32(q_row, g_trans_norm_h1, dim);
        cartan_set_f32(g_trans_q_raw, qi, dot);
        qi = qi + 1.0;
    }

    // 3. Per-Head Q-Norm
    var qh = 0.0;
    while (qh < q_heads) {
        let qh_base = qh * head_dim;
        var h_sq = 0.0;
        var hd = 0.0;
        while (hd < head_dim) {
            let v = cartan_f32_at(g_trans_q_raw, qh_base + hd);
            h_sq = h_sq + v * v;
            hd = hd + 1.0;
        }
        let inv_q_rms = 1.0 / sqrt((h_sq / head_dim) + 0.000001);
        hd = 0.0;
        while (hd < head_dim) {
            let v = cartan_f32_at(g_trans_q_raw, qh_base + hd);
            let w = cartan_f32_at(w_q_norm, hd);
            cartan_set_f32(g_trans_q_norm, qh_base + hd, v * inv_q_rms * w);
            hd = hd + 1.0;
        }
        qh = qh + 1.0;
    }

    let half = head_dim / 2.0;
    let is_global = (fmod(layer_idx + 1.0, 6.0) == 0.0);
    var rope_angles = half;
    if (is_global > 0.0) {
        rope_angles = 64.0;
    }

    // 4. RoPE on Q heads (Gemma rotate_half with proportional rotary factor)
    qh = 0.0;
    while (qh < q_heads) {
        let qh_base = qh * head_dim;
        var k = 0.0;
        while (k < half) {
            let x0 = cartan_f32_at(g_trans_q_norm, qh_base + k);
            let x1 = cartan_f32_at(g_trans_q_norm, qh_base + k + half);
            var c = 1.0;
            var s = 0.0;
            if (k < rope_angles) {
                let exponent = (k * 2.0) / head_dim;
                let freq = 1.0 / pow(rope_theta, exponent);
                let theta = pos * freq;
                c = cos(theta);
                s = sin(theta);
            }
            cartan_set_f32(g_trans_q_rot, qh_base + k, x0 * c - x1 * s);
            cartan_set_f32(g_trans_q_rot, qh_base + k + half, x1 * c + x0 * s);
            k = k + 1.0;
        }
        qh = qh + 1.0;
    }
    let is_kv_shared = (layer_idx >= 24.0);
    var kv_source_layer = layer_idx;
    if (is_kv_shared > 0.0) {
        if (is_global > 0.0) {
            kv_source_layer = 23.0;
        } else {
            kv_source_layer = 22.0;
        }
    }

    if (is_kv_shared == 0.0) {
        var kvi = 0.0;
        while (kvi < kv_dim) {
            let k_row = cartan_f32_ptr_add(w_k, kvi * dim);
            let v_row = cartan_f32_ptr_add(w_v, kvi * dim);
            cartan_set_f32(g_trans_k_raw, kvi, cartan_simd_dot_f32(k_row, g_trans_norm_h1, dim));
            cartan_set_f32(g_trans_v_raw, kvi, cartan_simd_dot_f32(v_row, g_trans_norm_h1, dim));
            kvi = kvi + 1.0;
        }

        var kvh = 0.0;
        while (kvh < kv_heads) {
            let kh_base = kvh * head_dim;
            var kh_sq = 0.0;
            var hd = 0.0;
            while (hd < head_dim) {
                let v = cartan_f32_at(g_trans_k_raw, kh_base + hd);
                kh_sq = kh_sq + v * v;
                hd = hd + 1.0;
            }
            let inv_k_rms = 1.0 / sqrt((kh_sq / head_dim) + 0.000001);
            hd = 0.0;
            while (hd < head_dim) {
                let v = cartan_f32_at(g_trans_k_raw, kh_base + hd);
                let w = cartan_f32_at(w_k_norm, hd);
                cartan_set_f32(g_trans_k_norm, kh_base + hd, v * inv_k_rms * w);
                hd = hd + 1.0;
            }
            kvh = kvh + 1.0;
        }

        kvh = 0.0;
        while (kvh < kv_heads) {
            let kh_base = kvh * head_dim;
            var k = 0.0;
            while (k < half) {
                let x0 = cartan_f32_at(g_trans_k_norm, kh_base + k);
                let x1 = cartan_f32_at(g_trans_k_norm, kh_base + k + half);
                var c = 1.0;
                var s = 0.0;
                if (k < rope_angles) {
                    let exponent = (k * 2.0) / head_dim;
                    let freq = 1.0 / pow(rope_theta, exponent);
                    let theta = pos * freq;
                    c = cos(theta);
                    s = sin(theta);
                }
                cartan_set_f32(g_trans_k_rot, kh_base + k, x0 * c - x1 * s);
                cartan_set_f32(g_trans_k_rot, kh_base + k + half, x1 * c + x0 * s);
                k = k + 1.0;
            }
            kvh = kvh + 1.0;
        }

        // 5. Append to Contiguous KV Cache Arena
        let k_layer_base = cartan_kv_cache_get_k(layer_idx);
        let v_layer_base = cartan_kv_cache_get_v(layer_idx);
        if (k_layer_base != 0.0 && v_layer_base != 0.0 && layer_idx >= 0.0 && layer_idx < 42.0 && pos >= 0.0 && pos < 2048.0) {
            let k_dst = cartan_f32_ptr_add(k_layer_base, pos * kv_dim);
            let v_dst = cartan_f32_ptr_add(v_layer_base, pos * kv_dim);
            cartan_c_memcpy(k_dst, g_trans_k_rot, kv_dim * 4.0);

            // Gemma 4 v_norm: unit RMS normalization per KV head (with_scale=False)
            var h = 0.0;
            while (h < kv_heads) {
                let v_base = h * head_dim;
                var v_sq = 0.0;
                var hd = 0.0;
                while (hd < head_dim) {
                    let val = cartan_f32_at(g_trans_v_raw, v_base + hd);
                    v_sq = v_sq + val * val;
                    hd = hd + 1.0;
                }
                let inv_v_rms = 1.0 / sqrt((v_sq / head_dim) + 0.000001);
                let v_dst_h = cartan_f32_ptr_add(v_dst, v_base);
                hd = 0.0;
                while (hd < head_dim) {
                    let val = cartan_f32_at(g_trans_v_raw, v_base + hd);
                    cartan_set_f32(v_dst_h, hd, val * inv_v_rms);
                    hd = hd + 1.0;
                }
                h = h + 1.0;
            }
        }
    }

    // 6. GQA Causal Attention (reusing KV from kv_source_layer for shared layers)
    let k_cache = cartan_kv_cache_get_k(kv_source_layer);
    let v_cache = cartan_kv_cache_get_v(kv_source_layer);
    var max_seq = pos + 1.0;
    if (max_seq > 4096.0) { max_seq = 4096.0; }

    qh = 0.0;
    while (qh < q_heads) {
        let kvh = floor(qh / heads_per_kv);
        let q_h = cartan_f32_ptr_add(g_trans_q_rot, qh * head_dim);
        var max_score = -1000000000.0;

        var t = 0.0;
        while (t < max_seq) {
            var dot = 0.0;
            if (k_cache != 0.0) {
                let k_ht = cartan_f32_ptr_add(k_cache, t * kv_dim + kvh * head_dim);
                dot = cartan_simd_dot_f32(q_h, k_ht, head_dim);
            }
            cartan_set_f32(g_trans_scores, t, dot);
            if (dot > max_score) { max_score = dot; }
            t = t + 1.0;
        }

        var sum_exp = 0.0;
        t = 0.0;
        while (t < max_seq) {
            let ep = exp(cartan_f32_at(g_trans_scores, t) - max_score);
            cartan_set_f32(g_trans_scores, t, ep);
            sum_exp = sum_exp + ep;
            t = t + 1.0;
        }
        var inv_sum = 1.0;
        if (sum_exp > 0.000000000001) { inv_sum = 1.0 / sum_exp; }

        let out_h = cartan_f32_ptr_add(g_trans_attn_out, qh * head_dim);
        var hd = 0.0;
        while (hd < head_dim) {
            var weighted = 0.0;
            if (v_cache != 0.0) {
                t = 0.0;
                while (t < max_seq) {
                    let p_t = cartan_f32_at(g_trans_scores, t) * inv_sum;
                    let v_ht = cartan_f32_ptr_add(v_cache, t * kv_dim + kvh * head_dim);
                    weighted = weighted + p_t * cartan_f32_at(v_ht, hd);
                    t = t + 1.0;
                }
            }
            cartan_set_f32(out_h, hd, weighted);
            hd = hd + 1.0;
        }
        qh = qh + 1.0;
    }

    // 7. Output Projection W_o + Post-Attention RMSNorm + Residual
    var o_sq_sum = 0.0;
    d = 0.0;
    while (d < dim) {
        let o_row = cartan_f32_ptr_add(w_o, d * q_dim);
        let dot_o = cartan_simd_dot_f32(o_row, g_trans_attn_out, q_dim);
        cartan_set_f32(g_trans_o_raw, d, dot_o);
        o_sq_sum = o_sq_sum + dot_o * dot_o;
        d = d + 1.0;
    }
    let inv_o_rms = 1.0 / sqrt((o_sq_sum / dim) + 0.000001);
    d = 0.0;
    while (d < dim) {
        let x = cartan_f32_at(g_trans_x_buf, d);
        let o = cartan_f32_at(g_trans_o_raw, d);
        let w = cartan_f32_at(w_post_attn, d);
        cartan_set_f32(g_trans_h1, d, x + o * inv_o_rms * w);
        d = d + 1.0;
    }

    // 8. Pre-FFN RMSNorm
    var h1_sq_sum = 0.0;
    d = 0.0;
    while (d < dim) {
        let val = cartan_f32_at(g_trans_h1, d);
        h1_sq_sum = h1_sq_sum + val * val;
        d = d + 1.0;
    }
    let inv_h1_rms = 1.0 / sqrt((h1_sq_sum / dim) + 0.000001);
    d = 0.0;
    while (d < dim) {
        let val = cartan_f32_at(g_trans_h1, d);
        let w = cartan_f32_at(w_pre_ffn, d);
        cartan_set_f32(g_trans_norm_h2, d, val * inv_h1_rms * w);
        d = d + 1.0;
    }

    // 9. GeGLU MLP: act[j] = GELU_tanh(dot_gate) * dot_up, down_proj, post-FFN norm + residual
    var j = 0.0;
    while (j < inter_dim) {
        let g_row = cartan_f32_ptr_add(w_gate, j * dim);
        let u_row = cartan_f32_ptr_add(w_up, j * dim);
        let dot_gate = cartan_simd_dot_f32(g_row, g_trans_norm_h2, dim);
        let dot_up = cartan_simd_dot_f32(u_row, g_trans_norm_h2, dim);
        cartan_set_f32(g_trans_act_buf, j, cartan_fast_gelu_tanh(dot_gate) * dot_up);
        j = j + 1.0;
    }

    var ffn_sq_sum = 0.0;
    d = 0.0;
    while (d < dim) {
        let d_row = cartan_f32_ptr_add(w_down, d * inter_dim);
        let dot_down = cartan_simd_dot_f32(d_row, g_trans_act_buf, inter_dim);
        cartan_set_f32(g_trans_ffn_raw, d, dot_down);
        ffn_sq_sum = ffn_sq_sum + dot_down * dot_down;
        d = d + 1.0;
    }
    let inv_ffn_rms = 1.0 / sqrt((ffn_sq_sum / dim) + 0.000001);
    d = 0.0;
    while (d < dim) {
        let h1_val = cartan_f32_at(g_trans_h1, d);
        let ffn_val = cartan_f32_at(g_trans_ffn_raw, d);
        let w = cartan_f32_at(w_post_ffn, d);
        cartan_set_f32(g_trans_h2, d, h1_val + ffn_val * inv_ffn_rms * w);
        d = d + 1.0;
    }

    // 10. Per-Layer Embedding (PLE) Gating
    if (has_ple > 0.0 && tok_id >= 0.0 && tok_id < 262144.0) {
        let pli_l = cartan_get_cached_pli(layer_idx, tok_id);
        if (pli_l != 0.0) {
            var p = 0.0;
            while (p < ple_dim) {
                let g_row = cartan_f32_ptr_add(w_ple_gate, p * dim);
                let dot_gate = cartan_simd_dot_f32(g_row, g_trans_h2, dim);
                let pli_val = cartan_f32_at(pli_l, p);
                cartan_set_f32(g_trans_ple_act, p, cartan_fast_gelu_tanh(dot_gate) * pli_val);
                p = p + 1.0;
            }
            var ple_sq = 0.0;
            d = 0.0;
            while (d < dim) {
                let p_row = cartan_f32_ptr_add(w_ple_proj, d * ple_dim);
                let dot_p = cartan_simd_dot_f32(p_row, g_trans_ple_act, ple_dim);
                cartan_set_f32(g_trans_ple_proj, d, dot_p);
                ple_sq = ple_sq + dot_p * dot_p;
                d = d + 1.0;
            }
            let inv_ple_rms = 1.0 / sqrt((ple_sq / dim) + 0.000001);
            d = 0.0;
            while (d < dim) {
                let h2_val = cartan_f32_at(g_trans_h2, d);
                let proj_val = cartan_f32_at(g_trans_ple_proj, d);
                let norm_val = cartan_f32_at(w_ple_norm, d);
                cartan_set_f32(g_trans_h3, d, h2_val + proj_val * inv_ple_rms * norm_val);
                d = d + 1.0;
            }
        } else {
            d = 0.0;
            while (d < dim) {
                cartan_set_f32(g_trans_h3, d, cartan_f32_at(g_trans_h2, d));
                d = d + 1.0;
            }
        }
    } else {
        d = 0.0;
        while (d < dim) {
            cartan_set_f32(g_trans_h3, d, cartan_f32_at(g_trans_h2, d));
            d = d + 1.0;
        }
    }

    // 11. Layer Scalar Scaling & CARTAN Vector Output
    d = 0.0;
    while (d < dim) {
        cartan_vec_set_f32(h_out_vec, d, cartan_f32_at(g_trans_h3, d) * layer_scalar);
        d = d + 1.0;
    }
    return 1.0;
}

// -----------------------------------------------------------------------------
// 12. Ultra-Fast In-Place Gemma 4 Transformer Decoder Layer Forward from Raw Binary Buffer
// Pure Native CARTAN decoder using hardware SIMD FMA dot products
// -----------------------------------------------------------------------------
fn cartan_gemma_layer_forward_raw(
    h: ptr,
    layer_buf: ptr,
    pos: float,
    seq_len: float,
    k_cache: ptr,
    v_cache: ptr
) -> ptr {
    if (h == 0.0 || layer_buf == 0.0) { return 0.0; }
    let dim = cartan_f32_at(layer_buf, 6.0);
    let h_out = cartan_tensor_alloc(dim);
    cartan_gemma_layer_forward_native(h_out, h, layer_buf, pos, seq_len, g_current_token_id);
    return h_out;
}



