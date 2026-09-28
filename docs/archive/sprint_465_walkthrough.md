# Sprint 465 Walkthrough: Formal Logic & Deductive Reasoning Domain 7 & Dynamic CSR Sizing

## Executive Summary
In Sprint 465, we synthesized **Domain 7: Formal Logic & Deductive Reasoning (`LOGIC_REASONING`)** across the entire CARTAN Neuro-Symbolic Expert System (NSES) and eliminated the hardcoded 64-node CSR graph and scratchpad capacity bottleneck in `src/std/nses_pipeline.cl`.
All additions adhere strictly to the zero-mock standard, performing genuine SMT/SAT consistency proofs, real CSR topological BFS traversals, authentic formal fallacy veto scans, and analytical logit shaping.

---

## Key Deliverables & Architectural Changes

### 1. Dynamic CSR Capacity & Veto Slots Scaling (`src/std/nses_pipeline.cl`, `src/std/veto_gate.cl`)
- **Problem**:
  - `src/std/nses_pipeline.cl` previously hardcoded `csr_builder_create(64.0)` and `nses_scratchpad_create(64.0, 64.0)`. Any rule node $\ge 64$ caused silent edge drops and visited table boundary overflows.
  - `src/std/veto_gate.cl` allocated exactly 8 domain slots for `domain_forbidden_tokens`, risking out-of-bounds access as new domains were introduced.
- **Solution**:
  - Dynamically compute CSR builder and scratchpad node capacity: `math_max(cg.header.num_rules + 64.0, 256.0)`.
  - Expanded `domain_forbidden_tokens` pre-allocation to 16 domain slots and updated boundary checks to `16.0`.

### 2. Domain 7 Synthesis in Ingestion Compiler (`tools/cargraph_ingest.car`)
- Ingested Domain 7 (`LOGIC_REASONING`) with 2 strict physical/formal invariants and 8 classical deductive inference rules:
  - **Rule 52 (Strict)**: Law of Excluded Middle ($P \lor \neg P$).
  - **Rule 53 (Strict)**: Principle of Explosion / Ex Falso Quodlibet ($P \land \neg P \vdash Q$).
  - **Rule 54 (Factual)**: Modus Ponens ($P \land (P \to Q) \vdash Q$).
  - **Rule 55 (Factual)**: Modus Tollens ($\neg Q \land (P \to Q) \vdash \neg P$).
  - **Rule 56 (Factual)**: Hypothetical Syllogism / Transitivity ($(P \to Q) \land (Q \to R) \vdash (P \to R)$).
  - **Rule 57 (Factual)**: Contraposition ($P \to Q \iff \neg Q \to \neg P$).
  - **Rule 58 (Factual)**: De Morgan's Law of Conjunction ($\neg(P \land Q) \iff \neg P \lor \neg Q$).
  - **Rule 59 (Factual)**: De Morgan's Law of Disjunction ($\neg(P \lor Q) \iff \neg P \land \neg Q$).
  - **Rule 60 (Factual)**: Resolution Refutation ($(A \lor B) \land (\neg A \lor C) \vdash (B \lor C)$).
  - **Rule 61 (Factual)**: Syllogistic Subsumption (Universal affirmative class inclusion).
- Verified mathematical propositional consistency via 64-variable SMT/SAT solver.
- Successfully serialized `test/geomind/trainingdata/nses_knowledge.car_graph` (8 domains, 62 rules, 16 invariants).

### 3. Formal Fallacy Veto Gate & Contradiction Logit Suppression (`src/std/veto_gate.cl`)
- Added Rule 9 (Domain 7) formal fallacy detection catching:
  - Affirming the consequent
  - Denying the antecedent
  - Circular reasoning / petitio principii
- Registered contradiction tokens `701.0` (affirming consequent), `702.0` (denying antecedent), `703.0` (circular reasoning), and `704.0` (contradiction assertion), suppressing logits below 0.0 and generating positive analytical loss penalties during backpropagation.

### 4. Intent Routing, CSR Topology & Training Routing (`src/std/`, `test/geomind/train.cl`)
- In `nses_pipeline.cl`:
  - Stage 1 intent detection routes queries with keywords (`logic`, `deduce`, `premise`, `conclusion`, `syllogism`, `modus`, `proof`, `infer`, `axiom`, `contradict`) to Domain 7.
  - Stage 3 selects Rule 54 (Modus Ponens) as deductive seed.
  - Wired CSR deductive inference edges: Rule 54 (Modus Ponens) $\to$ Rule 56 (Hypothetical Syllogism) $\to$ Rule 60 (Resolution Refutation).
