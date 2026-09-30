# Sprint 476 Implementation Plan: Authentic 42-Layer Gemma Transformer Streaming & Execution
**Date**: 2026-09-28
**Sprint Goal**: Stream and execute authentic 42 Google Gemma 4-E4B Transformer decoder layers directly into `test/geomind/chat.cl`, calibrate reflective doubt thresholds to prevent premature attractor rewinds, optimize LM head memory access, and empirically verify generation of "mitosis" on "In biology, cells divide through".

---

## 1. Scope & Architecture Alignment

### 1.1 Root Cause & Target Fixes
1. **Root Cause**: `test/geomind/chat.cl` called `e8_attention_forward_step_with_momentum` in `test/geomind/e8_attention_engine.cl`, which implemented a synthetic 16-step scalar polynomial equation (`0.25 * gelu_z * (1.0 + tanh(kappa * z * kw))`) with no learned weights, completely bypassing Gemma's 42 layers.
2. **Architecture**:
   - `tools/clone_gemma_to_cartan.py`: Ingests authentic tensor slices from `cache_google_gemma-4-E4B-it_model.safetensors` (15.99 GB) and serializes each layer's weights into structured sequential binary files `layers/gemma4_layer_{l}.bin`.
   - `src/std/transformer.cl`: Provides validated `cartan_gemma_layer_forward` (RoPE, GQA attention, GeGLU MLP, PLE gating, layer scalars).
   - `test/geomind/chat.cl`: Implements `geomind_execute_gemma_layers(hidden_state, pos, seq_len)`, streaming each layer buffer and executing `cartan_gemma_layer_forward` across layers 0..41.
   - Calibrate reflective doubt thresholds (`conf < 0.01 || ent > 5.50`) to prevent premature rewinding to rule attractor #0 (`"object"`).
   - Author compiler regression Target 86 (`test/compiler_suite/test_gemma4_layer_streaming_pipeline.car`).

---

## 2. Technical Design & Layer Binary Specification

### 2.1 Layer Binary Layout (`layers/gemma4_layer_{l}.bin`)
Each layer contains:
- Header: Magic `0x47454D34` ('GEM4'), `layer_idx` (u32), `head_dim` (u32: 256 or 512), `rope_theta` (f32: 10k or 1M), `layer_scalar` (f32).
- Normalized Weights (Float32 / Float16):
  1. `input_layernorm` [2560]
  2. `q_proj` [2048, 2560]
  3. `k_proj` [512, 2560]
  4. `v_proj` [512, 2560]
  5. `o_proj` [2560, 2048]
  6. `q_norm` [head_dim]
  7. `k_norm` [head_dim]
  8. `post_attention_layernorm` [2560]
  9. `pre_feedforward_layernorm` [2560]
  10. `gate_proj` [10240, 2560]
  11. `up_proj` [10240, 2560]
  12. `down_proj` [2560, 10240]
  13. `post_feedforward_layernorm` [2560]
  14. PLE weights (if present): `ple_gate` [256, 2560], `ple_proj` [2560, 256], `ple_norm` [2560]

---

## 3. Definition of Done (DoD)
- [ ] Layer extraction script `tools/clone_gemma_to_cartan.py` exports authentic layer binary stream.
- [ ] `geomind_execute_gemma_layers` integrated into `test/geomind/chat.cl`.
- [ ] Reflective doubt calibrated to `conf < 0.01 || ent > 5.50`.
- [ ] Target 86 authored and verified via `cartanc.exe`.
- [ ] All compiler regression tests pass with 0 regressions.
- [ ] `geomind.exe --chat` generates authentic contextual output.
- [ ] `ISSUES.md`, `CHANGELOG.md`, and Sprint 476 Walkthrough archived.
