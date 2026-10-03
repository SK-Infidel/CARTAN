# Sprint 497 Task List: Sovereign GeoMind Manifold Architecture & Complete Google/Gemma Purge

- [x] **Gate 1: Standard Library Sovereign Identifiers**
  - [x] Update `src/std/transformer.cl`: Rename `cartan_gemma_layer_*` to `cartan_manifold_layer_*` and purge legacy vendor aliases.
  - [x] Update `src/std/hub.cl`: Add `model_config_manifold_4b()`, update `hub_autotokenizer_from_pretrained` and `hub_automodel_from_pretrained` for `"geomind"` and `"manifold"`, purge third-party cache checks.
  - [x] Update `src/std/tokenizer.cl`: Prioritize `geomind_vocab_262k.bin` and `geomind_vocab_65k.bin` and purge legacy vendor fallbacks.

- [x] **Gate 2: Filesystem Checkpoints, Data & Cache Synchronization**
  - [x] Atomically rename all 42 layer files in `test/geomind/trainingdata/checkpoints/layers/`: `gemma4_layer_<N>.bin` -> `manifold_layer_<N>.bin`.
  - [x] Synchronize vocab files: `geomind_vocab_256k.txt`, `geomind_vocab_262k.bin`, `geomind_vocab_65k.bin`.
  - [x] Atomically rename SFT datasets in `test/geomind/trainingdata/sft/`: `*_gemma.jsonl` -> `*_manifold.jsonl`.
  - [x] Create zero-overhead hardlinks in root: `cache_geomind_model.safetensors`, `cache_geomind_tokenizer.json`, `cache_geomind_config.json`.

- [x] **Gate 3: GeoMind Model Engine & REPL Rebranding**
  - [x] Update `test/geomind/chat.cl`: Rebrand banners, update hub IDs to `"geomind/manifold-4b"`, rename execution functions and buffers to `manifold_*`, update layer lookup paths.
  - [x] Update `test/geomind/main.car`: Rebrand CLI flags, default `--graft` paths, and distill models. Fast `--help` exit.
  - [x] Update `test/geomind/train.cl` & `geomind_app.cl`: Update dataset and distill calls.
  - [x] Recompile `geomind.exe` and deploy to `bin/`, `build/`, `test/geomind/`.

- [x] **Gate 4: Regression Test Suite Alignment**
  - [x] Rename test files: Targets 83, 84, 86, and engine bridge.
  - [x] Update `test/compiler_suite/run_tests.car` and `tools/run_affected_tests.ps1`.
  - [x] Update `test_hf_hub.car`, `test_model_config_decoupling.car`, `test_model_grafting.car`, `test_geometric_and_search_primitives.car`, and `test_xml_ingest_pipeline.car`.
  - [x] Run all 88 test suite targets via `tools/run_affected_tests.ps1 -All` to ensure 100% pass rate (88 Passed, 0 Failed).

- [x] **Gate 5: Empirical Verification & Sprint Closure**
  - [x] Run live `geomind.exe` with prompt generation under default WebGPU mode; verify zero Google/Gemma branding in stdout.
  - [x] Update `ISSUES.md` (`[ISSUE-332] [FIXED]`).
  - [x] Update `CHANGELOG.md` (`[8.455.0]`).
  - [x] Author `docs/archive/sprint_497_walkthrough.md`.
