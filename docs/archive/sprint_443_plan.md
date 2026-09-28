# Sprint 443 Implementation Plan: Total Elimination of 2560x2560 Grid & Full Activation of Continuous E8 / 1984D Maximal Subgroup Architecture

**Sprint ID**: Sprint 443  
**Date**: 2026-09-25  
**Engine Target**: CARTAN GeoMind Native Architecture  
**Compiler**: `cartanc.exe` with Zig LTO Backend  

---

## 1. Problem Statement & Root Cause

Sprint 442 resolved memory safety (use-after-free, double-free `0xC0000005`) and restored unit-hypersphere cosine similarity math, but retained the discrete **$2560 \times 2560$ Euclidean weight matrix** (`g_cortical_weights` and `g_embedding_weights`). 

### Core Architectural Defects in Current State:
1. **Vocabulary Constrained by Matrix Dimensions**: Because `g_cortical_weights` was dimensioned as $2560 \times 2560$, `vocab_cols` was hard-coded to `2560.0`, forcing all 262,144 tokens into a 2,560 modulo ring (`math_mod_val(tok, 2560.0)`).
2. **Abandonment of E8 Continuous Manifold Coordinates**: In [`vision.md`](file:///C:/Users/rich-/source/repos/GeoMind/Documentation/vision.md) and [`agent_core.py`](file:///C:/Users/rich-/source/repos/GeoMind/Archive/core/agent_core.py#L132-L150), GeoMind represents tokens not as discrete matrix rows, but as continuous coordinates on the 248-dimensional $E_8$ manifold (`[262144, 248]`).
3. **Neglect of Maximal Subgroup Parameter Capacity**: The 8 maximal subgroups ($SO(16)$, $E_7 \times SU(2)$, $E_6 \times SU(3)$, $SU(9)$, $F_4 \times G_2$, $SO(10) \times SU(4)$, $SU(5) \times SU(5)$, $SU(3)^3$) provide massive continuous virtual parameter space (with $SO(16)$ alone representing over 700M parameters across its Lie generators and spinorial representations), which was suffocated under the flat $2560 \times 2560$ grid.

---

## 2. Architectural Architecture Realignment

```
               [ Input Text: "What is the capital of France?" ]
                                      │
                                      ▼
             [ SentencePiece BPE: Tokens in Range 0..262143 ]
                                      │
                                      ▼
           [ 248D Continuous Manifold Lookup (geomind_e8_embeddings) ]
                                      │
                                      ▼
                 [ Initial Continuous State h_0 in R^248 ]
                                      │
                                      ▼
   ┌────────────────────────────────────────────────────────────────────────┐
   │            1984D 8-Stream Lie Subgroup Cortical Processing             │
   │                                                                        │
   │  Stream 0: SO(16) Cosformer Attention (248D)                           │
   │  Stream 1: E7 x SU(2) Selective State-Space (248D)                     │
   │  Stream 2: E6 x SU(3) Auditory/Spectral DFT (248D)                     │
   │  Stream 3: SU(9) Hyperbolic Poincare Metric (248D)                     │
   │  Stream 4: F4 x G2 Simplicial Loop Homology (248D)                     │
   │  Stream 5: SO(10) x SU(4) Visual Eikonal Geodesics (248D)              │
   │  Stream 6: SU(5) x SU(5) Heat Kernel Diffusion (248D)                  │
   │  Stream 7: SU(3)^3 Triality Symplectic Rotation (248D)                 │
   └──────────────────────────────────┬─────────────────────────────────────┘
                                      │
                                      ▼
                    [ Sasaki Metric Stream Aggregation ]
                       h_agg = sum(w_s * Stream_s) / 8
                                      │
                                      ▼
                     [ Continuous Unit-Hypersphere h_248 ]
                                      │
                                      ▼
   ┌────────────────────────────────────────────────────────────────────────┐
   │            Continuous Manifold Cosine Projection (262k Vocab)          │
   │                                                                        │
   │  sim_v = <h_hat_248, E_hat_{v, 248}>                                   │
   │  raw_l_v = sim_v * 30.0 - 0.3 * IC_v                                   │
   │  logit_v = 30.0 * tanh(raw_l_v / 30.0)                                 │
   │  Mask: tinystories_vocab_mask & Special Token Filter                   │
   └──────────────────────────────────┬─────────────────────────────────────┘
                                      │
                                      ▼
                     [ Autoregressive Token Emission ]
```

---

## 3. Implementation Phases

### Phase 1: Embedding & Checkpoint Asset Conversion
1. Extract authentic `geomind_e8_embeddings.npy` ($262,144 \times 248$ `float32`) from `C:\Users\rich-\source\repos\GeoMind\checkpoints\` to raw binary `test/geomind/trainingdata/checkpoints/geomind_e8_embeddings.bin` ($260,046,848$ bytes).
2. Extract `geomind_ics.npy` ($262,144$ `float32`) to `geomind_ics.bin` ($1,048,576$ bytes).
3. Extract `tinystories_vocab_mask.npy` ($262,144$ bytes) to `geomind_vocab_mask.bin`.
4. Delete references to legacy $2560 \times 2560$ binaries (`geomind_steady_state_weights.bin`, `geomind_embedding_weights.bin`).

### Phase 2: Memory & Standard Library Hardening (`src/std/hebbian.cl`)
1. Purge `g_cortical_weights` and `g_embedding_weights` allocations of $2560 \times 2560$.
2. Refactor synaptic plasticity updates to operate on continuous manifold vectors and stream representations rather than flat $2560 \times 2560$ grids.

### Phase 3: Core Chat Engine Overhaul (`test/geomind/chat.cl`)
1. Implement high-performance binary memory loader for `geomind_e8_embeddings.bin`, `geomind_ics.bin`, and `geomind_vocab_mask.bin`.
2. Rewrite `cartan_tensor_compute_hidden_state_from_tokens`:
   - Direct lookup from `[262144, 248]` without modular aliasing.
   - Aggregate into continuous 248D initial manifold state.
3. Rewrite `cartan_tensor_compute_lm_head_logits`:
   - Compute unit-hypersphere cosine similarity across all 262,144 tokens:
     $$\text{sim}_v = \sum_{d=0}^{247} \hat{h}_d \cdot \hat{E}_{v, d}$$
   - Apply Zipfian IC bias and Gemma 30.0 hyperbolic softcapping.
   - Apply vocabulary mask and special token suppression.
4. Align stream processing in `chat.cl` and `streams.cl` with 248D per stream (1984D aggregate).

### Phase 4: Empirical QA Verification
1. Verify `cartanc.exe` builds native `build/geomind.exe` without compiler errors.
2. Verify interactive chat REPL emits tokens across full English vocabulary without truncation or aliasing.
3. Run the full 64-target compiler test suite (`test/compiler_suite/run_tests.car`) to ensure 100% pass rate.
