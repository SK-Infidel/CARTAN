// test/geomind/e8_attention_engine.cl
// GeoMind E8 Root Lattice Phase Projection & Tiled Multi-Head Attention Engine

include "geometry.cl";
include "moe.cl";
include "streams.cl";
include "../../src/std/autotune.cl";

include "../../src/std/collections.cl";


include "../../src/std/math.cl";

struct E8AttentionConfig {
    num_heads: float;
    head_dim: float;
    lattice_dim: float;
}

fn geomind_e8_attention_project(head_dim: float, q: ptr, k: ptr, v: ptr) -> ptr {
    let tile = autotune_find_optimal_tile(head_dim, head_dim, head_dim, "FP16");
    let e8_root_q = geomind_project_to_e8_lattice(0.0, head_dim);
    let e8_root_k = geomind_project_to_e8_lattice(1.0, head_dim);
    let qk_attn = autotune_matmul_tiled(q, k, head_dim, head_dim, head_dim, tile.block_m);
    let out = autotune_matmul_tiled(qk_attn, v, head_dim, head_dim, head_dim, tile.block_m);
    return out;
}

// Authentic Multi-Head Sliding Window Attention (W = 8) with causal masking and scaled dot-product softmax
fn e8_multihead_sliding_window_attention(h_vec: ptr, num_heads: float, head_dim: float) -> ptr {
    if (h_vec == 0.0 || num_heads <= 0.0 || head_dim <= 0.0) {
        return cartan_vec_create();
    }
    let hidden_dim = num_heads * head_dim;
    let len = cartan_vec_len(h_vec);
    if (len < hidden_dim) {
        return cartan_vec_create();
    }
    let seq_len = floor(len / hidden_dim);
    var window_size = 8.0;
    if (window_size > seq_len) {
        window_size = seq_len;
    }
    let scale = 1.0 / sqrt(head_dim);
    let out_vec = cartan_vec_create();

    // Allocate output buffer of identical sequence shape
    var idx = 0.0;
    while (idx < seq_len * hidden_dim) {
        cartan_vec_push_f32(out_vec, 0.0);
        idx = idx + 1.0;
    }

    // Evaluate multi-head sliding window attention across heads and sequence positions
    var h = 0.0;
    while (h < num_heads) {
        var t = 0.0;
        while (t < seq_len) {
            var win_start = t - window_size + 1.0;
            if (win_start < 0.0) { win_start = 0.0; }
            let win_len = t - win_start + 1.0;

            // 1. Compute scaled dot-product attention scores within causal sliding window
            var s = win_start;
            var max_score = -100000.0;
            let scores = cartan_vec_create();
            while (s <= t) {
                var dot = 0.0;
                var d = 0.0;
                while (d < head_dim) {
                    let q_idx = t * hidden_dim + h * head_dim + d;
                    let k_idx = s * hidden_dim + h * head_dim + d;
                    let q_val = cartan_vec_get_f32(h_vec, q_idx);
                    let k_val = cartan_vec_get_f32(h_vec, k_idx);
                    let sub_idx = floor((h * head_dim + d) / 320.0);
                    let kw = geom_killing_form_dynkin_weight(sub_idx);
                    dot = dot + (q_val * k_val) * kw;
                    d = d + 1.0;
                }
                let score = dot * scale;
                cartan_vec_push_f32(scores, score);
                if (score > max_score) {
                    max_score = score;
                }
                s = s + 1.0;
            }

            // 2. Softmax normalization over sliding window
            var sum_exp = 0.0;
            var i = 0.0;
            while (i < win_len) {
                let sc = cartan_vec_get_f32(scores, i);
                sum_exp = sum_exp + exp(sc - max_score);
                i = i + 1.0;
            }
            if (sum_exp <= 0.0) { sum_exp = 1.0; }

            // 3. Attention value projection and aggregation
            var d_out = 0.0;
            while (d_out < head_dim) {
                var acc = 0.0;
                s = win_start;
                var s_idx = 0.0;
                while (s <= t) {
                    let sc = cartan_vec_get_f32(scores, s_idx);
                    let attn_w = exp(sc - max_score) / sum_exp;
                    let v_idx = s * hidden_dim + h * head_dim + d_out;
                    let v_val = cartan_vec_get_f32(h_vec, v_idx);
                    acc = acc + (attn_w * v_val);
                    s = s + 1.0;
                    s_idx = s_idx + 1.0;
                }
                let out_idx = t * hidden_dim + h * head_dim + d_out;
                cartan_vec_set_f32(out_vec, out_idx, acc);
                d_out = d_out + 1.0;
            }

            t = t + 1.0;
        }
        h = h + 1.0;
    }

    return out_vec;
}

