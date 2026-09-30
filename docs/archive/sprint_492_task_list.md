# Sprint 492 Task List

- [ ] **Task 1: Harness Integrity & Target 88 Wiring (`[ISSUE-316]`)**
  - [ ] 1.1 Update `tools/run_affected_tests.ps1`: set `$All` range to `1..88` and update TargetCatalog comment to 88 targets.
  - [ ] 1.2 Update `test/compiler_suite/run_tests.car`: append Target 88 execution block and update summary banner to 88 targets.
  - [ ] 1.3 Verify Target 88 compiles, links, and runs cleanly via `tools/run_affected_tests.ps1 -Target 88`.

- [ ] **Task 2: Dynamic Entity Grounding in SQLite Cognitive Memory (`[ISSUE-318]`)**
  - [ ] 2.1 Add `sqlite_vec_find_entity_attribute_in_prompt(db, prompt)` to `src/std/sqlite_vec.cl` and expose alias `cartan_sqlite_find_entity_attribute_in_prompt`.
  - [ ] 2.2 Refactor `geomind_chat_retrieve_factual_attractor` in `test/geomind/chat.cl` to eliminate static `"france"` / `"biology"` / `"cell"` hardcoded branches in favor of dynamic SQLite query.

- [ ] **Task 3: Multi-Turn Conversational Coherence & Session Ingestion (`[ISSUE-317]`)**
  - [ ] 3.1 Implement `sqlite_vec_prepare_session_episodes(db, session_id, limit)` in `src/std/sqlite_vec.cl` to retrieve recent session turns ordered chronologically.
  - [ ] 3.2 Update `geomind_chat_generate_reply_multimodal` in `test/geomind/chat.cl` to query recent episodes for the active session and encode them into native Gemma 4 turn delimiters ahead of the current prompt.
  - [ ] 3.3 Ensure episode retrieval excludes the current prompt (which was just logged) to prevent duplication, and bounds sequence length to 1024 tokens.

- [ ] **Task 4: Empirical Verification & Documentation**
  - [ ] 4.1 Author `test/geomind/test_multiturn_conversational_coherence.car` verifying multi-turn prompt sequence generation and persistent session continuity.
  - [ ] 4.2 Rebuild `build/geomind.exe` and synchronize `test/geomind/geomind.exe` and `bin/geomind.exe`.
  - [ ] 4.3 Run full 88-target compiler regression suite via `tools/run_affected_tests.ps1 -All`.
  - [ ] 4.4 Mark issues in `ISSUES.md` and `docs/ROADMAP.md`.
  - [ ] 4.5 Save walkthrough to `docs/archive/sprint_492_walkthrough.md` and update `CHANGELOG.md`.
