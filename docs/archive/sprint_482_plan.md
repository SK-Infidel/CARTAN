# Sprint 482 Plan: Genuine 42-Layer Transformer Chat Inference, Memory-Mapped Layers & Stopword Purge

## 1. Context & Motivation
During interactive chat testing (`.\bin\geomind --chat`), two critical anomalies were identified:
1. `bin/geomind.exe` was a 4-day-old binary (Sprint 441, Sep 25) generating Tamil script repetitions (`இ`).
2. Even in the current binary, the 42 Google Gemma Transformer decoder layers were completely bypassed during chat inference. A 5-line linear momentum formula was used instead, causing the model to act as a bag-of-words lookup (generating country names instead of capitals).
3. The WordNet concept extractor matched `"the"` inside `"photosyn-THE-sis"`, polluting reasoning with `"the" -> photosynthesis`.

Sprint 482 eliminates all simulated/placeholder momentum updates, binds the genuine 42-layer Gemma causal transformer pipeline into chat prefill and autoregressive decode via zero-copy memory-mapped layer streaming, fixes concept extraction, and synchronizes all distribution binaries.

---

## 2. Architecture & Design Specifications

### A. Stopword Filtering & Exact Lemma Resolution (`src/std/semantics.cl`)
- Add stopword blacklist in `cartan_taxonomy_extract_primary_concept`:
  `{"the", "what", "is", "of", "a", "an", "in", "to", "and", "for", "are", "as", "by", "with", "at", "from", "it", "on", "this", "that"}`.
- Replace broad substring matching `cartan_string_contains(path, word)` with exact lemma boundary comparisons, eliminating `"the" -> photosynthesis`.

### B. High-Performance Memory-Mapped Layer Streaming (`src/std/cartan_native_io.c`)
- Implement `c_cartan_mmap_layer(double layer_idx, const char* path)`:
  - Cache 42 `HANDLE` and `MapViewOfFile` pointers in static array `g_layer_mmap_ptrs[42]`.
  - Maps 15.6 GB of layer weights in $<10\text{ ms}$ with zero heap allocation and zero disk-read latency.
  - Export `extern fn c_cartan_mmap_layer(layer_idx: float, path: string) -> ptr` to CARTAN runtime.
- Update `geomind_get_layer_buffer` in `test/geomind/chat.cl` to return the memory-mapped layer pointer directly.

### C. Genuine 42-Layer Autoregressive Transformer Generation (`test/geomind/chat.cl`)
- In `geomind_chat_generate_reply_multimodal`:
  - Reset and initialize KV cache arena for the new conversation turn.
  - Ingest prompt tokens through multi-layer causal prefill, populating the 42-layer KV caches.
  - In each autoregressive decode step, call `geomind_execute_gemma_decode_step(sampled_tok, pos)` through all 42 transformer layers with AVX2 SIMD attention, RoPE, and GeGLU MLPs.
  - Completely remove the toy 5-line linear momentum formula.

### D. Empirical Verification & Binary Deployment Synchronization
- Recompile `test/geomind/main.car` with Zig `-O3` LTO.
- Synchronize all 4 binary paths (`build/geomind.exe`, `bin/geomind.exe`, `test/geomind/geomind.exe`, `./geomind.exe`).
- Test `geomind.exe --chat -prompt "What is the capital of Iran"` and verify genuine reasoning.
- Run compiler regression suite verifying 0 regressions.
