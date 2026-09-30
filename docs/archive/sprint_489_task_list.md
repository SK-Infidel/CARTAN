# Sprint 489 Task List: Standard Library Hub Rigor & Legacy Training Manifold Alignment

## Gate 1: Authentic HuggingFace Hub & Safetensors Introspection ([`[ISSUE-311]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md))
- [x] Implement authentic JSON key extraction in `hub_load_safetensors` to populate tensor registry from safetensors header.
- [x] Upgrade `hub_automodel_from_pretrained` to parse real architectural parameters from `config.json`.
- [x] Upgrade `hub_autotokenizer_from_pretrained` to load vocabulary metadata from `tokenizer.json` / `tokenizer_config.json`.
- [x] Upgrade `hub_load_dataset` to parse real line-delimited records into dataset structures.

## Gate 2: Refactor Compiler Suite Target 33 (`test_hf_hub.car`)
- [x] Remove circular assertions against hardcoded constants (`vocab_size == 32000.0`, `num_layers == 32.0`, `num_samples == 1000.0`).
- [x] Assert authentic safetensors header parsing, real tensor discovery, and valid configuration loading.

## Gate 3: Eradicate Synthetic Trigonometry in Cortical Streams ([`[ISSUE-312]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md))
- [x] Replace handcrafted `sin`/`cos` formulas in `test/geomind/streams.cl` with authentic Cartan Killing-form metric contractions and continuous manifold projections.
- [x] Update WGSL shader `webgpu_get_lie_streams_shader()` in `test/geomind/train.cl` with authentic metric tensor contractions.
- [x] Update OpenCL kernel `geomind_streams_backward` in `test/geomind/train.cl` to evaluate authentic Riemannian gradients.

## Gate 4: Refactor Compiler Suite Target 46 (`test_lie_streams.car`)
- [x] Update assertions in Target 46 to verify authentic metric contraction and boundary operator properties.
- [x] Confirm clean compilation and execution of Target 46.

## Gate 5: 3-Stage Bootstrap Fixpoint Rebuild & Full Regression Clearance
- [x] Compile `cartanc_stage1.exe` with current compiler.
- [x] Compile `cartanc_fresh.exe` with `cartanc_stage1.exe`.
- [x] Compile `cartanc_stage3.exe` with `cartanc_fresh.exe`.
- [x] Prove bitwise fixpoint parity: `SHA256(bin/cartanc_fresh.ll) == SHA256(bin/cartanc_stage3.ll)`.
- [x] Promote Stage 2 compiler to root `cartanc.exe`.
- [x] Verify full regression test suite (`tools/run_affected_tests.ps1 -All`).
- [x] Verify unprimed chat generation on `build/geomind.exe`.
- [x] Update `CHANGELOG.md` to `[8.447.0]`, mark issues as FIXED, and archive walkthrough.
