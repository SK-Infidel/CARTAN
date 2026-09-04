# Sprint 294 Plan: Authentic WordNet & SlangNet Semantic Taxonomy Engine

## Objective
Resolve **`[ISSUE-043]`** by replacing the hardcoded keyword match list and discarded taxonomy file in `src/std/semantics.cl` with an authentic in-memory taxonomy prefix tree, genuine Lowest Common Ancestor (LCA) tree distance calculation, and continuous Information Content (IC) metrics.

## Scope & Target Issue
- **`[ISSUE-043]` Hardcoded WordNet / SlangNet Keyword Table & Unused Taxonomy Ingest**:
  - Component: `src/std/semantics.cl:10-75`
  - Current Flaw:
    1. `semantics_lca_tree_distance` returns `abs(d1 - d2) + 2.0` instead of traversing common prefix segments.
    2. `semantics_load_taxonomy` reads the file and discards it without populating taxonomy nodes.
    3. `semantics_get_concept_ic` matches 10 hardcoded keywords and falls back to flat 1.0 for all other words.
  - Implementation:
    1. **Authentic LCA Tree Distance**: Parse dot-paths into hierarchical segments, identify the Lowest Common Ancestor (longest common prefix node), and compute the true geodesic tree distance $D_1 + D_2 - 2 \cdot L$.
    2. **Taxonomy Ingestion & Graph Building**: Parse `wordnet_taxonomy.txt` (synsets, definitions, and lemmas) into an in-memory prefix tree structure (`g_taxonomy_tree`, `g_taxonomy_nodes`).
    3. **Continuous Information Content Engine**: Dynamic IC evaluation blending taxonomy tree depth, leaf specificity, and Shannon character entropy for arbitrary concepts/prompts, preserving exact Resnik reference calibrations for domain keywords.

## Logical Dependency Tree
```
wordnet_taxonomy.txt (Taxonomy Source)
  └── semantics_load_taxonomy (src/std/semantics.cl)
        ├── semantics_lca_tree_distance
        │     ├── test_semantics_ic.car (Regression Test [42/47])
        │     └── geomind_chat_generate_reasoning_pass (test/geomind/chat.cl)
        └── semantics_get_concept_ic
              ├── test/geomind/sft_train.cl
              └── test/geomind/chat.cl
```

## Definition of Done (DoD)
- [ ] `semantics_lca_tree_distance` computes genuine lowest common ancestor tree distance across arbitrary dot paths.
- [ ] `semantics_load_taxonomy` parses definition lines and lemma synsets into in-memory taxonomy nodes.
- [ ] `semantics_get_concept_ic` evaluates genuine Information Content across arbitrary terms without falling back to a dummy constant.
- [ ] Compiler snapshot `test_semantics_ic.car` and `scratch/run_tests.exe` pass cleanly (100%).
- [ ] `build/geomind.exe` verifies clean execution.
- [ ] `ISSUES.md` and `CHANGELOG.md` updated.
- [ ] Sprint plan and retrospective archived.
