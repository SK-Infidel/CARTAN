# Sprint 449 Implementation Plan: 100% Compiler Test Suite Regression Clearance & Hardening
Date: 2026-09-27
Lead Architect: CARTAN Compiler Core & Runtime Working Groups
Author: Antigravity Pair-Programmer for Rick

---

## 1. Objective
Achieve 100% pass (59/59 targets) across the hardened compiler regression test suite (`build/run_tests.exe`) and resolve all outstanding Sprint 449 issues without introducing any regressions or mock code.

---

## 2. Technical Execution Plan

### Stage 1: Fix Target [26/27] `test_framework_layer2.car` (Parser & Framework Layer 2)
1. In `src/cartanc/parser.car`:
   - In `var_declaration`, only enter `tensor_declaration_with_name` if token 6.0 (`Tensor`) or 10.0 (`Parameter`) is followed by `[` (`154.0`). Otherwise, fall through to `expression(self_ptr)`.
   - In `primary(self_ptr)`, allow token 6.0 (`Tensor`) and 7.0 (`Vector`) when followed by `::` (`158.0`), extracting name `"tensor"` or `"vector"` and lowering namespaced call `tensor::<fn>(args)` into `<module>_<fn>(args)`.
2. In `src/std/tensor.cl`:
   - Add aliases/functions for `tensor_alloc_sequence`, `tensor_matmul`, `tensor_relu`, `tensor_gelu`, `tensor_silu`, `tensor_sigmoid`, `tensor_softmax`, `tensor_transpose`, `tensor_div_scalar`, `tensor_mul_scalar`, `tensor_add_scalar`, `tensor_copy`, `tensor_concat`, `tensor_reshape`, `tensor_sqrt`.
3. In `src/framework/nn.car`, `src/framework/attention.car`, `src/framework/vision.car`:
   - Update include paths from `.car` to `.cl`.
   - Expose module-prefixed functions (`nn_relu`, `attention_scaled_dot_product_attention`, `vision_patch_embed`, etc.).
4. Rebuild self-hosted `cartanc.exe`.
5. Compile and run `build/test_framework_layer2.exe`.

### Stage 2: Fix Target [33/34] `test_hf_hub.car` (Safetensors Ingestion)
1. In `src/std/hub.cl`:
   - Implement `fn hub_load_safetensors(filepath: string) -> ptr` returning a tree containing the parsed tensor records.
2. Synchronize `cache_model.safetensors` from `model.safetensors`.
3. Compile and run `build/test_hf_hub.exe`.

### Stage 3: Fix Target [34/35] `test_vision.car` (Native Vision & Binary I/O Linkage)
1. In `src/std/vision.cl`:
   - Include `src/std/fs.cl` and remove conflicting unlinked `extern fn` declarations.
2. Compile and run `build/test_vision.exe`.

### Stage 4: Fix Target [40/41] `test_es_opt.car` (Evolution Strategies Type Syntax)
1. In `test/compiler_suite/test_es_opt.car`:
   - Remove pseudo C-style casts `(float)(...)` and `(int)(...)`, replacing with native CARTAN floating-point expressions (`i * 2.0`, etc.).
2. Compile and run `build/test_es_opt.exe`.

### Stage 5: Fix Target [49/50] `test_sleep_consolidation.car` (Hopfield Attractor Storage & Compaction)
1. In `src/std/resonator.cl`:
   - Implement `cartan_hopfield_store_vector_raw` and `cartan_hopfield_store_hidden_raw` to allow direct un-clamped attractor storage when deliberately testing offline compaction.
   - Fix `cartan_hopfield_load_basins` to assign loaded basins to `g_hopfield_key_bank` and `g_hopfield_val_bank`.
2. In `test/compiler_suite/test_sleep_consolidation.car`:
   - Use `cartan_hopfield_store_hidden_raw` to store the 3 test attractors.
3. Compile and run `build/test_sleep_consolidation.exe`.

### Stage 6: Full Regression Verification & Sprint Closeout
1. Run `build/run_tests.exe` and confirm 59/59 targets pass with Exit Code 0.
2. Update `ISSUES.md` and `CHANGELOG.md`.
3. Create `docs/archive/sprint_449_walkthrough.md`.
