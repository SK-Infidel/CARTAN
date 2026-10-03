# Sprint 510 Plan: Sovereign Cognitive Memory & Multi-Turn KV Continuity

**Date**: October 1, 2026  
**Architect**: Rick (Big Daddy)  
**Lead Engineer**: Antigravity  
**Goal**: Sub-second multi-turn prompt prefill via persistent KV cache continuity, FIFO context window management, and triggered associative memory recall.

---

## 1. High-Level Objectives

1. **Persistent Multi-Turn KV Continuity (Incremental Prefill)**:
   - On Turn 1: Prefill initial prompt (`<bos>`, system preamble, user query) into positions $0 .. N_1 - 1$.
   - On Turn $N > 1$: Never wipe the KV cache. Format *only* the new turn tokens and prefill incrementally into positions $pos .. pos + N_{new} - 1$.
   - Eliminate re-prefilling past turns from SQLite, keeping prefill latency **< 0.5 seconds permanently** across any conversation length.
2. **Positional Parameterization in Batch Layer Forward**:
   - Update `cartan_manifold_layer_forward_batch` to support `start_pos`.
   - Ensure RoPE rotates by `(start_pos + p) * freq` and KV cache stores into `(start_pos + p) * kv_dim`.
3. **Triggered Associative Recall ("Remember when...")**:
   - Implement `geomind_chat_detect_associative_trigger(prompt)`.
   - Query episodic outlines from SQLite and Hopfield energy basins on demand only when associative cues are detected.
4. **FIFO Context Eviction & Summarization**:
   - Guard against context window overflow ($pos + N > 2048$).
   - When approaching 2,048 tokens, summarize the oldest dialogue block into SQLite Domain 10 and compact or reset KV cache with summary anchor.
5. **Empirical Verification & QA Clearance**:
   - Run a multi-turn interactive test (`test/geomind/test_multiturn_conversational_coherence.car` and live interactive chat).
   - Verify Turn 1, Turn 2, Turn 3 prefill latencies remain $< 1.0$s with perfect conversational recall.
   - Run full compiler regression test suite (`tools/run_affected_tests.ps1 -All`).

---

## 2. Gate Breakdown

- **Gate 1**: `src/std/transformer.cl`: Support `start_pos` in `cartan_manifold_layer_forward_batch`.
- **Gate 2**: `test/geomind/chat.cl`: Implement session position tracking (`g_chat_session_pos`), incremental turn prompt assembly, and remove automatic KV cache reset on Turn $N > 1$.
- **Gate 3**: `test/geomind/chat.cl`: Implement triggered associative recall (`geomind_chat_detect_associative_trigger`) and episodic outline summarization.
- **Gate 4**: Live multi-turn interactive verification and full 88-target compiler regression clearance.
