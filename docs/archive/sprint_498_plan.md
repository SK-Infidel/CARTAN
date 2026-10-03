# Sprint 498 Plan: Restore Natural Language Generation & Manifold Coherence in GeoMind

## Goal
Restore pristine, coherent English dialogue generation in `geomind.exe` by eliminating destructive latent warping, restoring full causal KV-cache prefill integrity, purging poisoned conversational episodes from SQLite, and streamlining prompt conditioning.

## User Stories
1. **US-498.1: Full Causal Sequence Prefill & KV-Cache Integrity**:
   As Rick, I want `geomind.exe` to populate authentic Key-Value caches for all prompt tokens across all 42 transformer layers, so causal attention operates accurately during autoregressive decoding.
2. **US-498.2: Non-Destructive Manifold Latent State Preservation**:
   As Rick, I want WebGPU execution during chat to preserve the calibrated mathematical representation of the 2560-dimensional hidden state vector without distorting sectors with ad-hoc math, so LM head softcapping projects clean logits.
3. **US-498.3: Clean Dialogue Context & Streamlined Conditioning**:
   As Rick, I want corrupted episodes purged from cognitive memory and a concise, robust instruction turn format, so the model generates natural language responses rather than repetitive pseudo-code.

## Quality Gates & DoD
- [ ] Gate 1: `geomind_execute_manifold_sequence_prefill` passes all prompt tokens through the 42 layers and fully populates KV caches.
- [ ] Gate 2: Latent warping shaders (`chat_streams_fwd`) neutralized; WebGPU manifold dispatch performs genuine identity/norm operations that preserve representation alignment.
- [ ] Gate 3: Corrupted episodes cleared from `test/geomind/trainingdata/cognitive_memory.db`.
- [ ] Gate 4: Empirical verification: `geomind.exe -prompt "What is the capital of Germany?" -tokens 20` outputs coherent English (`"The capital of Germany is **Berlin**."`).
- [ ] Gate 5: All 88 regression test suite targets pass 88/88 via `tools/run_affected_tests.ps1 -All`.
- [ ] Gate 6: `CHANGELOG.md` and `ISSUES.md` updated, artifacts archived.
