# Sprint 474 Plan: Native 42-Layer Gemma Ingestion & 3-Tier Execution Pipeline

## 1. Sprint Goal
Implement authentic Gemma 4 model execution in CARTAN/GeoMind:
1. Replace phantom 12-byte checkpoint stubs in `src/std/hub.cl` with verified binary checkpoint ingestion and streaming layer loaders.
2. Wire genuine multi-layer decoder evaluation and tied-embedding LM head projection with logit soft-capping in `test/geomind/chat.cl`.
3. Implement 3-Tier memory architecture (Hot VRAM compute + Warm Host RAM 262k cache + Cold NSES Cognitive Warehouse for "tip of the tongue" reflective retrieval).
4. Prove zero regressions via QA Target 84 (`test/compiler_suite/test_gemma4_full_model_execution.car`).

---

## 2. User Stories
- **Story 1 (Hub Layer Ingestion)**: As the runtime engine, I require `src/std/hub.cl` to validate binary checkpoint headers and stream real layer tensors from disk/RAM into active compute buffers without mock stubs.
- **Story 2 (Authentic Transformer Forward Pass)**: As GeoMind, I require `test/geomind/chat.cl` to look up authentic 2,560-dim token embeddings from the full 262k table, evaluate Gemma decoder blocks via `cartan_gemma_layer_forward`, apply final RMSNorm, and compute tied-embedding LM head logits with soft-capping $[-30, 30]$.
- **Story 3 (Tier 3 Reflective Doubt Warehouse)**: As the reasoning mind, when my top-1 token confidence drops below threshold ("it's on the tip of my tongue"), I query the NSES SQLite cognitive warehouse for domain attractors to resolve uncertainty before sampling.
- **Story 4 (Empirical QA Proving)**: As the QA squad, I require Target 84 to verify all 5 stages of the pipeline with 100% mathematical precision under `cartanc.exe`.

---

## 3. Definition of Done (DoD)
- [ ] `src/std/hub.cl` eliminated all 12-byte dummy checkpoints and synthetic cosine fallbacks.
- [ ] `test/geomind/chat.cl` executes genuine full embedding lookup, decoder layer forward passes, final RMSNorm, and tied LM head projection.
- [ ] Tier 3 reflective doubt retrieval connected to NSES cognitive database upon confidence dips.
- [ ] Target 84 (`test_gemma4_full_model_execution.car`) authored, compiled with Zig `-O3 LTO`, and verified.
- [ ] Regression suite passes 84/84 targets with zero regressions.
- [ ] `ISSUES.md` updated (`[ISSUE-264]` and `[ISSUE-265]` marked FIXED).
- [ ] `CHANGELOG.md` updated with concise entry.
- [ ] All artifacts saved to `docs/archive/`.
