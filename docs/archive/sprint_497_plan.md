# Sprint 497 Implementation Plan: Sovereign GeoMind Manifold Architecture & Complete Google/Gemma Purge

**Sprint**: 497  
**Objective**: Purge all third-party "Google" and "Gemma" references across source, banners, functions, tests, and caches. Establish Sovereign GeoMind Manifold naming.  
**Sponsor**: Rick (Big Daddy)  
**Status**: APPROVED & READY FOR PARALLEL EXECUTION  

---

## 1. Scope & Execution Phases

### Phase 1: Standard Libraries Modernization
- **`src/std/transformer.cl`**:
  - Rename `cartan_gemma_layer_*` -> `cartan_manifold_layer_*`.
  - Provide inline backward-compatibility wrappers for `cartan_gemma_layer_*` during migration.
  - Update docstrings to reference the sovereign GeoMind Transformer Manifold.
- **`src/std/hub.cl`**:
  - Add `model_config_manifold_4b()` (keeping `model_config_gemma4_e4b()` as alias).
  - Generalize repo detection in `hub_autotokenizer_from_pretrained` & `hub_automodel_from_pretrained` for `"geomind"` and `"manifold"`.
  - Update default cache file lookups to check `cache_geomind_*` and `cache_manifold_*`.
- **`src/std/tokenizer.cl`**:
  - Prioritize `geomind_vocab_262k.bin` and `geomind_vocab_65k.bin`.

### Phase 2: Filesystem Checkpoints, Data & Cache Synchronization
- Rename 42 layer files: `test/geomind/trainingdata/checkpoints/layers/gemma4_layer_*.bin` -> `manifold_layer_*.bin`.
- Rename/link vocab files: `geomind_vocab_256k.txt`, `geomind_vocab_262k.bin`, `geomind_vocab_65k.bin`.
- Rename/link SFT datasets: `test/geomind/trainingdata/sft/*_manifold.jsonl`.
- Create zero-overhead NTFS hardlinks in repository root:
  - `cache_geomind_model.safetensors` -> `cache_model.safetensors`
  - `cache_geomind_tokenizer.json` -> `cache_google_gemma-4-E4B-it_tokenizer.json`
  - `cache_geomind_config.json` -> `cache_google_gemma_config.json`

### Phase 3: GeoMind Model Engine & REPL Rebranding
- **`test/geomind/chat.cl`**:
  - Rebrand terminal banner to:
    `GEOMIND E8 MULTIMODAL NEURO-SYMBOLIC CHAT ENGINE (chat.car)`
    `Sovereign GeoMind 42-Layer Manifold & SentencePiece BPE Tokenizer`
  - Switch model and tokenizer hubs to `"geomind/manifold-4b"`.
  - Rename internal layer buffers & KV caches: `g_manifold_layer_buffers`, `g_manifold_k_caches`, `g_manifold_v_caches`.
  - Rename execution functions: `geomind_execute_manifold_layers`, `geomind_execute_manifold_sequence_prefill`, `geomind_execute_manifold_decode_step`.
  - Update layer lookup paths to `manifold_layer_<N>.bin`.
- **`test/geomind/main.car`**:
  - Rebrand CLI help text and `--graft` default checkpoint.
  - Distill repo call: `"geomind/manifold-4b"`.
- **`test/geomind/train.cl` & `geomind_app.cl`**:
  - SFT dataset paths to `*_manifold.jsonl`.

### Phase 4: Regression Test Suite Alignment
- Rename test suite targets:
  - `test/compiler_suite/test_gemma4_layer_alignment.car` -> `test_manifold_layer_alignment.car`
  - `test/compiler_suite/test_gemma4_full_model_execution.car` -> `test_manifold_full_model_execution.car`
  - `test/compiler_suite/test_gemma4_layer_streaming_pipeline.car` -> `test_manifold_layer_streaming_pipeline.car`
  - `test/compiler_suite/test_gemma_engine.car` -> `test_manifold_engine.car`
- Update `test/compiler_suite/run_tests.car` and `tools/run_affected_tests.ps1`.
- Update `test_hf_hub.car` and `test_model_config_decoupling.car`.

### Phase 5: Empirical Verification & Sprint Closure
- Recompile `geomind.exe` and deploy across `bin/`, `build/`, and `test/geomind/`.
- Run all 88 test targets via `tools/run_affected_tests.ps1 -All`.
- Verify live execution of bare `geomind.exe` and test prompt generation.
- Confirm zero occurrences of "Google" or "Gemma" in stdout or code.
- Update `ISSUES.md`, `CHANGELOG.md`, and write walkthrough artifact.
