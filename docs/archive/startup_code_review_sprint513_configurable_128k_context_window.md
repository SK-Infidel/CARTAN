# Sprint 513 Startup Code Review: Configurable 128k Context Window Architecture

**Date**: 2026-10-02  
**Author**: Antigravity  
**Sprint**: 513  
**Focus**: Configurable Context Window scaling up to 128k tokens (131,072 tokens) for GeoMind (`[ISSUE-367]`).

---

## 1. Executive Summary & Codebase Audit Findings

Currently, the causal transformer neural manifold is hardcoded to a 2,048-token context horizon across multiple subsystems:
1. **KV Cache Arena Hardcoding ([`src/std/transformer.cl:50-80`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/transformer.cl#L50-L80))**:
   - `total_floats = 88080384.0; // 42 layers * 2048 positions * 1024 floats`
   - Fixed layer stride: `layer_idx * 2097152.0` ($2048 \times 1024$).
   - Fixed bounds checks: `pos < 2048.0` and `(start_pos + p) < 2048.0`.
2. **CRITICAL DEFECT DISCOVERED: Attention Scores Buffer Overflow (`g_trans_scores`)**:
   - In [`src/std/transformer.cl:2205`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/transformer.cl#L2205), `g_trans_scores = malloc(4096.0 * 4.0);`.
   - In both native decode (`line 2586`) and batch prefill (`line 3104`), attention dot products are written up to `max_seq`:
     `cartan_set_f32(g_trans_scores, t, dot);`
   - If sequence length exceeds 4,096 tokens, `g_trans_scores` **overflows heap memory**, causing memory corruption and crash.
   - **Resolution**: Dynamically size `g_trans_scores` to `g_kv_cache_max_seq * 4.0` bytes.
3. **KV Cache Layer Sharing Optimization**:
   - In [`src/std/transformer.cl:2482`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/transformer.cl#L2482) and [`line 2964`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/transformer.cl#L2964):
     `let is_kv_shared = (layer_idx >= 24.0);`
   - Layers 24..41 share KV projections from layers 22 and 23. They never write to KV cache, and only read from `kv_source_layer <= 23.0`.
   - By sizing the KV cache arena for the 24 active KV layers ($0..23$) instead of all 42 layers, 128k context (131,072 tokens) requires only **12.88 GB** per cache ($25.76 \text{ GB}$ total for K + V). This comfortably fits in the host system's 44.1 GB of free RAM.
4. **RoPE Frequency Scaling for Extended Horizons**:
   - Base `rope_theta = 10000.0`. At 131,072 tokens, high positions experience rotational wrapping unless theta is scaled.
   - Scaling $\text{rope\_theta} = 10000.0 \times (\text{max\_seq} / 2048.0)$ yields $640,000.0$ for 128k, aligning with modern long-context LLMs (LLaMA 3 / DeepSeek: 500,000.0).
5. **Session Horizon & CLI Control**:
   - [`test/geomind/chat.cl:2492`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl#L2492) hardcodes cycling at 2,000 tokens: `g_chat_session_pos + 128.0 >= 2000.0`.
   - [`test/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car) hardcodes `-tokens` default to 2048.0 without a `-context` flag.

---

## 2. Logical Dependency Tree

```
test/geomind/main.car (CLI -context flag & REPL /context command)
 └── test/geomind/chat.cl (Dynamic session horizon & limit setter)
      └── src/std/transformer.cl (Configurable KV cache capacity & RoPE scaling)
           ├── cartan_kv_cache_set_capacity(max_seq) -> float
           ├── cartan_kv_cache_get_capacity() -> float
           ├── cartan_kv_cache_init() [Dynamic 24-layer arena allocation]
           ├── g_trans_scores [Resized to max_seq * 4 bytes to prevent heap overflow]
           ├── cartan_manifold_layer_forward_native [Bounds checked against max_seq]
           └── cartan_manifold_layer_forward_batch [Bounds checked against max_seq]
```

---

## 3. Technical Solution Design

1. **Configurable Capacity API in `src/std/transformer.cl`**:
   - `var g_kv_cache_max_seq: float = 131072.0;` (128k default).
   - `cartan_kv_cache_set_capacity(max_seq: float) -> float`: Reallocates `g_k_cache_arena` and `g_v_cache_arena` if capacity changes.
   - Dynamic stride: `layer_idx * (g_kv_cache_max_seq * 1024.0)`.
2. **Buffer Safety**:
   - Sizing `g_trans_scores = malloc(g_kv_cache_max_seq * 4.0)` ensures safety for attention dot products up to 131,072 tokens.
3. **Adaptive RoPE Frequency**:
   - Scale `rope_theta` when `g_kv_cache_max_seq > 2048.0`:
     `let scaled_theta = rope_theta * (g_kv_cache_max_seq / 2048.0);`
4. **CLI & REPL Integration**:
   - Support `-context <N>` and `--context <N>` in CLI.
   - Default to `131072.0` (128k) or user-specified value.
   - Add `/context [N]` to REPL for telemetry and runtime resizing.
   - Update FIFO context guard to `g_chat_session_pos + 512.0 >= g_chat_context_limit`.
