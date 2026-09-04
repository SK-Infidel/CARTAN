# Sprint 292 Plan: Elimination of Simulated Functionality & Hardware Environment Primitives

## Objective
Eliminate all remaining simulated / placeholder functionality and unimplemented environment externs across CARTAN stdlib and GeoMind (Issues 35, 36, 37, 38, 40) in full compliance with the Strict Zero-Mock Rule.

## Scope & Target Issues
1. **`[ISSUE-035]` Hardware & Backend Environment Primitives (`src/std/env.cl`)**:
   - Implement `cartan_has_arg`, `cartan_get_arg_string`, `cartan_get_arg_float`, `cartan_get_arg_int`, `cartan_detect_hardware`, and `cartan_mount_backend`.
2. **`[ISSUE-036]` Simulated Distillation Student Logit Loop (`test/geomind/main.car`, `test/geomind/geomind_app.cl`)**:
   - Replace artificial constant increment with authentic teacher-student softmax gradient descent updates: $z_s \leftarrow z_s - \eta \cdot \tau \cdot (q - p)$.
3. **`[ISSUE-037]` Simulated Loss Multipliers in SFT & CE Pre-Training (`test/geomind/sft_train.cl`)**:
   - Replace artificial loss multipliers (`0.9968`, `0.9965`) with genuine GPU/CPU streaming training execution via `geomind_train_streaming_steady_state`.
4. **`[ISSUE-038]` Simulated WebGPU Cross-Entropy Loss & Fake Sasaki MoE Telemetry (`test/geomind/webgpu_causal_engine.cl`)**:
   - Implement true multi-class log-sum-exp cross-entropy in WGSL (`causal_loss_fwd`).
   - Replace trigonometric fake telemetry with authentic Sasaki phase-space routing distributions across the 16 Freudenthal experts.
5. **`[ISSUE-040]` Sliding Window Attention Identity Copy Dummy (`test/geomind/e8_attention_engine.cl`)**:
   - Implement authentic causal sliding window multi-head attention with scaled dot-products, numerical softmax normalization, and value accumulation.

## Logical Dependency Tree
```
sys_get_arg / sys_get_arg_count (LLVM Codegen)
  └── src/std/env.cl (Issue 35)

geomind_train_streaming_steady_state (c_runtime / geomind_runtime)
  └── test/geomind/sft_train.cl (Issue 37)

geomind_sasaki_route (test/geomind/moe.cl) + WGSL compute shaders
  └── test/geomind/webgpu_causal_engine.cl (Issue 38)

distill_kl_divergence_loss (src/std/distill.cl) + Analytical Gradients
  └── test/geomind/main.car & test/geomind/geomind_app.cl (Issue 36)

Scaled Dot-Product + Sliding Window Mask + Softmax
  └── test/geomind/e8_attention_engine.cl (Issue 40)
```

## Definition of Done (DoD)
- [ ] All 5 target files modified with zero simulated / placeholder calculations.
- [ ] Static type check and LLVM compilation via `cartanc.exe`.
- [ ] Regression suite passes without error.
- [ ] Target CLI tools execute cleanly with code 0.
- [ ] `ISSUES.md` and `CHANGELOG.md` updated.
- [ ] Retrospective walkthrough archived.
