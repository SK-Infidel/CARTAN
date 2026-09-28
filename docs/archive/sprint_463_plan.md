# Sprint 463 Plan: Bulk Neuro-Symbolic Corpus Ingestion & Dynamic Graph String Pool Resolution

## Sprint Objective
Resolve `[ISSUE-254]` by creating an authentic bulk corpus of 100+ communicative, dialogue-act, and pragmatic relational triples (`test/geomind/trainingdata/atomic_conceptnet_discourse.tsv`), upgrading `src/std/nses_pipeline.cl` to dynamically resolve memory node text directly from the `.car_graph` string pool (`cargraph_get_rule_text`), consolidating the master knowledge base binary, and empirically verifying with Target 73 across the full 73-target regression suite.

---

## Technical Specifications

### Phase 1: Authentic Bulk Discourse Corpus
Create `test/geomind/trainingdata/atomic_conceptnet_discourse.tsv` containing 100+ high-confidence triples across:
- **Speech Acts**: Greeting, inquiry, statement, directive, clarification, confirmation, apology, farewell.
- **ATOMIC 2020 Causal Primitives**: `xIntent`, `xNeed`, `xEffect`, `xReact`.
- **ConceptNet 5.8 Relations**: `HasPrerequisite`, `Causes`, `CapableOf`, `MustAgree`, `BoundedBy`, `IsA`.
- Strictly genuine relationships adhering to our zero-mock rule.

### Phase 2: Dynamic String Pool Resolution in `src/std/nses_pipeline.cl`
In `nses_pipeline_execute_turn` (Stage 4):
```cartan
cartan_tree_clear(pipe.memory_tree);
var m_idx = 0.0;
while (m_idx < traversed_cnt) {
    let n_id = collections_list_get(pipe.scratchpad.result_node_ids, m_idx);
    var resolved_text = "";
    if (pipe.graph_file.is_valid != 0.0 && n_id < pipe.graph_file.header.num_rules) {
        resolved_text = cargraph_get_rule_text(pipe.graph_file, n_id);
    }
    if (cartan_string_length(resolved_text) > 0.0) {
        cartan_tree_push(pipe.memory_tree, resolved_text);
    }
    m_idx = m_idx + 1.0;
}
```
This guarantees $O(1)$ zero-copy retrieval for arbitrary hundreds or thousands of rules directly from binary memory without branching.

### Phase 3: Master Knowledge Graph Consolidation
Ingest the bulk discourse corpus into `test/geomind/trainingdata/nses_knowledge.car_graph`, scaling total rules past 100 rules, and proving SMT/SAT consistency.

### Phase 4: Target 73 Regression Testing & Verification
1. Author Target 73 (`test/compiler_suite/test_bulk_corpus_ingestion.car`):
   - Ingest bulk corpus via `ns_process_triples_buffer`.
   - Verify dynamic node string resolution via `cargraph_get_rule_text`.
   - Verify SMT/SAT consistency.
   - Verify prompt scaffold assembly incorporates dynamically retrieved bulk rules.
2. Whitelist Target 73 in `.gitignore` and register in `test/compiler_suite/run_tests.car`.
3. Rebuild `build/run_tests.exe` and execute all 73 targets (73/73 passing).
4. Update `ISSUES.md` (`[ISSUE-254]` -> `[FIXED]`), `CHANGELOG.md` (`[8.421.0]`), `docs/ROADMAP.md`, and save `docs/archive/sprint_463_walkthrough.md`.
