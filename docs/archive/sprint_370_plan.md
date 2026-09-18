# Sprint 370: Geometric Transformer Architecture Optimization & Non-Euclidean Embedding Alignment

## 1. Sprint Goal
Optimize CARTAN's transformer and attention mechanisms to natively exploit the non-Euclidean Finsler-Randers geometry and Killing-Cartan metric tensor across the 8 Lie submanifolds. Eliminate Euclidean approximations in attention dot products, residual connections, and embedding arithmetic, aligning with foundational vector embedding principles ($v(\text{King}) - v(\text{man}) + v(\text{woman}) \approx v(\text{queen})$, $v(\text{father}) - v(\text{man}) + v(\text{woman}) \approx v(\text{mother})$) to guarantee 100% geometric alignment without embedding collapse.

## 2. Pre-Sprint Scrum & Code Review Discoveries
1. **Donor Token Mismatch in Concept Slot Mapping**:
   In `tools/merge_slerp_weights.py` and `src/std/tokenizer.cl`, concept slots $2510..2518$ were mapped using incorrect donor indices (e.g. `father` mapped to 2862 'organ', `mother` to 2988 'prote') instead of the true `gemma_vocab_65k.bin` IDs (`father`: 6353, `mother`: 5946, `girl`: 3953, `boy`: 6938, etc.).
2. **Dynkin Metric Discrepancy in SLERP Fusion**:
   `tools/merge_slerp_weights.py` used arbitrary monotonic weights `[1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0]` rather than the canonical Killing-Cartan Dynkin form weights `[2.0, 3.0, 4.0, 1.0, 5.0, 2.5, 1.5, 2.0]` defined in `src/std/geom.cl`.
3. **WebGPU Attention Shader Metric Omission & Truncation**:
   `webgpu_get_causal_attn_shader()` in `train.cl` truncated attention scoring to $d < 64$ (ignoring 2496 dimensions of the 2560-D model), used a hardcoded flat scalar `* 2.0f`, recomputed dot products redundantly inside the $D$ loop, and performed flat unconstrained residual addition.
4. **Euclidean Flatness in Vector Analogy Arithmetic**:
   `geomind_eval_single_analogy` in `test/geomind/main.car` evaluated cosine similarity with flat $\delta_{ij}$ Euclidean dot products, failing to contract with the metric tensor $G$.
5. **Multi-Head Sliding Window Attention in `e8_attention_engine.cl`**:
   Lacked manifold retraction and RMSNorm normalization in residual accumulation.

## 3. Implementation Tasks
- [ ] **Task 1: Concept Slot & Dynkin Metric Alignment in SLERP Fusion Engine**
  - Update `tools/merge_slerp_weights.py` with canonical Dynkin weights `[2.0, 3.0, 4.0, 1.0, 5.0, 2.5, 1.5, 2.0]`.
  - Correct all concept slot mappings to match `gemma_vocab_65k.bin` (father: 6353, mother: 5946, daughter: 8709, girl: 3953, boy: 6938, sister: 12198, brother: 10070, cat: 5866, dog: 4799).
  - Update `src/std/tokenizer.cl` `tokenizer_map_concept_slot` to match.
  - Re-execute `tools/merge_slerp_weights.py` to regenerate pristine non-Euclidean checkpoints.
- [ ] **Task 2: Metric-Contracted Vector Analogy Arithmetic & Similarity**
  - Refactor `geomind_eval_single_analogy` in `test/geomind/main.car` to contract all vector inner products and norms with the Killing-Cartan metric tensor $G_{rr} = g_{\lfloor r/320 \rfloor}$.
- [ ] **Task 3: Full-Spectrum Non-Euclidean Causal Attention Shader**
  - Rewrite `webgpu_get_causal_attn_shader()` in `test/geomind/train.cl`:
    - Compute multi-head attention across all 8 Lie submanifolds (8 heads of 320 dimensions).
    - Contract $Q K^T$ with the head's Dynkin weight $g_s$.
    - Scale attention logits by $\frac{1}{g_s \sqrt{320}}$.
    - Compute attention weights once per token pair before value accumulation.
    - Apply manifold retraction / energy-preserving normalization to the attention residual.
- [ ] **Task 4: Pure Native Geometric Attention Enhancement**
  - Endow `e8_multihead_sliding_window_attention` in `test/geomind/e8_attention_engine.cl` with Riemannian residual connection and anisotropic RMSNorm.
- [ ] **Task 5: Compilation, Binary Synchronization & Empirical Validation**
  - Recompile with native self-hosting `cartanc.exe`.
  - Synchronize bit-for-bit SHA-256 binaries across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
  - Empirically verify all vector analogies:
    - King - man + woman = queen
    - he - him + her = she
    - father - man + woman = mother
  - Verify Cloze training stability.
- [ ] **Task 6: Documentation, ISSUES.md & CHANGELOG.md**
  - Record Issue 120 in `ISSUES.md`.
  - Update `CHANGELOG.md`.
  - Archive plan and walkthrough.
