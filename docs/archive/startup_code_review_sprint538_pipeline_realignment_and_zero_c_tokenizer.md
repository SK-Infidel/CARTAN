# Startup Code Review: Sprint 538 — GeoMind End-to-End Pipeline Realignment, Zero-C Tokenizer Synchronization & Documentation Hardening

## 1. Executive Summary & Problem Formulation
During the Sprint 537 review, Rick inquired about the "C run time parser" in the GeoMind pipeline.
Inspection of [`test/geomind/GEOMIND_PIPELINE.md`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/GEOMIND_PIPELINE.md) revealed significant historical obsolescence:
1. Section 6 ("HuggingFace BPE Tokenizer Decoding & C-Runtime Parser") explicitly cited `src/cartanc/c_runtime.c#L1310-L1380` and claimed token decoding relies on a C-runtime JSON parser (`cartan_hub_decode_json_token`) reading `cache_tokenizer.json`.
2. The entire C runtime was eradicated in Sprints 287/312 (`c_runtime.c.deprecated`) in favor of self-hosting CARTAN.
3. SentencePiece BPE tokenization was ported to 100% pure CARTAN in [`src/std/tokenizer.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/tokenizer.cl), which memory-maps a pre-compiled binary Trie arena (`test/geomind/trainingdata/geomind_vocab_262k.bin`, 3.98 MB, 200,345 nodes, 262k vocabulary) and executes zero-allocation BPE encoding/decoding.
4. Standard library module links throughout `GEOMIND_PIPELINE.md` used outdated `.car` extensions (`src/std/fusion.car`, `distill.car`, `hub.car`, `vision.car`, `tokenizer.car`) instead of production `.cl` files.
5. The pipeline document lacked GeoMind's 8 Lie subgroup streams, WebGPU INT4 double-buffered GDDR6 staging, Sasaki Brainstem MoE routing, Tier 2 NSES cognitive memory, and agentic perception interfaces.

---

## 2. Logical Dependency Tree & Subsystem Architecture

```
                               ┌────────────────────────────────────────────────────────┐
                               │                    cartanc.exe                         │
                               │           (Self-Hosting CARTAN Compiler)               │
                               └──────────────────────────┬─────────────────────────────┘
                                                          │
                               ┌──────────────────────────▼─────────────────────────────┐
                               │                 test/geomind/main.car                  │
                               │                (Production Entry Point)                │
                               └──────┬───────────────────┬──────────────────────┬──────┘
                                      │                   │                      │
           ┌──────────────────────────▼─────┐ ┌───────────▼───────────┐ ┌────────▼─────────────────────────┐
           │     42-Layer Sovereign Core    │ │ Tier 2 Cognitive NSES │ │  Hardware & Perception Layer     │
           ├────────────────────────────────┤ ├───────────────────────┤ ├──────────────────────────────────┤
           │ test/geomind/chat.cl           │ │ src/std/sqlite_vec.cl │ │ src/std/wgpu.cl (WebGPU INT4)    │
           │ test/geomind/streams.cl (8 Lie)│ │ src/std/cargraph.cl   │ │ src/std/transformer.cl (AVX2)   │
           │ test/geomind/moe.cl (Sasaki)   │ │ test/geomind/chat.cl  │ │ tools/read_screen_ocr.cs (WinRT) │
           │ src/std/tokenizer.cl (Trie)    │ │ (10 Cognitive Domains)│ │ UCRT _kbhit() (Async Polling)    │
           └────────────────────────────────┘ └───────────────────────┘ └──────────────────────────────────┘
                                      │                   │                      │
                               ┌──────▼───────────────────▼──────────────────────▼──────┐
                               │                     geomind.exe                        │
                               │             (Zero-C Standalone Binary)                 │
                               └────────────────────────────────────────────────────────┘
```

### Detailed Component Dependencies
1. **SentencePiece BPE Trie Tokenizer Engine (`src/std/tokenizer.cl`)**:
   - Ingests `test/geomind/trainingdata/geomind_vocab_262k.bin` via `cartan_read_file` (12.96 MB, 12,957,193 bytes, 262,144 tokens).
   - Node struct: 16 bytes natural 4-byte alignment: `byte_val: u8` (+3B padding), `token_id: i32`, `child_head: i32`, `next_sibling: i32`.
   - Arena layout: 16-byte header + 600,386 nodes ($600,386 \times 16 = 9,606,176$ bytes) + offset table ($262,144 \times 4 = 1,048,576$ bytes) + null-terminated UTF-8 string pool (2,302,425 bytes).
   - `bpe_encode`: greedy longest-match prefix traversal across Trie branches.
   - `bpe_decode_token`: $\mathcal{O}(1)$ direct array index dereferencing to memory-resident string pool.
   - **Zero C Runtime Dependency**: Pure CARTAN standard library function calls only.
2. **Weight Fusion & Geodesic Interpolation (`src/std/fusion.cl`, `test/geomind/merge_model_weights.cl`)**:
   - Spherical linear interpolation between distinct checkpoint manifolds: $\text{SLERP}(W_1, W_2, t)$.
3. **Distillation Engine (`src/std/distill.cl`, `test/geomind/cloze_engine.cl`, `test/geomind/train.cl`)**:
   - Computes teacher-student KL divergence over Softmax temperature distributions and masked cloze token completions.
4. **Multimodal Perception (`src/std/vision.cl`, `tools/read_screen_ocr.cs`)**:
   - Ingests raw images into bilinear resized RGB tensors; drives Win32 GDI and WinRT OCR for live desktop perception.

---

## 3. Discovered Technical Debt & Issues
- **`[ISSUE-396]`**: `test/geomind/GEOMIND_PIPELINE.md` contains obsolete references to deleted `src/cartanc/c_runtime.c`, broken line links, outdated `.car` standard library extensions, and lacks modern 42-layer manifold, Lie streams, and NSES pipeline phases.
- **`test/geomind/docs/research/BIOLOGICAL_ARCHITECTURE_AND_INFERENCE_LEARNING.md`**: Contains a historical audit table mentioning `src/cartanc/c_runtime.c#L4217-L4239`, which should be updated to clarify that Sasaki router gating was ported to pure CARTAN in `test/geomind/moe.cl`.

---

## 4. Proposed Solution
1. Completely rewrite `test/geomind/GEOMIND_PIPELINE.md` into an 8-phase exhaustive, authoritative, pure-CARTAN pipeline specification.
2. Document the zero-C binary Trie tokenizer engine in Section 6 with exact binary layout and encoding/decoding mechanics.
3. Update standard library references to `.cl`.
4. Update `BIOLOGICAL_ARCHITECTURE_AND_INFERENCE_LEARNING.md` table to reference `test/geomind/moe.cl`.
5. Run compiler regression test suite (`tools/run_affected_tests.ps1`).
