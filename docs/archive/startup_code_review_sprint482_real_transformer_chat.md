# Startup Code Review: Sprint 482 - Native 42-Layer Transformer Chat Inference, Stopword Purge & Binary Sync

## 1. Executive Summary & Root Cause Analysis
Rick tested GeoMind in chat mode (`.\bin\geomind --chat`) with prompt `"What is the capital of Iran"` and observed two catastrophic anomalies:
1. An artificial `<think>` reasoning block declaring `"the" -> photosynthesis`.
2. Repetitive generation of Tamil script characters (`இ இ இ...`) and country names (`Japan iran what`, `Ivan Germany Israel Bulgaria...`) rather than the capital `Tehran`.

Meticulous codebase inspection revealed four underlying root causes:
1. **Ancient Binary in `bin/`**: `bin/geomind.exe` had a timestamp of September 25, 2026 (Sprint 441, 1.58 MB) and had not been synchronized during recent sprints. It lacked the 262k vocabulary table, 42-layer decoder pipeline, AVX2 SIMD attention, and softcap LM head, causing projection collapse.
2. **Transformer Layers Bypassed in Chat Generation**: In `test/geomind/chat.cl`, prompt prefill used only a flat exponential moving average of token embeddings (`cartan_tensor_compute_hidden_state_from_tokens`), and autoregressive decoding used a 5-line toy momentum formula (`new_m = 0.65 * m_v + 0.35 * (t_v - cur_v)`). The 42 Google Gemma Transformer decoder layers (`c_cartan_gemma_layer_forward_fast`) were **never executed**. The model acted as a pure bag-of-words similarity lookup: `" Iran"` dominated the linear embedding sum, whose nearest neighbors in Euclidean embedding space are other countries (`Germany`, `Japan`, `Israel`).
3. **Substring False-Positive in Concept Extraction**: `cartan_taxonomy_resolve_path` used `cartan_string_contains(path, word)`. The stopword `"the"` matched inside `"photosyn-THE-sis"`, extracting `"the" -> photosynthesis` for any prompt containing the article `"the"`, and artificially boosting its logits.
4. **Heap `fread` Layer Stalls**: Layer loading previously used heap allocation and `fread` across 15.6 GB of binary buffers. To achieve genuine 42-layer execution with instant response, layers must be memory-mapped via Windows `MapViewOfFile` (`c_cartan_mmap_layer`), matching the existing PLE memory-map architecture.

---

## 2. Logical Dependency Tree

```
test/geomind/main.car (Interactive REPL & CLI Driver)
 ├── test/geomind/chat.cl (Chat Inference Engine)
 │    ├── [CALLS] geomind_execute_gemma_layers / geomind_execute_gemma_decode_step
 │    │    └── src/std/transformer.cl (cartan_gemma_layer_forward_raw)
 │    │         └── src/std/cartan_native_io.c (c_cartan_gemma_layer_forward_fast)
 │    │              ├── [AVX2 GEMV] Q, K, V, Out Projections
 │    │              ├── [RoPE] Canonical Split-Half Rotation
 │    │              ├── [KV Cache] Pinned Contiguous KV Cache Arena
 │    │              ├── [GQA Attention] AVX2 Causal SIMD
 │    │              ├── [GeGLU MLP] Gate, Up, Down AVX2 FMA
 │    │              └── [PLE] Layer Embedding Gating
 │    ├── [MEMORY MAP] c_cartan_mmap_layer (42x 372MB Layer Files on-demand paging)
 │    ├── [ATTRACTOR] src/std/resonator.cl (Heteroassociative Continuous Hopfield KV)
 │    └── [LM HEAD] src/std/cartan_native_io.c (c_cartan_compute_lm_head_softcap)
 └── src/std/semantics.cl (WordNet & Concept Taxonomy)
      ├── [STOPWORD FILTER] Purges "the", "a", "an", "is", "of", "what"
      └── [EXACT MATCH] Replaces substring search with exact lemma comparison
```

---

## 3. Systematic Findings & Issues Cataloged

### [ISSUE-293] Stale Binary Distribution in `bin/geomind.exe`
- **Severity**: Critical (Deployment & Verification Integrity)
- **Status**: Fixed in Sprint 482. Synchronized `bin/geomind.exe` with `test/geomind/geomind.exe` and `build/geomind.exe` (SHA256 `86F8C25F3B41ACD53140C06F2ABC79079A0066FBBE54F88CBFFCF119FAE66F41`).

### [ISSUE-294] Bypassed 42-Layer Gemma Transformer Forward Pipeline in Chat Inference
- **Severity**: Blocker (Zero-Mock Rule Violation & Semantic Collapse)
- **Status**: Open. Chat inference loop in `test/geomind/chat.cl` must invoke `geomind_execute_gemma_layers` / `c_cartan_gemma_layer_forward_fast` on each autoregressive step rather than the toy linear momentum formula.

### [ISSUE-295] Substring False-Positive in WordNet Concept Extraction ("the" -> photosynthesis)
- **Severity**: High (Semantic Divergence)
- **Status**: Open. Stopwords must be filtered from `cartan_taxonomy_extract_primary_concept`, and `cartan_taxonomy_resolve_path` must require exact word equality.

### [ISSUE-296] High-Performance Zero-Copy Memory Mapping for 42 Gemma Transformer Layer Files
- **Severity**: High (Latency & Memory Efficiency)
- **Status**: Open. Implement `c_cartan_mmap_layer(layer_idx, path)` using `CreateFileMapping` / `MapViewOfFile` to eliminate the 15.6 GB `fread` disk stall.
