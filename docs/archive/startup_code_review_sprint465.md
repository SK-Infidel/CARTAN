# Startup Code Review - Sprint 465: Formal Logic & Deductive Reasoning Domain (Domain 7) & Dynamic CSR Sizing

## 1. Context & Objectives
Following the successful completion of Sprint 464 (Chat & Training NSES Forward Pass & Loss Integration), the next critical cognitive capability requested by Rick is formal logic and reasoning ("Language, logic, decision making, Science, etc.").
In this startup code review, we inspect the entire Neuro-Symbolic Expert System pipeline, identify architectural scalability bottlenecks, map out the dependency tree, and formulate the plan for Domain 7: Formal Logic & Deductive Reasoning (`LOGIC_REASONING`).

---

## 2. Findings & Discovered Technical Debt

### Issue 1: Hardcoded 64-Node CSR Capacity Bottleneck (`src/std/nses_pipeline.cl:66, 84`)
- **Location**: `src/std/nses_pipeline.cl`, lines 66 and 84:
  ```cartan
  let b = csr_builder_create(64.0);
  ...
  let pad = nses_scratchpad_create(64.0, 64.0);
  ```
- **Vulnerability**:
  - `csr_builder_add_edge` strictly drops any edge where `src >= b.num_nodes || dst >= b.num_nodes`.
  - When `cg.header.num_rules > 64` (e.g. `atomic_discourse.car_graph` with 110 rules, or after adding Domain 7 rules), edges connecting nodes $\ge 64$ are silently discarded.
  - In `csr_traverse_bfs`, the scratchpad visited table `v_epoch` only contains 64 entries. Any seed or target $\ge 64$ either fails or accesses unallocated elements.
- **Remedy**: Sizing must be dynamically computed based on loaded graph rules: `let n_cap = math_max(cg.header.num_rules + 64.0, 256.0);` for both `csr_builder_create` and `nses_scratchpad_create`.

### Issue 2: Fixed 8-Domain Limit in Veto Registry Token Lists (`src/std/veto_gate.cl:62-67`)
- **Location**: `src/std/veto_gate.cl`:
  ```cartan
  while (d < 8.0) { ... }
  ```
- **Vulnerability**: While 8 slots accommodate domains 0..7, adding Domain 7 saturates the last available index. Any subsequent domains (Domain 8: Decision Making, Domain 9: Formal Science) would immediately cause an out-of-bounds error.
- **Remedy**: Expand pre-allocated domain token capacity to 16 domains (`while (d < 16.0)`), and update guard in `veto_registry_add_forbidden_token` to `domain_id >= 16.0`.

### Issue 3: Missing Cognitive Domain 7: Formal Logic & Deductive Reasoning
- **Gap**: The NSES knowledge base currently contains 7 domains (Domains 0-6). Deductive queries (syllogisms, propositional logic, resolution, Modus Ponens/Tollens, De Morgan's laws) fall back to default physical simulation rules rather than formal logic reasoning structures.
- **Remedy**:
  - Ingest Domain 7 (`LOGIC_REASONING`) with 2 strict invariants and 8 factual/causal rules.
  - Implement Domain 7 fallacy veto rules and contradiction tokens (`701`-`704`).
  - Wire Domain 7 Stage 1 intent detection, seed selection, and training dataset routing.

---

## 3. Logical Dependency Tree

```
  src/std/sat_solver.cl (2-SAT Propositional & Horn-Clause Verification)
       │
       ▼
  src/std/cargraph.cl (CarGraph Flat Binary & Invariant Validation)
       │
       ├─────────────────────────────────┐
       ▼                                 ▼
  src/std/guardrails.cl             src/std/csr_graph.cl
  (Strict Invariant Slices &        (Dynamic Capacity CSR &
   Domain Routing)                   Zero-Allocation BFS Scratchpad)
       │                                 │
       ├─────────────────┬───────────────┤
       ▼                 ▼               ▼
  src/std/veto_gate.cl   src/std/burroughs.cl   src/std/prompt_scaffold.cl
  (Formal Logic Fallacy   (Lateral Primes &       (Scaffold Assembly &
   Veto & Logit Penalty)  Cognitive Diversity)     Delimited Context)
       │                 │               │
       └─────────────────┼───────────────┘
                         ▼
             src/std/nses_pipeline.cl
             (Dynamic CSR Sizing, Stage 1 Intent Routing,
              Deductive Seed Selection & Turn Execution)
                         │
         ┌───────────────┴───────────────┐
         ▼                               ▼
    test/geomind/chat.cl             test/geomind/train.cl
    (Chat Deductive Reasoning)       (Domain 7 Dataset Routing)
         │                               │
         └───────────────┬───────────────┘
                         ▼
             test/compiler_suite/run_tests.car
             (Target 75: test_nses_logic_domain.car)
```

---

## 4. Empirical Verification Standards (Zero-Mock Rule)
1. Dynamic CSR builder & scratchpad capacity $\ge 256$ must be empirically exercised with node indices $> 64$.
2. All 10 Domain 7 rules (2 strict invariants, 8 relational rules) must be ingested with verified non-zero norms and serialized cleanly.
3. Propositional SAT solver must verify formal logical consistency with zero unsatisfiable axioms.
4. Veto gate must detect and suppress formal fallacies (affirming consequent, denying antecedent, circular reasoning) and penalize contradiction tokens `701`-`704`.
5. Full regression test suite (75 targets) must pass cleanly with 0 failures.
