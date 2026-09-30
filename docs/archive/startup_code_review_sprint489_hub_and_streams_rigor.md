# Startup Code Review: Sprint 489 — Standard Library Hub Rigor & Legacy Training Manifold Alignment

**Date:** 2026-09-30  
**Author:** Antigravity (Pair Programming with Rick)  
**Sprint Focus:** Phase 5 Integrity — Resolving [ISSUE-311] (Hollow Pretrained Model & Tokenizer Stubs in `src/std/hub.cl`) and [ISSUE-312] (Synthetic Trigonometric Stream Processors in `test/geomind/streams.cl` and `test/geomind/train.cl`).

---

## 1. Executive Summary & Code Review Findings

During the startup code review of the remaining issues in [`ISSUES.md`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md), two major integrity gaps were examined:

### A. Hollow Stubs in `src/std/hub.cl` ([ISSUE-311](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md))
1. **Hollow `AutoModel` Construction (`hub_automodel_from_pretrained`)**:
   - `src/std/hub.cl:444-454` returns a struct with hardcoded `num_layers = 32.0`, `hidden_dim = 4096.0`, and an empty weights tree `cartan_tree_create()`. It performs zero inspection of `config.json` or model weight checkpoints.
2. **Hollow `AutoTokenizer` Construction (`hub_autotokenizer_from_pretrained`)**:
   - `src/std/hub.cl:429-442` returns `AutoTokenizer { tokenizer_type: "BPE", vocab_size: 32000.0, ... }` checking only if the string contains `"gemma"` to override `vocab_size = 262144.0`. It does not parse or load `tokenizer.json` or `tokenizer_config.json`.
3. **Mock Safetensors Header Listing (`hub_load_safetensors`)**:
   - `src/std/hub.cl:402-421` checks if the raw header contains `"model."` and manually pushes `"model.embed_tokens.weight"` and `"model.layers.0.weight"`. It does not parse the JSON keys of the safetensors header to enumerate the authentic tensor inventory.
4. **Mock Dataset Ingestion (`hub_load_dataset`)**:
   - `src/std/hub.cl:498-512` returns `num_samples: 1000.0` with an empty `records` tree without parsing any rows from the dataset files.
5. **Circular Test Assertion in Compiler Suite (`test/compiler_suite/test_hf_hub.car`)**:
   - Target 33 asserts against the exact hardcoded mock values (`tok.vocab_size == 32000.0`, `model.num_layers == 32.0`, `ds.num_samples == 1000.0`).

### B. Synthetic Trigonometric Activations in `streams.cl` & `train.cl` ([ISSUE-312](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md))
1. **Ad-Hoc Handcrafted Formulas**:
   - `test/geomind/streams.cl` lines 18, 34, 53, 96-97, 155 implement cortical stream operators with trigonometric formulas:
     - Stream 0 (SO(16)): `cos(i * 0.05 * kw) * 0.25 + 0.75`
     - Stream 1 (E7 x SU(2)): `sin(i * 0.0314 * kw) * 0.20 + 0.80`
     - Stream 2 (E6 x SU(3)): `sin((i + 1.0) * 0.1 * kw) * 0.7071`
     - Stream 4 (F4 x G2): `val * val * val * 0.02 * kw + sin(val * 2.0) * 0.1`
     - Stream 7 (SU(3)^3): `(t1 + t2 + t3) * (0.75 + 0.05 * cos(i * 1.047))`
2. **Hardcoded Compute Shaders in Training Pipeline**:
   - `test/geomind/train.cl:184-210` (`webgpu_get_lie_streams_shader()`) and line 528 (`geomind_streams_backward`) hardcode identical sine/cosine polynomial formulas into WGSL and OpenCL compute kernels.
3. **Architectural Disconnect**:
   - GeoMind's active production inference engine (`test/geomind/chat.cl`) runs 100% pure causal Gemma transformer layers with Hopfield continuous attractor basins and NSES logic, whereas `streams.cl` retains toy trigonometric transformations from the pre-transformer prototype era.
   - The 8 Lie subgroups must either be realized as genuine learned linear projection matrices ($W_k \in \mathbb{R}^{d_k \times d}$) or the legacy training path must be unified with the authentic transformer execution architecture.

---

## 2. Logical Dependency Tree

