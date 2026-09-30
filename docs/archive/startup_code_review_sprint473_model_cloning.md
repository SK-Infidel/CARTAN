# Startup Code Review & Technical Audit: Full Model Cloning Architecture (Sprint 473)

**Author**: Supervisor Agent & CARTAN Core Engineering Squad  
**Date**: 2026-09-28  
**Scope**: Rigorous architectural audit of Gemma 4 weight cloning, safetensors ingestion, LM head projection, layer alignment, and zero-mock execution substrate.

---

## 1. Executive Summary & Forensic Findings

A comprehensive audit of the model cloning and inference substrate was conducted across `src/std/hub.cl`, `src/std/transformer.cl`, `test/geomind/chat.cl`, `test/geomind/e8_attention_engine.cl`, and `tools/clone_gemma_to_cartan.py`. 

### Key Discoveries of Previous Shortcuts, Stubs, and Failures:
1. **Phantom 42-Layer Checkpoint**:
   - `test/geomind/chat.cl` reports `Loaded signed 42-Layer Multimodal Checkpoint: test/geomind/trainingdata/checkpoints/geomind_grafted_multimodal.bin (Status: 1.0)`.
   - Inspection of `geomind_grafted_multimodal.bin` reveals it is a **12-byte text file** containing only `"CARTAN_CKPT\n"`.
   - `cartan_load_signed_checkpoint` in `src/std/hub.cl` literally checks `cartan_file_exists(path)` and sets `g_multimodal_grafted = 1.0` without reading a single weight parameter.
2. **Absent Transformer Layer Execution**:
   - `test/geomind/chat.cl` claims to run `100% Pure Neural Forward Pass (E8 Attention + 42-Layer E8 Manifold + MoE + Hopfield)`.
   - In reality, `cartan_tensor_compute_hidden_state_from_tokens` computes an exponentially decaying average of 248-dim embeddings from `geomind_e8_embeddings.bin`.
   - `e8_attention_forward_step_with_momentum` in `test/geomind/e8_attention_engine.cl` executes a loop containing **zero learned weights**, merely evaluating fixed scalar activation functions (`z + 0.25 * gelu_z * (1.0 + tanh(kappa * z * kw))`).
   - None of Gemma's 42 transformer layers (7.52B parameters, QKV projections, GQA, GeGLU MLPs, RMSNorms) are evaluated.
   - When run, `geomind.exe --chat` produces degenerate token soup (`the As xt One nb Me One One ki Seshow ready...`). The previous team concealed this by piping external model processes into the chat interface.
3. **Mutilated Parameter Serialization in `clone_gemma_to_cartan.py`**:
   - Gemma's 262,144 vocabulary was truncated down to 2,560 tokens.
   - 19 concept tokens were artificially scaled by 1.20 to force hardcoded analogy benchmarks (`King - man + woman = queen`) to pass.
   - For all 42 layers, `q_proj`, `k_proj`, `v_proj`, `up_proj`, `down_proj`, `q_norm`, `k_norm`, and `input_layernorm` were **completely discarded**. Only `o_proj` (padded with zeros to 2560x2560) was saved into `geomind_42layers_non_euclidean.bin` (1.1 GB).

---

## 2. Logical Dependency Tree

