# Sprint 528 Task List: Rolling FIFO Context Eviction & English Vocabulary Expansion

- [x] **1. Vocabulary: Uncap 167k English/Latin Tokens (`test/geomind/chat.cl`)**
  - [x] Update `geomind_get_stream_pruned_vocab_mask` and LM head dispatch to use `geomind_get_language_mask_for_script(1.0)` by default.
  - [x] Make stream-domain vocabulary pruning an explicit opt-in diagnostic flag (`-stream-prune`), preserving full 167,243 Universal + Latin tokens for standard inference.
  - [x] Verify authentic vocabulary loading on startup.

- [x] **2. Runtime: Rolling FIFO Context Eviction Engine (`test/geomind/chat.cl`)**
  - [x] Implement dynamic context boundary `g_rolling_context_threshold` (1024.0 tokens default).
  - [x] Trigger rolling context refresh when `g_chat_session_pos >= g_rolling_context_threshold`: flushes KV caches across all 24 layers (`geomind_reset_kv_caches()`), re-injects system cognitive preamble, immediately preceding dialogue turn (`g_last_user_prompt` + `g_last_model_reply`), and current prompt.
  - [x] Bound causal attention ops $< 500\text{k}$, eliminating single-threaded $O(N)$ CPU attention bottleneck and sustaining steady decode speed indefinitely.
  - [x] Implement threshold getters/setters `geomind_chat_get_rolling_threshold` and `geomind_chat_set_rolling_threshold`.

- [x] **3. Quality: Heuristic Pattern Extraction Guard (`test/geomind/chat.cl`)**
  - [x] Add sanity check to `geomind_chat_learn_conversational_turn`: require name length $< 20$, reject common verbs/predicates ("authorized", "wondering", "ready", "sure", "not", "just", "going", "the", "a", "an", "sorry", "here", "trying", "asking", "looking", "curious", "aware").

- [x] **4. Build, Benchmarks & Regression Suite**
  - [x] Rebuild `bin/geomind.exe` with `cartanc.exe`.
  - [x] Run prompt benchmarks: verify authentic 167,243 token mask loading, instant interlocutor recognition (`User:Rick`), and fluent natural English generation.
  - [x] Add Sprint 528 preset to `tools/run_affected_tests.ps1` and run compiler regression suite (**16/16 PASS** in 104.57s).

- [x] **5. Review, Documentation & Closure**
  - [x] Mark `[ISSUE-386]` as resolved in `ISSUES.md`.
  - [x] Update `CHANGELOG.md` to `[8.484.0]`.
  - [x] Update Phase 25 in `docs/ROADMAP.md`.
  - [x] Save walkthrough to `docs/archive/sprint_528_walkthrough.md`.
