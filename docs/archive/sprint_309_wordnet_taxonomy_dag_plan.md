# Implementation Plan - Sprint 309: WordNet & SlangNet Hierarchical Semantic DAG Engine, Synset-Path Resolution & Live Taxonomy Logit Biasing (Phase 67)

## 1. Problem Statement & Motivation
Prior to this sprint:
1. `test/geomind/chat.cl` computed LCA tree distance by passing raw user prompt strings to `semantics_lca_tree_distance(prompt, "entity.physical_entity.object")`. Because `prompt` is natural language without dot-path syntax, LCA distance yielded a uncalibrated fallback rather than querying actual taxonomy DAGs.
2. `semantics_load_taxonomy` was never invoked in `geomind_chat_start()`, leaving taxonomy structures dormant during interactive `--chat`.
3. `test/geomind/trainingdata/wordnet_taxonomy.txt` contained only 8 lines, lacking real ontological depth.
4. `semantics_apply_lca_boost` was never applied during autoregressive token generation, leaving token sampling unguided by semantic taxonomy alignment.

## 2. Architectural Design
- **Taxonomy DAG Ingestion (`src/cartanc/geomind_runtime.c`)**:
  - `cartan_taxonomy_load_dag(filepath)`: Ingests structured synset paths, lemmas, hypernyms, and definitions.
  - `cartan_taxonomy_resolve_path(word)`: Resolves words to their most specific dot-path in the taxonomy tree.
  - `cartan_taxonomy_get_lca_distance(word1, word2)`: Computes exact graph tree distance to Lowest Common Ancestor.
  - `cartan_taxonomy_apply_logit_boost(logits, concept_word, boost)`: Elevates logits for vocabulary tokens semantically aligned with the concept branch.
- **Standard Library (`src/std/semantics.cl`)**:
  - Update `semantics_load_taxonomy`, `semantics_resolve_concept_path`, and `semantics_apply_lca_boost` to interface with native taxonomy DAG tables.
- **GeoMind Chat Engine (`test/geomind/chat.cl`)**:
  - Auto-load taxonomy DAG on chat startup.
  - Resolve prompt keywords to synset paths during reasoning `<think>` passes.
  - Apply semantic logit boosting during autoregressive generation.
- **Verification (Target 61)**:
  - `test/compiler_suite/test_wordnet_taxonomy_dag.car` verifying indexing, resolution, LCA distance, Resnik/Lin similarity, and logit boosting (5/5 tests).

## 3. Verification Plan
- `cartanc.exe build test/compiler_suite/test_wordnet_taxonomy_dag.car -o build/test_wordnet_taxonomy_dag.exe`
- `build\test_wordnet_taxonomy_dag.exe` (Exit Code 0, 5/5 passing)
- `cartanc.exe build test/compiler_suite/run_tests.car -o build/run_tests.exe`
- Update `docs/ROADMAP.md` (Phase 67), `ISSUES.md` (`[ISSUE-060]`), `CHANGELOG.md` (`[8.266.0]`).