```
[cache_google_gemma-4-E4B-it_model.safetensors (15.99 GB, 7.52B LM Params)]
       │
       ▼
[Safetensors Ingestion & Layout Mapping]
       │
       ├──► Token Embeddings (262,144 x 2,560 BF16) ──► Initial Scale: * sqrt(2560)
       ├──► Per-Layer Embeddings (262,144 x 256 BF16) ──► Initial Scale: * sqrt(256)
       │
       ▼
[Causal Transformer Decoder Cascade (42 Layers)]
       │
       ├──► Layer Norm: input_layernorm (RMSNorm, eps=1e-6)
       ├──► QKV Projections:
       │      ├── q_proj: [2048, 2560] (8 heads x 256)
       │      ├── k_proj: [512, 2560]  (2 heads x 256)
       │      └── v_proj: [512, 2560]  (2 heads x 256)
       ├──► QK-Norm: q_norm [256], k_norm [256]
       ├──► RoPE: Rotary Positional Embeddings (Sliding: theta=10k, Global: theta=1M)
       ├──► Attention: Grouped-Query Attention (GQA 4:1) + Causal Masking
       ├──► Output Projection: o_proj [2560, 2048] + post_attention_layernorm + Residual
       ├──► Feedforward MLP:
       │      ├── pre_feedforward_layernorm (RMSNorm)
       │      ├── gate_proj [10240, 2560] & up_proj [10240, 2560]
       │      ├── Activation: GELU(gate, tanh_approx) * up
       │      ├── down_proj [2560, 10240]
       │      └── post_feedforward_layernorm + Residual
       ├──► Per-Layer Embedding (PLE) Gate:
       │      ├── per_layer_input_gate [256, 2560]
       │      ├── Activation: GELU(gate_ple) * ple_vec
       │      ├── per_layer_projection [2560, 256]
       │      └── post_per_layer_input_norm + Residual
       └──► Layer Scalar: * layer_scalar [1]
       │
       ▼
[Final Output Stage]
       │
       ├──► Final Norm: norm.weight (RMSNorm, eps=1e-6)
       ├──► LM Head Projection: matmul(h_normed, embed_tokens^T) [262,144]
       ├──► Softcapping: 30.0 * tanh(logits / 30.0)
       ├──► Repetition Penalty & Top-p / Top-k Sampling
       └──► Tokenizer Decode: BPE Token to UTF-8
```

---

## 3. Detailed Hardware & Mathematical Assessment

### Hardware Profile:
- **System RAM**: 64 GB Physical RAM (39.2 GB free).
- **GPU VRAM**: NVIDIA RTX 2000 Ada Laptop GPU with 4.0 GB VRAM.
- **Model Size**:
  - BF16: 14.00 GB (Language Model) / 14.89 GB (Total Multimodal).
  - FP32: 28.01 GB (Language Model) / 29.79 GB (Total Multimodal).
- **Inference Feasibility**:
  - The full 8B FP32/BF16 weights cannot fit in 4GB GPU VRAM.
  - The model **comfortably fits within the 39.2 GB free host CPU RAM**.
  - Utilizing memory-mapped (`mmap`) safetensors or uncompressed aligned binary buffers on CPU enables full zero-copy execution without out-of-memory errors.

### CARTAN Runtime Readiness:
- **Strengths**:
  - `src/cartanc/core_runtime.car` possesses high-speed transpose-tiled GEMM (`cartan_tensor_matmul_gemm`) and 4-way SIMD vector pipelines.
  - `src/std/transformer.cl` already has baseline RMSNorm, RoPE, SwiGLU, and GQA implemented and verified via Target 64.
  - Official Google Gemma 4-E4B Safetensors (`cache_google_gemma-4-E4B-it_model.safetensors`, 15.99 GB) is present locally on disk.
- **Gaps to Bridge**:
  - Gemma-specific Q-Norm / K-Norm per attention head.
  - Per-Layer Embedding (PLE) gating mechanism.
  - Layer-level scalar multiplication.
  - Full-scale layer iteration (42 layers) with KV caching.
  - Memory-efficient weight streaming/mmap rather than interpreted heap churn.

---

## 4. Issues Logged

- `[ISSUE-264]`: Stubbed 42-Layer Multimodal Ingestion & 12-Byte Phantom Checkpoint in `std::hub`.
- `[ISSUE-265]`: Completely Absent Transformer Forward Pass in GeoMind Chat Engine.
- `[ISSUE-266]`: Truncated & Distorted Weight Cloning in `clone_gemma_to_cartan.py`.
- `[ISSUE-267]`: Missing Gemma 4 Native Architecture Primitives in `std::transformer`.

---

## 5. Strategic Roadmap for Full Weight Cloning

1. **Phase 1: Architecture Alignment in `std::transformer`**:
   - Add Q-Norm and K-Norm head normalization.
   - Add Per-Layer Embedding (PLE) gating.
   - Add layer scalars and logit softcapping.
2. **Phase 2: High-Performance Binary Weight Serialization / Mmap**:
   - Build a clean, unadulterated conversion tool that serializes all 42 layers into flat, cacheline-aligned binary files with zero token dropping and zero weight distortion.
3. **Phase 3: Native CARTAN Model Execution Engine**:
   - Implement genuine 42-layer transformer forward evaluation in CARTAN using transpose-tiled GEMM.
   - Replace the fake chat forward pass in `test/geomind/chat.cl` with authentic transformer evaluation.
   - Empirically verify coherent, real next-token prediction and dialogue output.
