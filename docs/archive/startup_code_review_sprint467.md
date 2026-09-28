# Startup Code Review: Sprint 467

## Date & Session
- **Date**: 2026-09-28
- **Sprint**: 467
- **Target Feature**: Universal Cross-Domain Lexicon, Ontology & Discourse Grounding across NSES Domains 0..8
- **Active Domains**: 9 (0: SYSTEM_CORE, 1: PHYSICS_SIM, 2: TOPOLOGY_GEOMETRY, 3: COMPLEXITY_THEORY, 4: BIOLOGICAL_SYSTEMS, 5: CAUSAL_TAXONOMY, 6: LANGUAGE_DISCOURSE, 7: LOGIC_REASONING, 8: DECISION_PLANNING)

---

## 1. Code Review Findings & Architecture Gap Analysis

### 1.1 Generic Language Domain vs Specialized Ontologies
- In [`tools/cargraph_ingest.car`](file:///C:/Users/rich-/source/repos/CARTAN/tools/cargraph_ingest.car), Domain 6 (`LANGUAGE_DISCOURSE`) rules (Rules 42..51) define generic conversational pragmatics (speech act coherence, turn taking, anaphoric binding, cooperative principle).
- The specialized vocabularies and predicates of Domains 0, 1, 2, 3, 4, 5, 7, and 8 are not explicitly formalized in Domain 6. Consequently, when the model generates natural language statements about Bellman equations (Domain 8), differential forms (Domain 2), or cellular respiration (Domain 4), it lacks explicit linguistic grounding rules mapping continuous manifold representations to discrete lexical frames.

### 1.2 Disconnected CSR Linguistic Grounding Topology
- In [`src/std/nses_pipeline.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/nses_pipeline.cl), Rule 47 asserts:
  `"Lexical tokens ground continuous semantic concept embeddings into symbolic communication structures."`
- However, Rule 47 has only a single outgoing edge: `47 -> 48` (High IC discrimination). It does **not** connect outward to the foundational nodes of any other domain!
- To establish Domain 6 as the true communicative hub, Rule 47 must possess directed CSR edges to the root conceptual nodes of each cognitive domain:
  - `47 -> 0` (Energy Conservation Invariant)
  - `47 -> 6` (Kinetic Energy & Classical Mechanics)
  - `47 -> 14` (Exterior Derivative & Manifold Calculus)
  - `47 -> 21` (Polynomial Reductions & Intractability)
  - `47 -> 26` (Photosynthesis & Biological Energy)
  - `47 -> 37` (Kinematic Velocity & Motion)
  - `47 -> 54` (Modus Ponens & Deductive Inference)
  - `47 -> 62` (Bellman Optimality & Decision Planning)

### 1.3 Lack of Category Error Veto Invariants
- In [`src/std/veto_gate.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/veto_gate.cl), Rule 8 covers Language/Discourse nonsense, but there is no explicit check against cross-domain ontological category errors (e.g. attempting to calculate the "photosynthetic derivative of velocity" or asserting that "Nash equilibrium travels faster than light").
- We should formalize Rule 11 (Ontological Category Error & Discourse Agreement Veto) and register contradiction tokens `605`-`608`.

### 1.4 Need for Centralized Standard Library Module `domain_lexicon.cl`
- To provide low-entropy, zero-mock lexical and ontological tables without bloating pipeline code, we should introduce [`src/std/domain_lexicon.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/domain_lexicon.cl):
  - Canonical terminology list and Information Content (IC) ratings across all 9 domains.
  - Relational predicate ontology (`IsA`, `Causes`, `Entails`, `HasPrerequisite`, `GovernedBy`, `OptimizesFor`).
  - Structured discourse framing templates for each domain.

---

## 2. Logical Dependency Tree

```
cargraph.cl / sat_solver.cl (Core Graph & SAT Primitives)
      ▲
      │
tools/cargraph_ingest.car & tools/ns_rule_generator.car
      ▲
      │
src/std/domain_lexicon.cl (NEW: Lexicons, Predicates & Discourse Frames for Domains 0..8)
      ▲
      │
src/std/veto_gate.cl (Rule 11: Category Error Veto, Tokens 605..608)
      ▲
      │
src/std/nses_pipeline.cl (CSR Hub-and-Spoke Edges: Rule 47 -> Roots of Domains 0..8)
      ▲
      │
test/geomind/trainingdata/cross_domain_ontology.tsv & .car_graph
      ▲
      │
test/compiler_suite/test_universal_domain_lexicon.car (Target 77)
      ▲
      │
test/compiler_suite/run_tests.car (77/77 Targets)
```

---

## 3. Impact Analysis & Cascading Regression Prevention
- **CSR Builder Capacity**:
  - Dynamically scaled in Sprint 465 to $\max(\text{num\_rules} + 64, 256)$. Adding 8 hub edges to Rule 47 utilizes existing capacity without memory reallocation.
- **Backward-Compatible Graph Headers**:
  - Regression targets 71, 74, 75, 76 now use `>=` metric assertions.
- **Zero-Mock Verification**:
  - All token lookups, predicate matchings, discourse frame assemblies, and category error scans must perform genuine string, vector, and tree operations.
