# Startup Code Review: Sprint 476 (Gemma 4 42-Layer Stream & Execution)
**Date**: 2026-09-28
**Investigator**: Supervisor Agent & Team
**Target**: `test/geomind/chat.cl`, `src/std/transformer.cl`, `test/geomind/e8_attention_engine.cl`, `tools/clone_gemma_to_cartan.py`

---

## 1. Executive Summary & Forensic Discoveries

### Discovery 1: Synthetic 16-Step Scalar Polynomial Formula Replacing Genuine Transformer Decoder
- **Location**: [`test/geomind/e8_attention_engine.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/e8_attention_engine.cl#L185-L203) invoked by [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl#L897) & [line 1011](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl#L1011).
- **Finding**: Generation relies on `e8_attention_forward_step_with_momentum`, which executes a synthetic 16-step polynomial scalar formula `0.25 * gelu_z * (1.0 + tanh(kappa * z * kw))` instead of the authentic 42 Google Gemma 4-E4B Transformer decoder layers.
- **Root Cause of Failed Generation ("before object last class? Not.... mitosis...")**: Without passing hidden states through trained attention projection matrices ($W_q, W_k, W_v, W_o$) and GeGLU feedforward blocks ($W_{\text{gate}}, W_{\text{up}}, W_{\text{down}}$), the token representations have zero contextual self-attention, and the LM head performs raw nearest-neighbor lookup on non-contextual pooled embeddings.

### Discovery 2: Premature Reflective Doubt Trigger & Rule Attractor #0 Context Rewind
- **Location**: [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl#L934).
- **Finding**: Doubt condition `if (rewind_executed == 0.0 && step >= 2.0 && (conf < 0.05 || ent > 3.50))` triggers almost immediately on step 2 under top-50 sampling (where baseline uniform confidence is $1/50 = 0.02$).
- **Impact**: Trajectory is abruptly rewound to the scaffold checkpoint, and Tier 3 Cognitive Warehouse injects rule attractor #0 (`"object"`), hijacking generation and yielding attractor words like `"object"`, `"last"`, `"class"`.

### Discovery 3: Disk I/O Thrashing in LM Head Projection
- **Location**: [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl#L273-L338).
- **Finding**: `cartan_tensor_compute_lm_head_logits` opens `g_full_emb_path` (`fopen`) and performs 262,144 individual 10 KB `fread` calls per token step, repeatedly streaming 2.68 GB from disk for each generated token.

---

## 2. Logical Dependency Tree

```
[cache_google_gemma-4-E4B-it_model.safetensors] (15.99 GB Donor Checkpoint)
  │
  ├──> [tools/clone_gemma_to_cartan.py] (Binary Extraction Pipeline)
  │      ├─> geomind_embeddings_full_262k.bin (2.68 GB)
  │      ├─> geomind_ple_embeddings_full_262k.bin (268 MB)
  │      ├─> geomind_final_norm.bin (10 KB)
  │      └─> layers/gemma4_layer_{0..41}.bin (Sequential Layer Weight Streams)
  │
  ├──> [src/std/transformer.cl]
  │      ├─> cartan_rmsnorm & cartan_rmsnorm_head
  │      ├─> cartan_rope_apply (dynamic theta: 10,000 / 1,000,000)
  │      ├─> cartan_gqa_causal_attention (Q-rot, K-cache, V-cache)
  │      ├─> cartan_geglu_mlp_forward (GeGLU gate + up + down)
  │      ├─> cartan_ple_gate_forward (per-layer embedding gate)
  │      └─> cartan_gemma_layer_forward (Full Single-Layer Decoder Step)
  │
  ├──> [test/geomind/chat.cl]
  │      ├─> geomind_execute_gemma_layers (Iterates l = 0..41 via layer streaming)
  │      ├─> cartan_tensor_compute_lm_head_logits (In-memory buffered projection + 30.0 softcap)
  │      ├─> cartan_tokenizer_sample_topp_topk (Top-P 0.90, Top-K 50)
  │      └─> Calibrated Reflective Doubt (conf < 0.01 || ent > 5.50)
  │
  └──> [build/geomind.exe] & [test/compiler_suite/run_tests.car]
         └─> Empirical Prompt Generation: "In biology, cells divide through" -> "mitosis"
```

---

## 3. Issues Created in Backlog (`ISSUES.md`)

1. **`[ISSUE-272]`**: Synthetic 16-Step Polynomial Formula in `chat.cl` Instead of Authentic 42-Layer Gemma Transformer Forward Pass.
2. **`[ISSUE-273]`**: Premature Reflective Doubt Trigger (`conf < 0.05`) Hijacking Generation to Rule Attractor #0 (`"object"`).
3. **`[ISSUE-274]`**: 262k Vocabulary Projection Repeated Disk I/O Thrashing (2.68 GB per token) in `chat.cl`.
