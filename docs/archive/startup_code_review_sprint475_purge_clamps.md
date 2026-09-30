# Startup Code Review: Sprint 475 — Forensic Purge of Deceptive Clamps, Stubs & Modulo Aliasing

**Date**: September 28, 2026  
**Auditor**: Antigravity (Supervising Compiler & Mind Architect)  
**Supervisor / Principal**: Rick (Rich / Daddy Rick)  
**Status**: APPROVED & ACTIVE  

---

## 1. Executive Summary & Forensic Audit Findings

Following Rick's directive to hunt down all deceptive shortcuts, stubs, and remnants left by the previous session, a forensic audit was executed across `src/` and `test/`. The audit uncovered systematic hardcoded clamps, token masks, and modulo aliasing that secretly truncated vocabulary and representation dimensions:

1. **`src/std/gpu.cl` (Lines 182–188) — The 64-Token Bitmask Clamp**:
   - `causal_loss_fwd` fell back to an OpenCL kernel containing:
     ```c
     int base = t_idx * 64;
     int k = ((int)targets[t_idx]) & 63;
     for (int d = 0; d < 64; d++) ...
     if (t_loss < 0.01f) t_loss = 0.01f;
     ```
     Target token IDs were bitmasked with `& 63`, truncating 262k vocabulary to 64 tokens, and enforcing a fake loss floor of `0.01f`.
   - `causal_attn_fwd`: Hardcoded `int D = 2560;` and loop `for (int d = 0; d < 64; d++)`.
   - `lie_streams_fwd`: Hardcoded `base = t_idx * 2560;` with rigid 320-element intervals.

2. **`test/geomind/train.cl` — The Truncated Training Engine**:
   - `webgpu_get_causal_loss_shader` (Lines 233–242): WGSL duplicate of the 64-token mask:
     `var k: u32 = u32(targets[t_idx]) & 63u;` and `if (token_loss < 0.01f) { token_loss = 0.01f; }`.
   - `cartan_tensor_train_step` (Lines 753–761, 845, 1006):
     - `if (dim > 2560.0) { dim = 2560.0; }`
     - `let vocab_cols = 2560.0; if (target_idx >= vocab_cols) { target_idx = math_mod_val(target_idx, vocab_cols); }` — aliasing all 262,144 tokens modulo 2560.
     - Row indexing: `w_row = 2.0 + (r * 2560.0);`
   - Backward Gradient Skips (Lines 1121, 1154):
     - `if (lr > 0.0 && next_tok >= 0.0 && next_tok < 2560.0)` — completely dropping backward propagation for any token $\ge 2560$ (discarding 99.02% of Gemma tokens).
     - `if (prev_tok >= 0.0 && prev_tok < 2560.0)` — skipping Lie stream updates for tokens $\ge 2560$.
   - GPU Launch & Buffer Clamps (Lines 442–468, 559–560, 583–584, 1103):
     - `total_weights = 2560.0 * 2560.0;` (toy square matrix instead of $D \times V$).
     - `g_buf_train_logits = gpu_alloc(2560.0 * 4.0);` (10 KB buffer instead of $262,144 \times 4$ bytes = 1 MB).
     - Launch grids: `cartan_gpu_launch(g_pipe_gemv, 2560.0, 1.0, 1.0);` (only computing logits for the first 2560 tokens).
   - Old Prototype Loop (Lines 1285–1320):
     - `let D = 2560.0;`
     - Periodic 248-D modulo fallback: `row_offset = tok_id * 248.0; sub_d = math_mod_val(d, 248.0);`.

3. **`src/std/hebbian.cl` — Clamped 256-D Plasticity**:
   - Lines 142, 152: `let total = 2560.0 * 2560.0;`
   - Lines 168, 170: `if (pre_len > 256.0) { pre_len = 256.0; } if (post_len > 256.0) { post_len = 256.0; }`
   - Line 204: `if (h_len > 256.0) { h_len = 256.0; }`
   - Line 207: `let target_idx = math_mod_val(tok_id, 256.0);`
   - Plasticity updates were wrapped modulo 256 and clamped to 256 dimensions.

