# Sprint 475 Task List: Forensic Purge of Deceptive Clamps & Architectural Generalization

**Sprint**: 475  
**Lead**: Antigravity (Supervising Compiler & Mind Architect)  
**Stakeholder**: Rick (Rich / Daddy Rick)  

---

## Task Breakdown

### Phase 1: Issue Tracking & Formalization
- [x] **Task 475.1**: Append `[ISSUE-268]`, `[ISSUE-269]`, `[ISSUE-270]`, and `[ISSUE-271]` to `ISSUES.md`.

### Phase 2: Core Abstraction & Standard Library Generalization
- [x] **Task 475.2**: Add `struct ModelConfig` and helper constructors (`model_config_create`, `model_config_gemma4_e4b`, `model_config_e8_root`, `model_config_llama_standard`) in `src/std/hub.cl`.
- [x] **Task 475.3**: Purge 64-token mask `& 63` and fake `0.01` floor from `src/std/gpu.cl`.
- [x] **Task 475.4**: Generalize Lie sector stride `stride = floor(dim / 8.0)` in `src/std/geom.cl`, `src/std/hybrid_resonator.cl`, `src/std/fusion.cl`, and `test/geomind/chat.cl`.
- [x] **Task 475.5**: Generalize `src/std/hebbian.cl` to allocate dynamically based on `dim * vocab_size` and eliminate 256-D / 256-token modulo clamps.

### Phase 3: GeoMind Training & Inference Engine Purge
- [x] **Task 475.6**: Purge `webgpu_get_causal_loss_shader` in `test/geomind/train.cl` of 64-token clamp and 0.01 loss floor.
- [x] **Task 475.7**: In `test/geomind/train.cl`, remove modulo-2560 aliasing (`target_idx = math_mod_val(target_idx, vocab_cols)`), parameterize `vocab_cols` from model configuration, and remove `< 2560.0` gradient skips on lines 1121 and 1154.
- [x] **Task 475.8**: In `test/geomind/train.cl`, parameterize WebGPU GEMV / SGD arguments and thread dispatch to match active vocabulary and hidden dimension.
- [x] **Task 475.9**: In `test/geomind/chat.cl`, fix vocab display (`256000` -> `262144`) and wire 2,560-D full embedding projection into `cartan_tensor_compute_lm_head_logits`.

### Phase 4: Verification & Regression Testing
- [x] **Task 475.10**: Author Target 85 (`test/compiler_suite/test_model_config_decoupling.car`) verifying dynamic decoupling across small ($D=64, V=1000$), standard ($D=2560, V=262144$), and large ($D=4096, V=128256$) model configurations without hardcoded clamps.
- [x] **Task 475.11**: Add Target 85 to `test/compiler_suite/run_tests.car` and `.gitignore`.
- [x] **Task 475.12**: Compile and run all 85 test targets via `build/run_tests.exe`. Verify 0 failures.

### Phase 5: Documentation & Closeout
- [x] **Task 475.13**: Update `ISSUES.md` marking `[ISSUE-268]`, `[ISSUE-269]`, `[ISSUE-270]`, and `[ISSUE-271]` as `[FIXED]`.
- [x] **Task 475.14**: Update `CHANGELOG.md` with version `[8.433.0]`.
- [x] **Task 475.15**: Save `docs/archive/sprint_475_walkthrough.md`.
