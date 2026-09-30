# Sprint 473 Implementation Plan: Full-Vocabulary Gemma 4 Layer Alignment, Safetensors Ingestion & Zero-Mock Transformer Execution Substrate

## 1. Objectives
Eliminate all stubbed features and phantom checkpoints ([`ISSUE-264`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md#L3603)–[`ISSUE-267`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md#L3642)).
Architect and implement the complete, authentic Gemma 4 transformer decoder execution substrate in CARTAN with full layer alignment across sliding ($d_{\text{head}}=256, \theta=10,000$) and global ($d_{\text{head}}=512, \theta=1,000,000$) attention layers, Per-Layer Embedding (PLE) gating, QK-Norm, layer scalars, and logit soft-capping.
Integrate full-vocabulary ($262,144$ tokens) safetensors extraction and tiered memory hierarchy (Hot VRAM / Warm System RAM / Cold NSES SQLite Data Warehouse).

---

## 2. Technical Scope & Squad Alignments

### A. Layer Alignment & Primitives Upgrade (`src/std/transformer.cl`)
1. **Per-Head QK-Norm**:
   - Apply RMSNorm independently across each Query head ($8$ heads $\times d_{\text{head}}$) and Key head ($2$ heads $\times d_{\text{head}}$) prior to RoPE and dot product attention:
     $$q_{h} = \text{RMSNorm}(q_{h}, w_{q,\text{norm}}), \quad k_{h} = \text{RMSNorm}(k_{h}, w_{k,\text{norm}})$$
2. **Dual-Theta RoPE Dispatch**:
   - Sliding Attention ($l \notin \{5, 11, 17, 23, 29, 35, 41\}$): $d_{\text{head}} = 256, q_{\text{dim}} = 2048, kv_{\text{dim}} = 512, \theta = 10,000$.
   - Global Attention ($l \in \{5, 11, 17, 23, 29, 35, 41\}$): $d_{\text{head}} = 512, q_{\text{dim}} = 4096, kv_{\text{dim}} = 1024, \theta = 1,000,000$.
3. **Per-Layer Embedding (PLE) Gating Block**:
   - Ingest per-layer embedding vector $v_{\text{ple}} \in \mathbb{R}^{256}$ (scaled by $\sqrt{256}$):
     $$\text{gate} = W_{\text{ple,gate}} \cdot h_2, \quad \text{act} = \text{GELU}(\text{gate}) \odot v_{\text{ple}}$$
     $$h_3 = h_2 + \text{RMSNorm}(W_{\text{ple,proj}} \cdot \text{act}, w_{\text{ple,norm}})$$
4. **Layer Scalar Scaling**:
   - Apply per-layer scalar multiplier: $h_{\text{out}} = h_3 \cdot s_{\text{layer}}$.
5. **Logit Soft-Capping & Tied LM Head**:
   - Implement `cartan_logit_softcap(logits: ptr, cap: float) -> ptr`:
     $$\text{logits}_{\text{capped}} = \text{cap} \cdot \tanh\left(\frac{\text{logits}}{\text{cap}}\right), \quad \text{cap} = 30.0$$

### B. High-Performance Full-Vocabulary Ingestion Substrate (`tools/clone_gemma_to_cartan.py`, `src/std/hub.cl`)
1. **Full 262,144 Vocabulary Pipeline**:
   - Ingest the authentic $[262144, 2560]$ token embedding matrix and $[262144, 256]$ PLE matrix directly from `cache_google_gemma-4-E4B-it_model.safetensors`.
   - Eliminate all artificial concept mappings, scaling hacks ($1.20$), and token truncation.
2. **Zero-Mock Checkpoint Serialization**:
   - Replace 12-byte dummy file creation in `src/std/hub.cl` with validated tensor offsets and aligned binary buffers.
   - Support memory-mapped loading for zero-copy streaming through System RAM (Tier 2).

### C. Dedicated Verification Suite (QA Gate Target 83)
1. Author Target 83 (`test/compiler_suite/test_gemma4_layer_alignment.car`):
   - Gate 1: Per-Head QK-Norm mathematical validation.
   - Gate 2: Sliding Attention vs Global Attention layer alignment (head dimension 256 vs 512, RoPE theta 10k vs 1M).
   - Gate 3: Per-Layer Embedding (PLE) gating and layer scalar execution.
   - Gate 4: Logit soft-capping bound check ($|\text{logit}| \le 30.0$).
2. Whitelist Target 83 in `.gitignore` and register in `test/compiler_suite/run_tests.car`.

---

## 3. Definition of Done (DoD)
- [ ] `src/std/transformer.cl` upgraded with QK-Norm, PLE gating, dual-theta RoPE, layer scalars, and logit soft-capping.
- [ ] Target 83 compiles and passes cleanly with authentic mathematical assertions.
- [ ] Full regression suite passes cleanly (83/83 targets).
- [ ] No placeholder constants, synthetic sine noise, or dummy files.
- [ ] Sprint Walkthrough, Changelog, and Issues updated and archived.