- In `burroughs.cl`:
  - Ingested Domain 7 lateral primes for Gödel incompleteness, truth lattices, and self-referential paradoxes.
- In `train.cl`:
  - Route datasets matching `"logic"`, `"deduction"`, `"reasoning"`, `"proof"`, `"syllogism"`, `"rule_taker"`, `"entailment"` to Domain 7.

### 5. Regression Suite Target 75 (`test/compiler_suite/test_nses_logic_domain.car`)
- Authored Target 75 verifying all 5 gates with 100% precision.
- Whitelisted in `.gitignore` and registered in `test/compiler_suite/run_tests.car`.

---

## Verification Results
- **Target 75 Standalone Output**:
  ```
  =====================================================================
    Target 75: NSES Formal Logic & Deductive Reasoning Domain (Domain 7)
  =====================================================================
  [PASS] Loaded knowledge graph from: test/geomind/trainingdata/nses_knowledge.car_graph
  Verifying Knowledge Base Domain 7 Structure...
    Total Domains: 8 (expected 8)
    Total Rules: 62 (expected 62)
    Strict Invariants: 16 (expected 16)
    Rule 52: Law of Excluded Middle: A well-formed proposition in classical bivalent logic is either strictly True or strictly False; no third truth value exists.
    Rule 53: Principle of Explosion (Ex Falso Quodlibet): From contradictory premises (P and not P), any arbitrary false assertion follows, invalidating logical consistency.
    Rule 54: Modus Ponens: If conditional antecedent P implies Q and premise P is asserted True, consequent Q is validly deduced True.
    Rule 56: Hypothetical Syllogism: If proposition P implies Q and Q implies R, then P transitively implies R.
  [PASS] Domain 7 knowledge rules verified.

  Verifying Dynamic CSR Capacity & Scratchpad Scaling...
    CSR Graph Capacity: 256 nodes (expected >= 256.0)
    Scratchpad Capacity: 256 nodes (expected >= 256.0)
  [PASS] Dynamic CSR node capacity successfully scaled.

  Verifying Stage 1 Intent Routing & Deductive Traversal for Domain 7...
    Query: Given premise P implies Q, if P is true, what can we deduce from modus ponens and hypothetical syllogism?
    Active Domain: 7 (expected 7.0)
    Traversed Rules Count: 3
    Memory Tree Size: 3
      Traversed Rule [0]: Modus Ponens: If conditional antecedent P implies Q and premise P is asserted True, consequent Q is validly deduced True.
      Traversed Rule [1]: Hypothetical Syllogism: If proposition P implies Q and Q implies R, then P transitively implies R.
      Traversed Rule [2]: Resolution Refutation: Disjunctive clauses (A or B) and (not A or C) resolve to the valid resolvent clause (B or C).
  [PASS] Stage 1 routing and CSR deductive seed traversal verified.

  Verifying Domain 7 Fallacy Veto & Logit Suppression...
    Candidate Text: 'In our deduction, affirming the consequent is valid and leads to a sound conclusion.'
    Vetoed: 1 (expected 1.0)
    Violated Rule ID: 9 (expected 9.0)
    Canonical Assertion: In accordance with classical deductive logic, valid inferences must preserve truth, contradictions cannot both be true, and affirming the consequent or denying the antecedent are invalid formal fallacies.
    Domain 7 Symbolic Penalty: 0.0171
    Logit 701 (Affirming Consequent): -1.00 (expected <= 0.0)
    Logit 702 (Denying Antecedent): -1.00 (expected <= 0.0)
    Logit 703 (Circular Reasoning): -1.00 (expected <= 0.0)
    Logit 704 (Contradiction Assertion): -1.00 (expected <= 0.0)
    Logit 500 (Neutral Token): 2.00 (expected 2.0)
  [PASS] Domain 7 formal fallacy veto and logit shaping verified.

  Verifying Training Dataset Routing for Domain 7...
    Dataset 'trainingdata/proofwriter_deductive_rules.tsv' routed to domain: 7 (expected 7.0)
    Dataset 'trainingdata/entailment_bank_trees.txt' routed to domain: 7 (expected 7.0)
    Dataset 'trainingdata/corpus_dialogue_turns.txt' routed to domain: 6 (expected 6.0)
  [PASS] Training dataset routing verified for Domain 7.

  =====================================================================
  [PASS] Target 75: NSES Formal Logic & Deductive Reasoning Verified Cleanly.
  =====================================================================
  ```
- **Full Compiler Regression Suite**: 75/75 targets executed successfully (0 failures).
