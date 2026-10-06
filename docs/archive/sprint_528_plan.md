# Sprint 528 Plan: Rolling FIFO Context Eviction & English Vocabulary Expansion

**Sprint**: 528  
**Mission**: Resolve `[ISSUE-386]` by implementing rolling FIFO context window eviction and uncapping the full 167k English/Latin vocabulary for conversational inference.  

---

## 1. Architectural Objectives
1. **Uncap English/Latin Vocabulary**:
   - In [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl), replace the restrictive 2.5k stream mask and 21k TinyStories mask with the authentic 167,243 Universal + Latin token mask (`geomind_get_language_mask_for_script(1.0)`).
   - Preserve stream-gated logit biasing (`geomind_apply_stream_gated_logit_bias`) for domain alignment while allowing the full expressive vocabulary of Gemma-4.
2. **Rolling FIFO Context Eviction**:
   - In [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl) and [`src/std/transformer.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/transformer.cl), implement a rolling KV cache manager.
   - Pin the initial system instruction and cognitive preamble (tokens $0 \dots N_{\text{preamble}}$).
   - Once total session length exceeds a rolling budget (default 1,024 tokens), slide out the oldest intermediate turn KV entries (`memmove` on KV arenas across all 24 active layers), keeping `g_chat_session_pos` bounded.
   - Maintain constant $8 - 10\text{ tok/s}$ CPU decode speed indefinitely, preventing linear slowdown.
3. **Robust Interlocutor Extraction**:
   - In `geomind_chat_learn_conversational_turn` in `chat.cl`, add sanity validation to `"i am "` pattern extraction to prevent sentences like `"Only I am authorized to receive..."` from creating synthetic usernames.

---

## 2. Definition of Done (DoD)
- [ ] Vocabulary mask loads full 167,243 Universal + Latin tokens from `geomind_vocab_scripts.bin`.
- [ ] Rolling FIFO context eviction slides KV cache forward without memory leaks or attention corruption.
- [ ] Interlocutor extraction ignores multi-word verb/adjective predicates.
- [ ] Multi-turn dialogue throughput stays $\ge 7.0\text{ tok/s}$ across 10+ turns.
- [ ] Zero foreign grammar anomalies or token salads in extended dialogues.
- [ ] Full regression suite passes via `tools/run_affected_tests.ps1 -Sprint 528`.
- [ ] `ISSUES.md`, `CHANGELOG.md`, `ROADMAP.md` updated, and artifacts archived.
