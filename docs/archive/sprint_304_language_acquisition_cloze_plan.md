# Sprint 304 Implementation Plan: Phase 62 Staged Language Acquisition & Attention-Trigger Cloze Architecture

## 1. Context & Objectives
- **Target**: Complete Phase 62 (Items 1-5) from `docs/ROADMAP.md` and `docs/Research/Idea.txt`.
- **Core Components**:
  1. **High-Frequency Noun-Noun Bigrams Taxonomy (100 pairs)**: Register prioritized lexical units (`Health care`, `Ice cream`, `Web page`, etc.).
  2. **Binomial Non-Reversible Structural Pairs (100 pairs)**: Noun+Noun (41), Adj+Adj (26), Verb+Verb (20), Adverbial/Contrastive (13).
  3. **Functional Discourse Markers & Social Rituals (100 triggers)**: Politeness (15), Discourse (20), Agreement/Doubt (20), Requests (19), Emotional Reactions (26).
  4. **Narrative Progression & Structural Transition Bridges (100 bridges)**: Ingest 100 narrative transitions (`As previously mentioned`, `In contrast to`, etc.).
  5. **Full-Scale Anchored Cloze Curriculum Engine (`--train-cloze`)**: Upgrade `test/geomind/cloze_engine.cl` to stream through the 240,000+ mined cloze pairs (`mined_expanded_corpus_cloze_part01..06.jsonl`), driving bridge transition loss with real BPE tokenization and Riemannian natural gradient updates.
  6. **Regression Verification**: Target 56 (`test_language_acquisition_cloze.car`) verified via `run_tests.car` (56/56 passing).

## 2. Dependency Graph
```
docs/Research/Idea.txt
   │
   ▼
src/std/language_acquisition.cl
   │
   ├──> test/geomind/cloze_engine.cl
   │       └──> test/geomind/main.car (--train-cloze)
   │
   └──> test/compiler_suite/test_language_acquisition_cloze.car (Target 56)
           └──> test/compiler_suite/run_tests.car
```

## 3. Detailed Execution Plan
1. **`src/std/language_acquisition.cl`**:
   - Implement `lang_get_noun_pair(idx: float) -> string` (100 pairs).
   - Implement `lang_get_binomial_pair(idx: float) -> string` (100 pairs) & category identifiers.
   - Implement `lang_get_discourse_marker(idx: float) -> string` (100 phrases).
   - Implement `lang_get_transition_bridge(idx: float) -> string` (100 bridges).
   - Implement `lang_is_registered_phrase(phrase: string) -> float`.
   - Implement `lang_calculate_anchor_weight(phrase: string) -> float`.
2. **`test/geomind/cloze_engine.cl`**:
   - Integrate `src/std/language_acquisition.cl`.
   - Upgrade `geomind_cloze_eval_bridge` and `geomind_cloze_train_step` to tokenize target phrases into true SentencePiece BPE tokens (`cartan_hub_encode_text_to_tokens`), compute hidden states, and execute dynamic Riemannian natural gradient steps over all tokens in the phrase.
   - Implement `geomind_cloze_stream_curriculum` to read from JSONL dataset files, parse `sentence_cloze` and `target_phrase`, and train with adaptive anchor weighting.
3. **`test/geomind/main.car`**:
   - Ensure `--train-cloze` CLI command is wired to the curriculum pass and streaming engine.
4. **Target 56 Regression Suite**:
   - Create `test/compiler_suite/test_language_acquisition_cloze.car` verifying:
     - [1/5] Noun-Noun taxonomy retrieval and indexing.
     - [2/5] Binomial non-reversible pairs retrieval across 4 categories.
     - [3/5] Functional discourse markers and social rituals retrieval.
     - [4/5] Narrative progression and structural transition bridges retrieval.
     - [5/5] Full authentic BPE cloze tokenization, dynamic anchor weighting, and Riemannian gradient optimization.
5. **Test Runner & Verification**:
   - Update `test/compiler_suite/run_tests.car` to register Target 56 (56 total targets).
   - Build and execute test runner; verify 56/56 passing tests with exit code 0.
6. **Agile Closure**:
   - Create retro artifact and archive to `docs/archive/`.
   - Update `ISSUES.md` (close `[ISSUE-055]`).
   - Check off Phase 62 items in `docs/ROADMAP.md`.
   - Update `CHANGELOG.md`.
   - Commit changes via git.