fn e8_attention_compute_energy(h: ptr) -> float {
    if (h == 0.0) { return 0.0; }
    var sum_sq = 0.0;
    var i = 0.0;
    let n = cartan_vec_len(h);
    while (i < n) {
        let v = cartan_vec_get_f32(h, i);
        let sub_idx = floor(i / 320.0);
        let kw = geom_killing_form_dynkin_weight(sub_idx);
        sum_sq = sum_sq + (v * v) * kw;
        i = i + 1.0;
    }
    return 0.5 * sum_sq;
}

// Anisotropic RMSNorm layer normalization bounding manifold activation energy to 1.0
fn cartan_tensor_rmsnorm(v: ptr, eps: float) {
    if (v == 0.0) { return; }
    let dim = v[0];
    if (dim <= 0.0) { return; }
    var sum_sq = 0.0;
    var i = 0.0;
    while (i < dim) {
        let val = v[2.0 + i];
        let sub_idx = floor(i / 320.0);
        let kw = geom_killing_form_dynkin_weight(sub_idx);
        sum_sq = sum_sq + (val * val) * kw;
        i = i + 1.0;
    }
    let rms = sqrt((sum_sq / dim) + eps);
    if (rms <= 0.000001) { return; }
    let inv_rms = 1.0 / rms;
    i = 0.0;
    while (i < dim) {
        v[2.0 + i] = v[2.0 + i] * inv_rms;
        i = i + 1.0;
    }
}

fn e8_attention_forward_step_with_momentum(hidden_ptr: ptr, mom_ptr: ptr, temp: float) -> ptr {
    if (hidden_ptr == 0.0) { return cartan_vec_create(); }
    let h_len = hidden_ptr[0];
    if (h_len == 0.0) { return cartan_vec_create(); }
    let weights = cartan_sasaki_brainstem_route_vec(hidden_ptr, mom_ptr, temp);
    let h_cur = geomind_streams_manifold_forward_routed(hidden_ptr, weights);
    
    // Normalize manifold activations before and after 16-layer FFN cascade
    cartan_tensor_rmsnorm(h_cur, 0.00001);
    let dim = h_cur[0];
    var l = 0.0;
    while (l < 16.0) {
        let kappa = (l + 1.0) / 16.0;
        var d = 0.0;
        while (d < dim) {
            let z = h_cur[2.0 + d];
            let sub_idx = floor(d / 320.0);
            let kw = geom_killing_form_dynkin_weight(sub_idx);
            let gelu_z = 0.5 * z * (1.0 + tanh(0.79788456 * (z + 0.044715 * z * z * z)));
            let ffn = gelu_z * (1.0 + tanh(kappa * z * kw));
            h_cur[2.0 + d] = z + 0.25 * ffn;
            d = d + 1.0;
        }
        l = l + 1.0;
    }
    cartan_tensor_rmsnorm(h_cur, 0.00001);
    return h_cur;
}

fn e8_attention_forward_step(hidden_ptr: ptr, temp: float) -> ptr {
    return e8_attention_forward_step_with_momentum(hidden_ptr, 0.0, temp);
}