4. **`src/std/geom.cl`, `src/std/hybrid_resonator.cl`, `src/std/fusion.cl` — Broken Manifold Partitioning for $D > 2560$**:
   - `if (dim >= 2560.0) { stride = 320.0; }`
   - If dimension is 4096 (Gemma 27B / Llama 8B) or 8192 (70B), stride should be `dim / 8.0` (512 or 1024), NOT 320!
   - Forcing 320 broke the 8 Lie submanifolds on any architecture larger than 2560.

5. **`test/geomind/chat.cl` — Incomplete LM Head Projection**:
   - Line 595: `vocab size: 256000` (Gemma is 262,144).
   - Lines 282–308: `cartan_tensor_compute_lm_head_logits` projected only 248 dimensions using `g_e8_embeddings`, failing to utilize the 2,560-D full embedding table when present.

---

## 2. Logical Dependency Tree

```
                      [src/std/math.cl]
                             │
                             ▼
                      [src/std/hub.cl]
              (ModelConfig: V, D, D_ffn, heads)
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
[src/std/transformer.cl] [src/std/geom.cl]  [src/std/hebbian.cl]
 (Gemma 4 Decoders)    (stride = D / 8.0)  (D x V Plasticity)
        │                    │                    │
        └────────────────────┼────────────────────┘
                             │
                             ▼
                    [src/std/gpu.cl]
     (Eradicate 64-token mask, compile dynamic WGSL/OpenCL)
                             │
                             ▼
              [test/geomind/train.cl & chat.cl]
     (Unified 3-Tier Execution: Hot VRAM, Host RAM, NSES)
                             │
                             ▼
      [test/compiler_suite/test_model_config_decoupling.car]
                           (Target 85)
                             │
                             ▼
             [test/compiler_suite/run_tests.car]
                   (All 85 Targets PASS)
```

---

## 3. Systematic Eradication Strategy

1. **Formalize `ModelConfig` in `src/std/hub.cl`**:
   - Struct containing `dim`, `vocab_size`, `inter_dim`, `num_heads`, `num_kv_heads`, `head_dim`.
   - Helper functions to initialize configs for Gemma 4 (2560-D, 262k vocab), E8 Roots (248-D, 262k vocab), and Standard LLM (4096-D, 128k vocab).
2. **Purge Clamps in `test/geomind/train.cl`**:
   - Replace fixed `2560.0 * 2560.0` allocations with dynamic `hidden_dim * vocab_size` or tied embedding references.
   - Remove modulo-2560 token aliasing.
   - Remove `< 2560.0` gradient and Lie stream skips.
   - Fix buffer allocations for logits ($V \times 4$ bytes) and deltas ($V \times 4$ bytes).
   - Replace 64-token causal loss shader with authentic cross-entropy over full active vocabulary.
3. **Generalize Lie Sector Partitioning**:
   - In `geom.cl`, `hybrid_resonator.cl`, `fusion.cl`, and `chat.cl`: replace `if (dim >= 2560.0) { stride = 320.0; }` with `var stride = floor(dim / 8.0); if (stride < 1.0) { stride = 1.0; }`.
4. **Generalize `src/std/hebbian.cl`**:
   - Parameterize cortical weights with `dim` and `vocab_dim`.
   - Eliminate `math_mod_val(tok_id, 256.0)` and 256-D clamps.
5. **Purge 64-Token Clamps in `src/std/gpu.cl`**:
   - Eradicate `int k = ((int)targets[t_idx]) & 63;` and `t_loss < 0.01f` shortcuts.
6. **Author Target 85 (`test_model_config_decoupling.car`)**:
   - Empirically verify dimension decoupling across small ($D=64, V=1000$), standard ($D=2560, V=262144$), and large ($D=4096, V=128256$) model configurations without hardcoded clamps.
