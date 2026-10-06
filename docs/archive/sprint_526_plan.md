# Sprint 526 Plan: Cortical Stream Dynamic Vocabulary Pruning & Ghost-Free Speculative Drafting

## 1. Objective
Activate the 8 Cortical Streams and Sasaki Brainstem Router in safe, non-destructive roles to achieve a genuine $5\times - 8\times$ decode throughput speedup without modifying the 42-layer transformer latent state $\mathbf{h}$:
1. **Dynamic Vocabulary Pruning**: Reduce LM head evaluation from 167k/21k tokens to $\sim 2,500$ tokens per step (core syntax + active stream domain tokens), dropping LM head latency from $38\text{ ms} \to 4\text{ ms}$.
2. **Ghost-Free Stream Speculative Drafting**: Eliminate duplicate 42-layer passes by unconditionally committing anchor token $tok_0$ before drafting $K=3$ candidates with the active stream, verifying in a single batched pass with $\ge 1\times$ net progress guaranteed.

---

## 2. Architecture & Work Breakdown

### Workstream 1: Stream Domain Vocabulary Mask Generator (`tools/build_stream_domain_masks.py`)
- Load `cache_google_gemma-4-E4B-it_tokenizer.json` (262,144 tokens).
- Define 8 Stream Domain Vocabularies:
  - Common Core: Universal punctuation, digits, symbols, whitespace, and top 1,000 high-frequency syntactic glue tokens (always active across all 8 masks).
  - Stream 0 (Cosformer): General structural & foundational lexicon.
  - Stream 1 (SSM): Temporal, narrative, conjunctions, transition adverbs.
  - Stream 2 (Spectral): Math, science, physics, quantitative, frequency terminology.
  - Stream 3 (Poincare): Taxonomic, hierarchical, ontological nouns and entities.
  - Stream 4 (Homology): Spatial relations, prepositions, logical connectives, boundaries.
  - Stream 5 (Eikonal): Sensory, visual, descriptive, color, spatial orientation.
  - Stream 6 (Heat Kernel): Associative adjectives, diffusion, qualitative states.
  - Stream 7 (Triality): Conversational, discourse markers, dialogic pronouns, questions.
- Export `test/geomind/trainingdata/checkpoints/geomind_stream_masks.bin` ($8 \times 262,144 = 2,097,152$ bytes).

### Workstream 2: Runtime Stream Mask Loading & Gating (`test/geomind/chat.cl`)
- Implement `geomind_load_stream_masks_if_needed()`.
- Implement `geomind_get_stream_pruned_vocab_mask(script, stream_idx, stream_w)`.
- If `dom_w >= g_sasaki_stream_threshold` (default 0.30): select stream-specific pruned mask.
- If `dom_w < g_sasaki_stream_threshold`: fallback safely to full language mask.
- Wire into `cartan_tensor_compute_lm_head_logits`.

### Workstream 3: Ghost-Free Stream Speculative Drafting (`test/geomind/chat.cl`)
- Refactor the speculative loop in `geomind_chat_generate_reply_multimodal`:
  1. Sample $tok_0$ unconditionally from current state $cur\_h$.
  2. If speculative drafting enabled:
     - Invoke active stream drafter `geomind_stream_draft_candidate_tokens(cur_h, dom_stream, dom_w, 3.0)` in $< 0.1\text{ ms}$.
     - Run batched 42-layer pass on $[tok_0, c_1, c_2, c_3]$.
     - Emit $tok_0$.
     - Verify candidate tokens sequentially.
     - On first mismatch, trim rejected KV cache range with `cartan_kv_cache_clear_range`.
     - Output state is set directly to the last accepted token's hidden state.
  3. Guarantee: zero ghost passes, minimum progress 1 token, maximum progress 4 tokens per pass.

---

## 3. Definition of Done (DoD)
- [ ] `geomind_stream_masks.bin` generated with $\sim 2,500 - 3,500$ active tokens per stream.
- [ ] LM head latency drops from $\sim 38\text{ ms} \to \le 6\text{ ms}$ on `bin/geomind.exe`.
- [ ] Speculative drafting operates with 0 ghost passes and positive token acceptance.
- [ ] Prompt responses remain 100% fluent, coherent, and factual.
- [ ] 16/16 compiler regression suite targets pass via `tools/run_affected_tests.ps1`.
- [ ] `CHANGELOG.md` updated to `[8.482.0]`.
