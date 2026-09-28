# Sprint 467 Implementation Plan: Universal Cross-Domain Lexicon, Ontology & Discourse Grounding

## 1. Objectives & Scope
- **Sprint**: 467
- **Mission**: Upgrade Domain 6 (`LANGUAGE_DISCOURSE`) into the central communicative, lexical, and ontological bridge for all 9 cognitive domains (`SYSTEM_CORE`, `PHYSICS_SIM`, `TOPOLOGY_GEOMETRY`, `COMPLEXITY_THEORY`, `BIOLOGICAL_SYSTEMS`, `CAUSAL_TAXONOMY`, `LANGUAGE_DISCOURSE`, `LOGIC_REASONING`, `DECISION_PLANNING`).
- **Zero-Mock Directive**: All lexical lookups, Information Content (IC) weight calculations, discourse frame formatters, category validations, and graph traversals must perform genuine string, vector, and tree calculations.

---

## 2. Technical Architecture

### 2.1 Standard Library Module: `src/std/domain_lexicon.cl`
- **Data Structures**:
  - `DomainLexiconEntry`: `term: string`, `domain_id: float`, `ic_weight: float`, `category_type: string`.
  - `DomainLexicon`: container storing tree of entries, domain index mappings, and canonical discourse frames.
- **Key Functions**:
  - `domain_lexicon_create() -> DomainLexicon`
  - `domain_lexicon_add_term(lex, term, domain_id, ic_weight, cat_type)`
  - `domain_lexicon_populate_defaults(lex)`: populates 45+ authentic domain-specific terms across all 9 domains with genuine IC weights (e.g. `energy`, `entropy`, `hamiltonian`, `differential`, `manifold`, `p_np`, `turing`, `atp`, `metabolism`, `velocity`, `modus_ponens`, `bellman`, `nash_equilibrium`).
  - `domain_lexicon_lookup_ic(lex, word) -> float`: calculates Information Content weight for token prioritization.
  - `domain_lexicon_get_discourse_frame(lex, domain_id) -> string`: returns the formal grammatical discourse frame for that domain.
  - `domain_lexicon_validate_predicate_category(lex, subj_domain, predicate, obj_domain) -> float`: validates cross-domain ontological consistency.
  - `domain_lexicon_free(lex)`

### 2.2 Hub-and-Spoke CSR Linguistic Grounding Topology (`src/std/nses_pipeline.cl`)
- Rule 47 (*"Lexical tokens ground continuous semantic concept embeddings into symbolic communication structures."*) is wired to root nodes of all domains:
  - `47.0 -> 0.0` (System Core: Conservation Invariant)
  - `47.0 -> 6.0` (Physics: Kinetic Energy)
  - `47.0 -> 14.0` (Topology: Exterior Derivative)
  - `47.0 -> 21.0` (Complexity: Polynomial Reduction)
  - `47.0 -> 26.0` (Biology: Photosynthesis)
  - `47.0 -> 37.0` (Causality: Kinematic Velocity)
  - `47.0 -> 54.0` (Logic: Modus Ponens)
  - `47.0 -> 62.0` (Planning: Bellman Optimality)
- When a language/discourse query is processed, traversing from Rule 47 exposes the semantic vocabulary of all domain models.

### 2.3 Cross-Domain Ontological Triple Corpus (`cross_domain_ontology.tsv`)
- Authentic dataset connecting entities and predicates across all 9 domains:
  - Format: `Head \t Relation \t Tail \t Confidence \t IsStrict`
  - Uses canonical relations: `IsA`, `Causes`, `HasPrerequisite`, `Entails`, `GovernedBy`, `OptimizesFor`.
  - Ingested via `tools/ns_rule_generator.car` and compiled into `cross_domain_ontology.car_graph`.

### 2.4 Rule 11: Ontological Category Error & Discourse Veto (`src/std/veto_gate.cl`)
- Scans candidate outputs for cross-domain category errors (e.g. applying biological metabolism to geometric differential forms, claiming logical rules have physical velocity).
- Registers contradiction tokens `605.0` (Category Mismatch), `606.0` (Ungrounded Predicate), `607.0` (Discourse Frame Rupture), `608.0` (Type Violation) for Domain 6.

### 2.5 Regression Target 77 (`test/compiler_suite/test_universal_domain_lexicon.car`)
- Verifies:
  1. Lexicon registration and authentic IC calculations across all 9 domains.
  2. Canonical discourse frame retrieval for all domains.
  3. Ontological category error validation.
  4. Hub-and-spoke CSR traversal from Rule 47 to all domain roots.
  5. Rule 11 category error veto and tokens 605-608 logit suppression.
  6. Zero-mock compliance across all 77 regression targets.
