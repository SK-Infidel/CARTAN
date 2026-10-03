# Startup Code Review: Sprint 520
## Thermodynamic Layer Early Exit & Hopfield Speculative Drafting

**Date**: 2026-10-03  
**Reviewer**: Supervisor Agent & Compiler/Runtime Squads  
**Focus**: Latency mitigation for autoregressive token decoding on DDR5 host RAM memory bus

---

### 1. Root Cause Analysis: Rigid Layer Streaming & Unleveraged Basin Memory
- **Memory Bus Bottleneck**: Autoregressive decode streams ~3.95 GB of INT8 weights per token across DDR5 channels (~84 ms/token = ~11.9 tok/s peak theoretical memory limit).
- **Rigid 42-Layer Pipeline**: Every token traverses all 42 layers sequentially, even when latent state representations $\Delta h = \|h_l - h_{l-1}\| / \|h_l\|$ converge to near zero (< 0.05) by layer 24.
- **Architectural KV Asymmetry**: In GeoMind's architecture, layers 0..23 write to the KV cache arena, whereas layers 24..41 share KV caches from layers 22/23 without writing. Therefore, exiting at or after layer 24 leaves the entire KV cache 100% complete and bit-for-bit valid for all future tokens.
- **Speculative Drafting Opportunity**: Modern Continuous Hopfield associative memory (`src/std/resonator.cl`) stores attractor basins and token transitions. When resonance $R > \theta$, Hopfield associative query can draft 3–5 tokens in < 0.1 ms. Batched INT8 kernel (`cartan_manifold_layer_forward_batch_int8`) can verify all drafted tokens in a single 84 ms weight streaming pass, multiplying effective decode throughput by up to 3x–5x.

---

### 2. Logical Dependency Tree
```
src/std/transformer.cl
    ├── cartan_manifold_layer_forward_raw / cartan_manifold_layer_forward_native
    │       └── KV cache arena (g_k_cache_arena, g_v_cache_arena: layers 0..23 write; 24..41 read)
    ├── cartan_manifold_layer_forward_batch_int8 (single-pass verification of K candidate tokens)
    └── cartan_transformer_layer_delta / state entropy metric

src/std/resonator.cl
    ├── cartan_hopfield_query_vec (attractor basin associative recall)
    ├── cartan_hopfield_store_pair_vec (key-value transition storage)
    └── cartan_hopfield_draft_candidates (candidate token sequence generation)

test/geomind/chat.cl
    ├── geomind_execute_manifold_decode_step (thermodynamic early exit loop)
    ├── geomind_chat_generate_reply_multimodal (Hopfield speculative draft & batch verify loop)
    └── telemetry reporting (tokens/sec, early exit rate, speculative acceptance rate)
```

---

### 3. Issues Identified
- **[ISSUE-377]**: Autoregressive Decode DDR5 Memory Bus Bottleneck: Rigid 42-Layer Traversal and Unleveraged Speculative Basin Memory.
