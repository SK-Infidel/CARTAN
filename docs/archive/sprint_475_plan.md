# Sprint 475 Plan: Forensic Purge of Deceptive Clamps & Architectural Generalization

**Date**: September 28, 2026  
**Sprint Lead**: Antigravity (Supervising Compiler & Mind Architect)  
**Stakeholder**: Rick (Rich / Daddy Rick)  

---

## 1. Sprint Goal
Forensically purge every legacy clamp, token mask, modulo aliasing, and fake loss threshold across `src/std/gpu.cl`, `test/geomind/train.cl`, `src/std/hebbian.cl`, `src/std/geom.cl`, `src/std/fusion.cl`, and `test/geomind/chat.cl`. Establish a clean, generalized `ModelConfig` abstraction decoupling vocabulary size ($V$), hidden representation dimension ($D$), and attention topology. Verify with Target 85 and ensure all 85 test targets compile and pass with 0 regressions.

---

## 2. User Stories
- **US-475.1 (Language Scaling & Dimension Decoupling)**: As a model architect, I want CARTAN's standard library and training engines to dynamically adapt to any hidden dimension ($D \in \{64, 248, 2560, 4096, 8192\}$) and vocabulary size ($V \in \{1000, 32000, 128256, 262144\}$) without arbitrary hardcoded clamps or modulo wraps.
- **US-475.2 (Zero-Mock Gradient & Loss Integrity)**: As a researcher, I want backpropagation in `train.cl` and `gpu.cl` to propagate genuine gradients across all 262,144 tokens without `< 2560` skips, `& 63` masks, or fake `0.01` loss floors.
- **US-475.3 (Continuous Manifold Sector Alignment)**: As a geometric deep learning specialist, I want the 8 Lie submanifolds to partition dynamically with stride $S = D / 8.0$ across all dimensions.

---

## 3. Sprint Backlog & Deliverables
1. **`ISSUES.md`**: File `[ISSUE-268]`, `[ISSUE-269]`, `[ISSUE-270]`, `[ISSUE-271]`.
2. **`src/std/hub.cl`**: Implement `ModelConfig` struct and dimension factory helpers.
3. **`src/std/gpu.cl`**: Purge `& 63` mask and `t_loss < 0.01f` fake floor; make OpenCL kernels dynamic.
4. **`test/geomind/train.cl`**:
   - Purge `webgpu_get_causal_loss_shader` 64-token mask and fake 0.01 floor.
   - Purge `vocab_cols = 2560.0` and `math_mod_val(target_idx, vocab_cols)` modulo aliasing.
   - Remove `< 2560.0` gradient skips on lines 1121 and 1154.
   - Parameterize GPU GEMV, SGD, and loss delta arguments and thread grid launches.
5. **`src/std/hebbian.cl`**: Parameterize cortical weight allocation and eliminate 256-D / 256-token modulo clamps.
6. **`src/std/geom.cl`, `src/std/hybrid_resonator.cl`, `src/std/fusion.cl`, `test/geomind/chat.cl`**: Replace `if (dim >= 2560.0) stride = 320.0` with `floor(dim / 8.0)`.
7. **`test/geomind/chat.cl`**: Correct `vocab size: 256000` to 262144; utilize 2,560-D full embedding table when present.
8. **Target 85 (`test/compiler_suite/test_model_config_decoupling.car`)**: Verify dimension decoupling across multiple model scales.
9. **Regression Execution**: Build `build/run_tests.exe` and verify all 85 targets pass cleanly.
10. **Closeout**: Update `ISSUES.md`, update `CHANGELOG.md`, save `docs/archive/sprint_475_walkthrough.md`.
