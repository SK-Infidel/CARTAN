# Startup Code Review: Sprint 474 - Gemma 4 42-Layer Full Model Ingestion & 3-Tier Execution

## 1. Executive Summary & Context
In Sprint 473, we laid the authentic mathematical foundation:
- Extracted all 262,144 tokens into `geomind_embeddings_full_262k.bin` (2.68 GB), `geomind_ple_embeddings_full_262k.bin` (11.27 GB), and `geomind_final_norm.bin` (10,240 bytes) with zero token truncation and zero synthetic modulation.
- Authored Gemma 4 primitives in `src/std/transformer.cl` (`cartan_rmsnorm_head`, `cartan_geglu_mlp_forward`, `cartan_ple_gate_forward`, `cartan_logit_softcap`, `cartan_gemma_layer_forward`).
- Authored QA Target 83 (`test/compiler_suite/test_gemma4_layer_alignment.car`), mathematically proving all 4 gates pass. All 83 regression targets now pass cleanly (0 failures).

In Sprint 474, we execute the model cloning runtime: wiring the authentic 42-layer decoder pipeline and implementing the 3-Tier memory architecture directed by Rick (Host RAM caching + Hot VRAM compute + Cold Cognitive Warehouse for "tip of the tongue" reflective retrieval).

---

## 2. Logical Dependency Tree
```
[src/std/math.cl]
    ▲
    │
[src/std/tensor.cl]
    ▲
    │
[src/std/transformer.cl] (Gemma 4 Primitives: QK-Norm, GeGLU, PLE, Softcap, Layer Forward)
    ▲
    ├───────────────────────────────────────────────────────┐
    │                                                       │
[src/std/hub.cl]                                  [test/geomind/chat.cl]
 (Safetensors / Bin Streamer & Checkpoint Loader)    (Chat Engine & Token Generation)
    ▲                                                       ▲
    │                                                       │
[test/geomind/trainingdata/checkpoints/]                    │
 (Full 262k Embeddings, PLEs, Final Norm, Schema)          │
    ▲                                                       │
    └───────────────────────────────────────────────────────┘
                                ▲
                                │
    [src/std/sqlite_vec.cl & cargraph.cl / NSES Pipeline]
     (Tier 3 Cognitive Warehouse: "Tip of the Tongue" Reflective Memory)
```

---

## 3. Discovered Technical Debt & Stubbed Features

### A. `[ISSUE-264]` Dummy Checkpoint Writer & Phantom Loader in `src/std/hub.cl`
- `cartan_graft_multimodal_weights` wrote a 12-byte text file containing `"CARTAN_CKPT\n"` and generated synthetic cosine arrays (`0.05 * cos(vi * 0.1)`).
- `cartan_load_signed_checkpoint` only verified file existence and set `g_multimodal_grafted = 1.0` without loading tensor weights.

### B. `[ISSUE-265]` Missing Decoder Forward Pass in `test/geomind/chat.cl`
- `cartan_tensor_compute_hidden_state_from_tokens` executed an exponential moving average over 248-dim vectors instead of 2,560-dim full embedding lookup.
- `e8_attention_forward_step_with_momentum` applied a 16-layer scalar FFN with no learned weights (`z + 0.25 * gelu_z * (1.0 + tanh(kappa * z * kw))`), skipping all 42 transformer layers.
- `cartan_tensor_compute_lm_head_logits` computed cosine similarity against a 248-dim table instead of tied-embedding linear projection with logit soft-capping.

### C. `[ISSUE-268]` Absence of Tier 3 Cognitive Warehouse Query Hook on Reflective Doubt
- When top-1 confidence drops or entropy spikes, the system rewound the context, but did not consult the NSES associative SQLite database (`cognitive_memory.db`) or knowledge graph (`.car_graph`) to resolve the "tip of the tongue" memory deficit before sampling.

---

## 4. Hardware Sizing & 3-Tier Memory Layout
1. **Tier 1: Hot VRAM (Active Compute)**:
   - GPU: NVIDIA RTX 2000 Ada (4.0 GB VRAM).
   - Holds: Active layer weights under evaluation, KV cache buffers, and intermediate activation tensors.
2. **Tier 2: Warm Host RAM (Full Weight Storage)**:
   - Host: 64 GB physical RAM (39.2 GB free).
   - Holds: Full 262,144 token embedding matrix (`geomind_embeddings_full_262k.bin`: 2.68 GB), PLE embeddings, final layernorm, and cached layer parameters.
3. **Tier 3: Cold Cognitive Warehouse (Associative Database)**:
   - Storage: SQLite `cognitive_memory.db` / `test/geomind/trainingdata/nses_knowledge.car_graph`.
   - Access: Triggered dynamically by `cartan_doubt_should_rewind` when top-1 confidence $< 0.05$ or entropy $> 3.5$. Fetches nearest domain attractor vectors to guide generation through difficult concept boundaries.
