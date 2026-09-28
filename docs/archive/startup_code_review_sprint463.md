# Startup Code Review — Sprint 463
**Date**: September 28, 2026
**Investigator**: Supervisor Agent & CARTAN Squads
**Focus**: Bulk Neuro-Symbolic Corpus Ingestion & Dynamic Graph String Pool Resolution (`[ISSUE-254]`)

---

## 1. Executive Summary & Big Picture

In Sprint 462, we built `tools/ns_rule_generator.car` to automate the translation of relational triples into validated Horn clauses, flat binary `.car_graph` representations, and declarative CARTAN source code.
In Sprint 463, we execute **Option 1**: bulk ingestion of authentic ATOMIC 2020 and ConceptNet 5.8 communicative/discourse triples to scale the active expert system knowledge base.

To support arbitrary bulk rule ingestion without code bloat, we must eliminate the hardcoded `if (n_id == ...)` branches in `src/std/nses_pipeline.cl` and switch to **dynamic $O(1)$ zero-copy string resolution** from the loaded `.car_graph` string pool (`cargraph_get_rule_text(pipe.graph_file, n_id)`).

---

## 2. Logical Dependency Tree

```
┌────────────────────────────────────────────────────────┐
│     test/geomind/trainingdata/                         │
│     atomic_conceptnet_discourse.tsv                    │
│     (100+ Authentic Communicative & Pragmatic Triples) │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│               tools/ns_rule_generator.car              │
│      - Bulk Parsing & SMT/SAT Consistency Proof        │
│      - Serialization to .car_graph & Declarative Car   │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│     test/geomind/trainingdata/nses_knowledge.car_graph │
│               (Consolidated Master Graph)              │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│               src/std/nses_pipeline.cl                 │
│      - Dynamic cargraph_get_rule_text Resolution       │
│      - Zero-Allocation CSR Traversal & Prompt Priming  │
└────────────────────────────────────────────────────────┘
```

---

## 3. Findings & Technical Debt Identified

### Finding 1: Static Rule String Resolution in NSES Pipeline
- **Location**: `src/std/nses_pipeline.cl` lines 185–235
- **Defect**: The memory extraction stage in `nses_pipeline_execute_turn` maps node IDs to strings via hardcoded `if (n_id == ...)` checks. While sufficient for 52 initial rules, this is non-scalable for hundreds or thousands of ingested triples.
- **Remedy**: Query `cargraph_get_rule_text(pipe.graph_file, n_id)` directly if `pipe.graph_file.is_valid != 0.0`. Fall back to static map only if graph file is missing.

### Finding 2: Unconsolidated Active Knowledge Binary
- **Location**: `test/geomind/trainingdata/nses_knowledge.car_graph`
- **Defect**: The active knowledge base binary currently has 52 rules. Ingesting our 100+ bulk communicative triples will scale it to 100+ rules, providing rich associative priming for discourse.

---

## 4. Sprint 463 Action Plan
1. Create authentic bulk corpus `test/geomind/trainingdata/atomic_conceptnet_discourse.tsv` containing 100+ high-confidence communicative, dialogue act, and pragmatic triples (strictly zero mock).
2. Upgrade `src/std/nses_pipeline.cl` to dynamically resolve rule strings via `cargraph_get_rule_text`.
3. Ingest the bulk corpus into `test/geomind/trainingdata/nses_knowledge.car_graph` via `tools/cargraph_ingest.car` / `tools/ns_rule_generator.car`.
4. Author Target 73 (`test/compiler_suite/test_bulk_corpus_ingestion.car`) and verify 73/73 passing tests.
