# Comprehensive Startup Code Review & Logical Dependency Tree — Sprint 445

## Executive Summary
A comprehensive audit of the CARTAN and GeoMind codebases was performed to locate all vestigial Euclidean artifacts, rigged benchmark hacks, silenced Lie submanifolds, and synthetic sinusoidal phase noise left behind by previous teams.

---

## 1. Logical Dependency Tree

```
Compiler Core (`src/cartanc/`)
  ├── lexer.car ──> parser.car ──> type_checker.car ──> llvm_codegen.car
  └── core_runtime.car (Vectors, Buffers, GPU, Memory)
        │
        ▼
Standard Substrate (`src/std/`)
  ├── math.cl (Scalars, exp, log, sin, cos, tanh, math_abs, math_mod_val)
  ├── collections.cl (Vector, Tree, Map, String primitives)
  ├── tensor.cl (Allocations, contiguous f32 buffers)
  └── geom.cl (Dynkin weights: geom_killing_form_dynkin_weight for 8 Lie subgroups)
        │
        ▼
Neural & Geometry Architecture (`src/std/` & `test/geomind/`)
  ├── transformer.cl (Causal Transformer Decoder: RMSNorm, RoPE, GQA, SwiGLU)
  ├── resonator.cl (Continuous Hopfield Associative Memory)
  ├── hybrid_resonator.cl (Unifies Transformer + Hopfield + Killing-Cartan metric)
  ├── geometry.cl (FRS metric on TM = M x T_x M, 240 Weyl root reflections)
  ├── streams.cl (8 Lie Subgroup streams + E8StreamHerald gauge exchange)
  ├── moe.cl (16 Freudenthal Magic Square experts + Sasaki routing)
  └── e8_attention_engine.cl (Multi-layer E8 Attention + FFN cascade)
        │
        ▼
Cognitive Memory, Tokenization & Multimodal (`src/std/` & `test/geomind/`)
  ├── tokenizer.cl (BPE tokenization)
  ├── vision.cl & audio.cl (Multimodal feature extraction & projection)
  ├── sleep.cl & sleep.car (Delta-CSR NSES consolidation & S^247 void discovery)
  └── hebbian.cl (Three-factor Hebbian plasticity)
        │
        ▼
Execution Interfaces (`test/geomind/`)
  ├── chat.cl (Interactive REPL, S^247 cosine projection over 32k/262k vocab)
  ├── train.cl (OpenCL / WebGPU / CPU training loops)
  └── main.car (CLI orchestrator: --chat, --train, --sleep, --eval-analogy)
```

---

## 2. Key Audit Discoveries & Technical Debt

### [DEFECT-1] Rigged BPE Token Remapping (`src/std/tokenizer.cl`)
- **Location**: `src/std/tokenizer.cl#L154-L175` & `L236`.
- **Finding**: `tokenizer_map_concept_slot` hijacked common semantic tokens ("woman", "king", "queen", "physics", etc.) and remapped them into slots `2500..2518`.
- **Impact**: Poisoned BPE token sequences during encoding to fake analogy benchmark test passes inside the legacy 2560-wide Euclidean grid.

### [DEFECT-2] Flat 2560x2560 Grid, Token Clamping & Sine Noise in Training (`test/geomind/train.cl`)
- **Location**: `test/geomind/train.cl#L438`, `L500`, `L506`, `L741-L742`, `L826`, `L932`, `L950`.
- **Finding**:
  1. `let total_weights = 2560.0 * 2560.0;` — retained discrete Euclidean matrix for training.
  2. `let vocab_cols = 2560.0; if (target_idx < 0.0 || target_idx >= vocab_cols) return 0.0;` — silently dropped training for all real tokens $\ge 2560$.
  3. `int eff_tok = (tok < vocab) ? tok : 3;` in GPU OpenCL kernels clamped out-of-range tokens to token 3 (`<unk>`).
  4. `float phase = (float)tok * 37.0f + (float)i * 13.0f; float base_sig = sin(phase * 0.001f);` injected synthetic sinusoidal phase noise.
  5. WebGPU shaders hardcoded `D = 2560u` and 8 hardcoded 320u loops.

### [DEFECT-3] Silenced Lie Subgroups in FRS Router (`test/geomind/geometry.cl`)
- **Location**: `test/geomind/geometry.cl#L263`, `L323`, `L331`, `L345`.
- **Finding**: `geomind_frs_stream_routing` hardcoded `start_d = s * 320.0` and `while (d < 320.0 && (start_d + d) < plen)`.
- **Impact**: When `plen == 248.0`, `start_d` for streams $1..7 \ge 320 > 248$. The loop never executed for streams 1–7. Stream 0 absorbed 100% of the vector while streams 1–7 had 0.0 energy.

### [DEFECT-4] Toy Sinusoidal State Updates & Multimodal OOB (`test/geomind/chat.cl`)
- **Location**: `test/geomind/chat.cl#L246-L296`, `L298-L320`, `L589`, `L624`.
- **Finding**:
  1. `cartan_tensor_update_autoregressive_state` mutated representations between tokens using arbitrary sine/cosine/cubic noise instead of Riemannian parallel transport on $S^{247}$.
  2. `cartan_multimodal_ground_hidden` wrote to offsets `1600.0 + i` and `640.0 + i` on 248D vectors.
  3. `geomind_chat_process_image_file` and `geomind_chat_process_audio_file` generated fake 16x16 gradient images and 440Hz sine audio when no files were provided.

### [DEFECT-5] Pointer Address Arithmetic in MoE Router (`test/geomind/moe.cl`)
- **Location**: `test/geomind/moe.cl#L48-L55`, `L151-L172`.
- **Finding**: `total_gate` averaged the heap pointer addresses of `g_sasaki_weights` and scaled the output vector by the raw heap address. `geomind_sasaki_route` only inspected 16 dimensions with an arbitrary `0.05 * expert_idx` shift.

### [DEFECT-6] Hardcoded 320 Strides in Standard Libraries
- **Location**: `src/std/hybrid_resonator.cl#L80`, `src/std/sleep.cl#L227`, `src/std/resonator.cl#L541`, `test/geomind/main.car#L464`.
- **Finding**: Hardcoded `r / 320.0` silenced sectors 1–7 for 248D vectors during Killing-Cartan metric pullback. `sleep.cl` and `resonator.cl` hardcoded 2560.0 defaults.

---

## 3. Remediation Roadmap (Sprint 445)
1. **Purge Rigged Tokenizer Remapper**: Remove `tokenizer_map_concept_slot` from `src/std/tokenizer.cl` and emit genuine BPE token IDs.
2. **Restore Manifold Autoregression in Chat**: Replace synthetic trigonometric formulas in `cartan_tensor_update_autoregressive_state` with true Riemannian geodesic / parallel transport projection on $S^{247}$. Fix multimodal stream sector indexing.
3. **Fix Dynamic Strides in FRS Router & Hybrid Resonator**: Replace hardcoded `320.0` strides with dynamic strides (`(r * 8.0) / dim` or `stride = plen >= 2560 ? 320 : (plen >= 1984 ? 248 : 31)`).
4. **Clean MoE Freudenthal Experts**: Eliminate pointer address math in `moe.cl` and compute true 248D Sasaki phase-space routing.
5. **Harmonize Training Engine**: Remove 2560-token drop in `train.cl`, remove synthetic phase noise, and align with continuous $E_8$ manifold geometry.
