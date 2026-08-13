# Sprint 82 Implementation Plan: Authentic English GEMM & SFT Grokking Engine

## 1. Executive Summary & Core Objective
- **Objective**: Transform GeoMind into a fluently speaking English model by replacing scalar float hacks with true $V$-dimensional matrix multiplication ($Z = W_{\text{lm\_head}} \cdot h_{32}$) across all 49,152 vocabulary tokens, combined with Softmax Top-$P$ nucleus sampling and autograd SFT backpropagation.

---

## 2. Architectural Pipeline
```
[Prompt Tokens] ──> [32-Layer E8 / MoE Stack] ──> [Hidden Vector h_32 ∈ ℝ^768]
                                                         │
                                                         ▼
                                            [Full 2D W_lm_head GEMM (Z = W_lm_head * h_32)]
                                                         │
                                                         ▼
                                            [Softmax Temperature + Top-P Sampler]
                                                         │
                                                         ▼
                                            [Decoded English Sentence Tokens]
```

---

## 3. Step-by-Step Implementation
1. **`test/geomind/chat.car`**:
   - Implement `geomind_compute_full_vocab_logits(w_lm_head, h_32, vocab_size, d_model)` to calculate dot products $z_v = \sum_{d} W_{\text{lm\_head}}[v, d] \cdot h_{32}[d]$ for all 49,152 vocabulary rows.
   - Implement `geomind_softmax_sample_top_p(logits, vocab_size, temp, top_p)` to sample natural English tokens from the logit distribution.
   - Autoregressively update hidden states and decode tokens into clean English sentences.
2. **`test/geomind/sft_train.car`**:
   - Execute autograd gradient updates across parameter weights using cross-entropy loss over English dialogue text until loss decays to grokking thresholds.
3. **Rebuild & Synchronize**:
   - Rebuild `geomind.exe` using `cartanc.exe` and sync to root and `bin/`.
4. **Verification**:
   - Run `geomind.exe --chat` and verify fluent English sentence generation.
5. **Documentation**:
   - Log Sprint 82 in `CHANGELOG.md` and update `docs/ROADMAP.md`.
