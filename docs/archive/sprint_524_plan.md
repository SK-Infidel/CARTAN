# Sprint 524 Plan: Invariant-Safe Sparse Cortical MoE Dynamic Routing & Live Hippocampal Fast Weights

## Mission Statement
Eradicate semantic hallucination and token degeneration caused by raw-embedding layer bypass in `geomind.exe`, establish invariant-safe Sparse Cortical MoE dynamic routing across post-attention layers 24..40, and implement genuine 2560D semantic token-embedding ingestion and live episodic fast-weight resonance for the Continuous Hopfield Resonator.

---

## 1. Architectural Strategy & Invariant Guarantees

### A. Invariant-Safe Sparse Cortical MoE (Layers 24..40 Bypass)
1. **Hard Invariant 1 (KV Cache Integrity)**:
   - Layers 0..23 MUST unconditionally execute authentic GQA attention and populate all 24 KV cache layers for every prompt and decode token.
   - Eliminates arbitrary `memcpy` KV replication and guarantees valid attention history across all sequence positions.
2. **Hard Invariant 2 (Contextualized Latent Scale)**:
   - Sasaki Brainstem Router evaluation on $(x, \dot{x})$ occurs at layer 24 on the fully contextualized hidden state $h_{24}$.
   - If dominant stream confidence $w^* \ge \tau_{\text{stream}}$:
     - Modulate $h_{24}$ using the closed-form Lie stream ($\text{stream\_process}(h_{24})$).
     - Bypass intermediate layers 25..40 directly into Anchor Layer 41.
     - Skips 16 dense transformer layers (38% layer compute reduction) while maintaining correct latent vector magnitude and attention context for Layer 41 and the LM head.
   - If $w^* < \tau_{\text{stream}}$:
     - Apply stream pre-conditioning (10% blend into $h_{24}$) and execute layers 25..40 (with thermodynamic early exit active).

### B. Live Hippocampal Fast Weights (Continuous Hopfield Resonator)
1. **Semantic Text Ingestion (`--ingest`)**:
   - Refactor `cartan_hopfield_ingest` to tokenize passages using the BPE tokenizer (`cartan_hub_encode_text_to_tokens`).
   - Compute authentic 2560D mean-pooled token embeddings from the 262k embedding table and register them into `g_hopfield_key_bank` and `g_hopfield_val_bank`.
   - Save updated attractor basins to `test/geomind/trainingdata/hopfield_basins.bin`.
2. **In-Flight Fast Weight Ingestion & Episodic Resonance**:
   - In `test/geomind/chat.cl`, ingest each conversation turn's hidden state $h_{\text{final}}$ into the Continuous Hopfield memory as a fast weight.
   - Query Hopfield attractor basins with 2560D hidden states to dynamically steer latent trajectories toward relevant episodic memories without backpropagation.

---

## 2. Squad Allocations & Subagent Responsibilities
- **cartan_architect**: Formalize mathematical invariants for post-attention stream bypass and Hopfield energy minimization.
- **cartan_runtime_engineer**: Implement 2560D semantic BPE ingestion in `src/std/resonator.cl` and wire safe layer 24 routing in `test/geomind/chat.cl`.
- **cartan_qa_tester**: Empirically verify live `geomind.exe` generation coherence, `--ingest` attractor persistence, and run the compiler regression suite.
