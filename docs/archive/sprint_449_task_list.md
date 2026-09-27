# Sprint 449 Task List: 100% Compiler Test Suite Regression Clearance & Hardening

- [x] **Task 1: Resolve Target [26/27] `test_framework_layer2.car`**
  - [x] 1.1 In `src/cartanc/parser.car`, update `var_declaration` to only parse tensor shapes if followed by `[` (`154.0`).
  - [x] 1.2 In `src/cartanc/parser.car`, update `primary` to support token 6.0 (`Tensor`) and 7.0 (`Vector`) followed by `::` (`158.0`).
  - [x] 1.3 In `src/std/tensor.cl`, implement missing tensor module aliases (`tensor_alloc_sequence`, `tensor_matmul`, `tensor_relu`, `tensor_gelu`, etc.).
  - [x] 1.4 In `src/framework/*.car`, fix include paths (`.cl`) and module-prefixed function exports (`nn_relu`, `attention_scaled_dot_product_attention`, `vision_patch_embed`).
  - [x] 1.5 Recompile self-hosted `cartanc.exe`.
  - [x] 1.6 Verify `build/test_framework_layer2.exe` builds and passes with Exit Code 0.

- [x] **Task 2: Resolve Target [33/34] `test_hf_hub.car`**
  - [x] 2.1 In `src/std/hub.cl`, implement `fn hub_load_safetensors(filepath: string) -> ptr`.
  - [x] 2.2 Synchronize `cache_model.safetensors` with valid safetensors format.
  - [x] 2.3 Verify `build/test_hf_hub.exe` builds and passes with Exit Code 0.

- [x] **Task 3: Resolve Target [34/35] `test_vision.car`**
  - [x] 3.1 In `src/std/vision.cl`, include `src/std/fs.cl` and remove conflicting extern declarations.
  - [x] 3.2 Verify `build/test_vision.exe` builds and passes with Exit Code 0.

- [x] **Task 4: Resolve Target [40/41] `test_es_opt.car`**
  - [x] 4.1 In `test/compiler_suite/test_es_opt.car`, remove C-style `(float)` and `(int)` casts and format printf with `cartan_float_to_string`.
  - [x] 4.2 In `src/std/es_opt.cl`, store scalar metadata in `cartan_vec` float container.
  - [x] 4.3 Verify `build/test_es_opt.exe` builds and passes with Exit Code 0.

- [x] **Task 5: Resolve Target [49/50] `test_sleep_consolidation.car`**
  - [x] 5.1 In `src/std/resonator.cl`, implement `cartan_hopfield_store_vector_raw` and `cartan_hopfield_store_hidden_raw`.
  - [x] 5.2 In `src/std/resonator.cl`, update `cartan_hopfield_load_basins` to assign `g_hopfield_key_bank` and `g_hopfield_val_bank`.
  - [x] 5.3 In `test/compiler_suite/test_sleep_consolidation.car`, use `cartan_hopfield_store_hidden_raw` to stage the 3 attractors.
  - [x] 5.4 Verify `build/test_sleep_consolidation.exe` builds and passes with Exit Code 0.

- [x] **Task 6: Full Regression Suite Verification & Sprint Closeout**
  - [x] 6.1 Rebuild `build/run_tests.exe`.
  - [x] 6.2 Execute `build/run_tests.exe` and confirm 59/59 targets pass (0 failures).
  - [x] 6.3 Update `ISSUES.md` and `CHANGELOG.md`.
  - [x] 6.4 Write `docs/archive/sprint_449_walkthrough.md`.
