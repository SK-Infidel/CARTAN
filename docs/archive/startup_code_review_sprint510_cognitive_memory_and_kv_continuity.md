# Startup Code Review: Sprint 510 - Sovereign Cognitive Memory & Multi-Turn KV Continuity

**Date**: October 1, 2026  
**Architect**: Rick (Big Daddy)  
**Lead Engineer**: Antigravity  
**Target Subsystems**: `src/std/transformer.cl`, `test/geomind/chat.cl`, `src/std/sqlite_vec.cl`, `test/geomind/main.car`

---

## 1. System Context & Logical Dependency Tree

```
┌──────────────────────────────────────────────────────────────┐
│  Interactive Chat Driver (test/geomind/main.car)             │
│  - Reads CLI interactive turns & commands (/clear, /reset)   │
└──────────────────────────────┬───────────────────────────────┘
                               │ calls geomind_chat_generate_reply_multimodal
                               ▼
┌──────────────────────────────────────────────────────────────┐
│  Cognitive Chat Engine (test/geomind/chat.cl)                │
│  - Active session position tracking: g_chat_session_pos      │
│  - Incremental prompt token formatting (Turn 1 vs Turn N)    │
│  - Triggered associative memory cues ("remember when...")    │
└──────────────┬───────────────────────────────┬───────────────┘
               │                               │
               ▼                               ▼
┌──────────────────────────────┐ ┌─────────────────────────────┐
│ Transformer Runtime          │ │ Tier 2 Cognitive Memory     │
│ (src/std/transformer.cl)     │ │ (src/std/sqlite_vec.cl)     │
│ - cartan_kv_cache_reset()    │ │ - Episodic abstract storage │
│ - cartan_manifold_layer_     │ │ - Triggered factual recall  │
│   forward_batch(start_pos)   │ │ - FIFO context eviction     │
│ - Continuous KV Arena        │ │                             │
└──────────────────────────────┘ └─────────────────────────────┘
```

---

## 2. Code Review Findings & Anti-Patterns Identified

### Finding 1: Full-History Re-Prefill Anti-Pattern (`test/geomind/chat.cl:2135-2144, 2310-2332`)
- **Diagnosis**: On every turn, `geomind_execute_manifold_sequence_prefill` explicitly calls `geomind_reset_kv_caches()`, wiping the entire 2048-token KV cache arena to position 0. Concurrently, lines 2310–2332 query SQLite for the last 4 prior episodes, concatenate them to the user's new prompt, and re-encode the entire accumulated history.
- **Impact**: Turn 1 prefills 35–55 tokens. Turn 5 prefills 400+ tokens. Because prefill is sequential over tokens, TTFT scales quadratically from 1.5s to >25-35s.
- **Remedy**: Eliminate `geomind_reset_kv_caches()` during active multi-turn sessions. Track `g_chat_session_pos`. On Turn $N > 1$, format *only* the new turn tokens and prefill incrementally into the existing KV cache starting at `g_chat_session_pos`.

### Finding 2: `cartan_manifold_layer_forward_batch` Hardcoded Position Offset (`src/std/transformer.cl:2760-2768`)
- **Diagnosis**: In `cartan_manifold_layer_forward_batch`, the token loop runs:
  ```cartan
  while (p < num_tokens) {
      cartan_manifold_layer_forward_native(h_p, h_p, layer_buf, p, num_tokens, tok_p);
      p = p + 1.0;
  }
  ```
  The position argument passed to RoPE and KV cache indexing is `p` (starting from 0.0). For incremental prefill of Turn $N$, the position must be `start_pos + p`.
- **Remedy**: Update `cartan_manifold_layer_forward_batch` to accept `start_pos: float`. Position in RoPE and KV cache becomes `start_pos + p`.

### Finding 3: Unfiltered Verbatim Episode Dumping (`test/geomind/chat.cl:2690-2693`)
- **Diagnosis**: Every assistant turn is logged verbatim to `episodes` table in SQLite (`geomind_chat_log_turn("geomind", full_gen_text)`). When episodes are long (e.g. 1500 characters), they choke subsequent prefill loops.
- **Remedy**: Store episodes only as concise semantic summaries or outline records. Only query episodic memory when explicitly triggered by associative recall cues or when active context evicts.

### Finding 4: Absence of Triggered Associative Recall Gate
- **Diagnosis**: Factual retrieval currently blindly executes on every prompt if expert priming is enabled, or tries to string-match keywords. There is no natural semantic trigger for *"Remember when..."* or *"What did you say earlier about..."*.
- **Remedy**: Implement `geomind_chat_detect_associative_trigger(prompt)`. When detected, search SQLite episodic abstracts and Continuous Hopfield basins to inject a 1-sentence grounding anchor.

---

## 3. Strict Zero-Mock Compliance
All KV cache indexing, RoPE angle rotations ($pos \times freq$), and incremental attention lookbacks must execute authentic calculations in physical memory with zero simulations or hardcoded skips.
