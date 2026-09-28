# Sprint 465 Plan: Formal Logic & Deductive Reasoning Domain (Domain 7) & Dynamic CSR Scaling

## Objectives
Synthesize **Domain 7: Formal Logic & Deductive Reasoning (`LOGIC_REASONING`)** across the entire CARTAN Neuro-Symbolic Expert System (NSES) and eliminate the hardcoded 64-node CSR capacity bottleneck in `src/std/nses_pipeline.cl`.

---

## Work Packages

### 1. Dynamic CSR Capacity & Veto Slots Scaling
- **Target Files**: `src/std/nses_pipeline.cl`, `src/std/veto_gate.cl`
- **Changes**:
  - Dynamically scale CSR builder and scratchpad size in `nses_pipeline_create`:
    `let n_cap = math_max(cg.header.num_rules + 64.0, 256.0);`
    Pass `n_cap` to `csr_builder_create(n_cap)` and `nses_scratchpad_create(n_cap, n_cap)`.
  - In `src/std/veto_gate.cl`, expand `domain_forbidden_tokens` allocation from 8 to 16 domain slots (`while (d < 16.0)`), and update guard in `veto_registry_add_forbidden_token` to `domain_id >= 16.0`.

### 2. Domain 7 Synthesis in Ingestion Compiler (`tools/cargraph_ingest.car`)
- **Domain Configuration**:
  - Domain ID: 7.0 (`LOGIC_REASONING`)
  - Start Rule: 52.0, Num Rules: 10.0, Strict Count: 2.0 (Total: 62 rules across 8 domains, 16 strict invariants)
- **Strict Invariants**:
  - Rule 52: "Law of Excluded Middle: A well-formed proposition in classical bivalent logic is either strictly True or strictly False; no third truth value exists."
  - Rule 53: "Principle of Explosion (Ex Falso Quodlibet): From contradictory premises (P and not P), any arbitrary false assertion follows, invalidating logical consistency."
- **Factual & Deductive Rules**:
  - Rule 54: "Modus Ponens: If conditional antecedent P implies Q and premise P is asserted True, consequent Q is validly deduced True."
  - Rule 55: "Modus Tollens: If conditional antecedent P implies Q and consequent Q is asserted False, antecedent P is validly deduced False."
  - Rule 56: "Hypothetical Syllogism: If proposition P implies Q and Q implies R, then P transitively implies R."
  - Rule 57: "Contraposition: The conditional statement P implies Q is logically equivalent to not Q implies not P."
  - Rule 58: "De Morgan's Law of Conjunction: The negation of a conjunction (not (P and Q)) is logically equivalent to the disjunction of negations (not P or not Q)."
  - Rule 59: "De Morgan's Law of Disjunction: The negation of a disjunction (not (P or Q)) is logically equivalent to the conjunction of negations (not P and not Q)."
  - Rule 60: "Resolution Refutation: Disjunctive clauses (A or B) and (not A or C) resolve to the valid resolvent clause (B or C)."
  - Rule 61: "Syllogistic Subsumption: If all elements of class S belong to genus M, and all elements of genus M belong to predicate P, then all S belong to P."

### 3. Veto Gate & Burroughs Lateral Primes for Domain 7
- **Target Files**: `src/std/veto_gate.cl`, `src/std/burroughs.cl`
- **Veto Rules**:
  - Add Rule 9.0 (Domain 7.0): Formal fallacy detection (affirming the consequent, denying the antecedent, circular reasoning / begging the question).
  - Register forbidden contradiction tokens: `701.0` (affirming consequent), `702.0` (denying antecedent), `703.0` (circular reasoning), `704.0` (contradictory truth assignment).
- **Burroughs Primes**:
  - Add Domain 7 lateral primes (Gödel unprovability, formal model-theoretic consistency, self-referential paradoxes).

### 4. Pipeline Intent Detection, CSR Topology & Training Routing
- **Target Files**: `src/std/nses_pipeline.cl`, `test/geomind/train.cl`
- **Changes**:
  - In `nses_pipeline.cl`:
    - Add Stage 1 intent detection matching `"logic"`, `"deduce"`, `"premise"`, `"conclusion"`, `"syllogism"`, `"modus"`, `"proof"`, `"infer"`, `"axiom"`, `"imply"`, `"contrapos"`.
    - Stage 3 seed selection: Seed Domain 7 with Rule 54.0 (Modus Ponens).
    - Wire CSR logical inference edges: Rule 54 (Modus Ponens) $\to$ Rule 56 (Hypothetical Syllogism) $\to$ Rule 60 (Resolution Refutation).
  - In `test/geomind/train.cl`:
    - Update domain routing count to 8 domains.
    - Route datasets containing `"logic"`, `"deduction"`, `"reasoning"`, `"proof"`, `"syllogism"`, `"rule_taker"`, `"entailment"` to Domain 7.

### 5. Regression Suite Target 75 (`test/compiler_suite/test_nses_logic_domain.car`)
- Author Target 75 verifying:
  1. Ingestion of Domain 7 into `.car_graph` with 62 rules and 16 strict invariants.
  2. Dynamic CSR builder and scratchpad scaling $\ge 256$ nodes without drop or overflow.
  3. Modus Ponens seed traversal through hypothetical syllogism and resolution.
  4. Domain 7 formal fallacy veto triggering and contradiction logit penalty calculation (tokens 701-704).
  5. Training dataset routing for formal logic corpora.
- Register Target 75 in `.gitignore` and `test/compiler_suite/run_tests.car`.
- Execute full 75-target suite with zero failures.