```
                       ┌─────────────────────────┐
                       │ src/cartanc/core_runtime│
                       └────────────┬────────────┘
                                    │
          ┌─────────────────────────┼─────────────────────────┐
          │                         │                         │
          ▼                         ▼                         ▼
┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
│ src/std/fs.cl    │      │ src/std/tensor.cl│      │ src/std/geom.cl  │
└─────────┬────────┘      └─────────┬────────┘      └─────────┬────────┘
          │                         │                         │
          ├─────────────────────────┤                         │
          │                         │                         │
          ▼                         ▼                         ▼
┌──────────────────┐      ┌──────────────────┐      ┌──────────────────────┐
│src/std/ingest.cl │      │src/std/tokenizer │      │test/geomind/geometry │
└─────────┬────────┘      └─────────┬────────┘      └─────────┬────────────┘
          │                         │                         │
          └────────────┬────────────┘                         │
                       │                                      │
                       ▼                                      ▼
             ┌──────────────────┐                   ┌──────────────────────┐
             │  src/std/hub.cl  │                   │test/geomind/streams  │
             └─────────┬────────┘                   └─────────┬────────────┘
                       │                                      │
          ┌────────────┴────────────┐            ┌────────────┴────────────┐
          ▼                         ▼            ▼                         ▼
┌──────────────────┐      ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│test_hf_hub.car   │      │test/geomind/chat │ │test_lie_streams  │ │test/geomind/train│
│   (Target 33)    │      │    (Inference)   │ │   (Target 46)    │ │   (Training)     │
└──────────────────┘      └──────────────────┘ └──────────────────┘ └──────────────────┘
```

---

## 3. Detailed Technical Defect Catalog

| ID | Location | Defect Description | Impact |
|---|---|---|---|
| **DEF-489-1** | `src/std/hub.cl:444` | `hub_automodel_from_pretrained` returns static 32-layer/4096-dim struct | Zero-mock violation; cannot load real configs |
| **DEF-489-2** | `src/std/hub.cl:429` | `hub_autotokenizer_from_pretrained` does not parse tokenizer files | Zero-mock violation; dummy vocab sizes |
| **DEF-489-3** | `src/std/hub.cl:402` | `hub_load_safetensors` pushes hardcoded strings instead of parsing JSON | Broken tensor introspection |
| **DEF-489-4** | `src/std/hub.cl:498` | `hub_load_dataset` returns mock sample count 1000 and empty tree | Mock data returned to caller |
| **DEF-489-5** | `test/compiler_suite/test_hf_hub.car` | Target 33 asserts against hardcoded mock values | Circular verification failure |
| **DEF-489-6** | `test/geomind/streams.cl:18-160` | Cortical streams compute handcrafted `cos`/`sin` formulas | Toy math violation; fake cortical processing |
| **DEF-489-7** | `test/geomind/train.cl:184-210` | WGSL shader embeds hardcoded trigonometric formulas | Fake GPU training execution |
| **DEF-489-8** | `test/compiler_suite/test_lie_streams.car` | Target 46 asserts positive range of trigonometric formulas | Circular verification of toy math |

---

## 4. Remediation & Strategic Direction

1. **Gate 1 (`std::hub` Safetensors & Model Config Rigor)**:
   - Implement authentic JSON key extraction in `cartan_safetensors_read_header` to discover and return real tensor names into the AST tree.
   - Upgrade `hub_automodel_from_pretrained` to load genuine architectural parameters from `config.json` (or return clear error/empty state if missing).
   - Upgrade `hub_autotokenizer_from_pretrained` to read real vocabulary specifications or delegate to authentic SentencePiece/BPE trie loader.
   - Upgrade `hub_load_dataset` to parse real CSV/JSON line records.
2. **Gate 2 (`test_hf_hub.car` Refactoring)**:
   - Rewrite Target 33 to test authentic safetensors header parsing, real tensor discovery from existing test weights, and valid configuration loading without mock assertions.
3. **Gate 3 (Cortical Streams & Lie Subgroup Manifold Projection)**:
   - Replace handcrafted trigonometric modulation with authentic continuous Riemannian metric contractions and Cartan Killing-Dynkin projection operators.
   - Eliminate synthetic formulas from `webgpu_get_lie_streams_shader` and `streams_bwd_src`.
4. **Gate 4 (`test_lie_streams.car` Refactoring)**:
   - Rewrite Target 46 to verify genuine metric contractions, energy conservation, and manifold partition invariants.
5. **Gate 5 (Bootstrap Fixpoint & Full Regression)**:
   - Execute 3-stage bootstrap compilation.
   - Confirm bitwise SHA256 parity.
   - Pass all 88 regression targets with zero regressions.
