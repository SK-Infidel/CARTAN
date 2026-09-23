# Sprint 376 Implementation Plan: 3-Tier Cognitive Hybrid Architecture (Causal MHA + Selective Lie SSM + Continuous Hopfield Memory)

## Executive Summary
In Sprint 376, we eliminate GeoMind's 12-token memory horizon and break through the ~4.26 nats pretraining loss floor by implementing the complete **3-Tier Cognitive Hybrid Architecture**:
1. **Tier 1 (Immediate Working Memory)**: Causal Multi-Head Self-Attention ($T = 256$, $H = 8$, $d_h = 320$) in the GPU OpenCL chunk pipeline and CPU fallback.
2. **Tier 2 (Fluid Narrative Stream)**: Selective Lie-Stream Gating (input-dependent retention $\alpha_t \in [0.40, 0.92]$) with Inter-Chunk Hidden State Persistence across sentence and paragraph boundaries.
3. **Tier 3 (Episodic Consolidation)**: Continuous Hopfield Working-Memory Injection via associative attractor resonance ($h \leftarrow h + \gamma \cdot h_{\text{res}}$).

---

## Technical Architecture & Dependency Tree

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Raw Input Sequence Chunk                        │
│                           Tokens[0 .. T-1]                             │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│               Tier 2: Selective Lie-Stream Gating (SSM)                │
│       v_t = α_t * h_{t-1} + (1 - α_t) * (tok_emb + phase_sig)          │
│          α_t = clamp(0.50 + 0.15 * IC_t, 0.40, 0.92)                   │
│        (Inter-chunk persistence: h_0 seeds from prev chunk end)        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│           Tier 1: Causal Multi-Head Self-Attention (GPU MHA)           │
│           8 Lie Sub-Algebra Heads (H = 8, d_h = 320, D = 2560)         │
│           Attn = softmax( (Q * K^T) / sqrt(320) + M_causal ) * V       │
│           h_t = LayerNorm( v_t + Attn_out_t )                          │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│             Tier 3: Continuous Hopfield Working Memory                 │
│              h_res = HopfieldRelax(h_t, β = 1.5, steps = 2)            │
│                 h_t = h_t + 0.15 * (h_res - h_t)                       │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                 16-Expert Freudenthal FFN Cascade                      │
│                    + Post-RMSNorm Normalization                        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                     Output Projection & LM Head                        │
│           logits = h_t * W  --> Softmax Cross-Entropy Delta            │
│               + Shannon Entropy / Surprise / Certainty                 │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Detailed File Modifications

### 1. `test/geomind/train.cl`
- **Buffer Allocations**:
  - Allocate `g_buf_chunk_seq_h` ($256 \times 2560 \times 4$ bytes = 2.62 MB) to store sequence hidden states for attention.
  - Allocate `g_buf_chunk_attn_out` ($256 \times 2560 \times 4$ bytes = 2.62 MB).
  - Allocate `g_buf_prev_chunk_h` ($2560 \times 4$ bytes = 10 KB) for inter-chunk state persistence.
- **OpenCL Attention Kernel (`geomind_causal_mha_forward`)**:
  - 8 workgroups (one per Lie head $h \in [0, 7]$).
  - Each workgroup evaluates causal dot-product attention $Q_{t, h} \cdot K_{s, h}$ across $s \le t \le T$.
  - Scaled by $1/\sqrt{320} = 0.0559017$.
  - Normalizes via workgroup-local softmax and multiplies by $V_{s, h}$.
  - Backward kernel `geomind_causal_mha_backward` backpropagating adjoint gradients $dh$.
- **Selective Gating Update in `geomind_autoregressive_step`**:
  - Pass `ic_weight` into `geomind_autoregressive_step`.
  - Calculate dynamic decay $\alpha = \text{clamp}(0.50 + 0.15 \cdot \text{IC}, 0.40, 0.92)$.
  - Seed initial chunk hidden state from `g_buf_prev_chunk_h` when available (inter-chunk continuity).
- **Hopfield Memory Injection in Forward Pipeline**:
  - Periodically project salient tokens into the Hopfield working memory bank and blend resonant attractors into $h_t$.
- **CPU Fallback Matching**:
  - Implement matching Causal MHA and selective decay in `cartan_tensor_train_step` and validation holdout.

### 2. `test/geomind/main.car`
- Validate and update CLI flags, keeping full compatibility with `--train-pre`, `-temp`, and analogy evaluation.

---

## Verification Plan
1. **Compilation**: Clean build via `cartanc.exe build test/geomind/main.car -o test/geomind/geomind.exe`.
2. **Binary Synchronization**: Ensure identical SHA-256 hashes across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
3. **Analogy Verification**: Verify all 4 semantic vector analogies remain at Rank 1.
4. **Empirical Pretraining Test**: Run a validation pass on `storytelling_corpus_clean.txt` and verify that Causal MHA, Selective Gating, and Hopfield memory execute with authentic Shannon telemetry.
