# Sprint 270 Plan: Biological Streaming Training Pipeline

## Objective
Connect all recently restored biological mechanisms (Continuous Hopfield memory attractor resonance, Sasaki router gating, and authentic WordNet Information Content) directly into the streaming GPU training engine (`geomind_train_streaming_steady_state` & `cartan_tensor_train_batch_gpu_direct`), resolve the SFT JSON parser bypass, expand multi-word Halliday cohesive bridges, and link AZR self-play into persistent Hopfield memory.

---

## Tasks

- [ ] **Task 1: Fix JSON Parsing in SFT Streaming Mode**
  - File: [`src/cartanc/c_runtime.c`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/c_runtime.c) (Lines 5059 & 5210).
  - Unify condition to `(stage_mode == STAGE_CLOZE || stage_mode == STAGE_SFT)`.
  - Extract instruction/cloze prompts and target responses so SFT trains on semantic answers instead of raw JSON braces.

- [ ] **Task 2: Continuous Hopfield Resonance in Training Batches**
  - File: [`src/cartanc/c_runtime.c`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/c_runtime.c).
  - Implement fast in-place vector relaxation `cartan_hopfield_relax_raw_float(float* vec, size_t dim, float beta, int steps)`.
  - Call `cartan_hopfield_relax_raw_float` inside OpenMP batch embedding loop (Lines 5119 & 5277) whenever active basins exist (`g_hopfield_basin_count > 0`), anchoring streaming text into previously ingested context.

- [ ] **Task 3: Authentic WordNet Information Content (IC) Loss Weighting**
  - File: [`src/cartanc/c_runtime.c`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/c_runtime.c) (Lines 5094 & 5245).
  - Query `cartan_get_wordnet_ic(tgt_id)` to dynamically weight loss by concept information density, amplifying learning on rare and transitional terms.

- [ ] **Task 4: Multi-Token Halliday Cohesive Bridge Expansion**
  - File: [`src/cartanc/c_runtime.c`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/c_runtime.c) (Lines 5271-5290).
  - For target phrases with multiple tokens, supervise sequential continuation tokens to learn the entire bridge rather than only token 0.

- [ ] **Task 5: Connect AZR Self-Play to Hopfield Memory Basins**
  - File: [`test/geomind/azr_engine.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/azr_engine.cl).
  - Upon achieving $+1.0$ binary reward, encode winning solutions and store as attractor basins via `cartan_hopfield_store_vector`.

- [ ] **Task 6: Build & Validate Native Executables Across Modes**
  - Synchronize `src/cartanc/c_runtime.c` to `C:\Users\rich-\.cartan\c_runtime.c`.
  - Compile with `cartanc_boot.exe build test/geomind/main.car -o bin/geomind_native.exe`.
  - Empirically verify `--train-cloze`, `--train-ce`, `--train-sft`, `--azr-selfplay`, and `--chat`.
