# Sprint 477 Task List: Objective Lexical Selection, NSES Knowledge Priming & REPL Stability

- [ ] **Task 1: Eliminate Artificial Token Boosts and Manual Suppressions** <!-- id: 0 -->
  - [ ] Remove `cur_mit + 2.5` override in `test/geomind/chat.cl`.
  - [ ] Remove all hardcoded token ID suppressions in `cartan_apply_repetition_penalty`.
  - [ ] Implement authentic Zipfian function-word suppression based on `g_e8_ics`.

- [ ] **Task 2: Full English Vocabulary Restoration & Named Entity Ingestion** <!-- id: 1 -->
  - [ ] Audit `geomind_vocab_mask.bin` and ensure all English dictionary words, proper nouns, and entity variants (`Paris`, `France`, etc.) are active.
  - [ ] Verify that LM head projection accurately evaluates candidates without omitting valid lexical items.

- [ ] **Task 3: Productive NSES & Cognitive Memory Priming** <!-- id: 2 -->
  - [ ] Wire NSES entity facts from SQLite `cognitive_memory.db` into active prompt context.
  - [ ] Query CarGraph domain centroids/rule embeddings and blend them continuously into the prompt hidden state prior to transformer execution.

- [ ] **Task 4: Interactive REPL Stabilization & Memory Safety** <!-- id: 3 -->
  - [ ] Enforce conversational token limits (default 24 tokens) and early stopping on EOS / punctuation.
  - [ ] Fix vector memory leaks in the generation loop (`cur_h`, `layer_h`, `mom`).
  - [ ] Maintain conversational context across interactive REPL turns.

- [ ] **Task 5: Empirical Verification & Regression Testing** <!-- id: 4 -->
  - [ ] Rebuild `build/geomind.exe` with `cartanc.exe`.
  - [ ] Test generation on `"In biology, cells divide through"` and `"The capital of france is,"`.
  - [ ] Run multi-turn interactive session test.
  - [ ] Execute full compiler test suite via `build/run_tests.exe` (all 86 targets pass).

- [ ] **Task 6: Sprint Closeout & Documentation** <!-- id: 5 -->
  - [ ] Update `CHANGELOG.md` with version `[8.435.0]`.
  - [ ] Update `ISSUES.md` closing `[ISSUE-275]`, `[ISSUE-276]`, `[ISSUE-277]`, `[ISSUE-278]`.
  - [ ] Author `docs/archive/sprint_477_walkthrough.md`.
