# Startup Code Review - Sprint 466: Decision Making, Planning & Game Theory (Domain 8) & Deductive-Decision Integration

## 1. Context & Objectives
Following the successful synthesis of Domain 7 (Formal Logic & Deductive Reasoning), Rick confirmed prioritizing **Decision Making, Planning & Game Theory (`DECISION_PLANNING`, Domain 8)** along with integrating it with formal logic.
In this review, we examine the logical prerequisites, map the dependency structure, define the mathematical invariants, and eliminate any remaining impedance mismatches between logical deduction and goal-directed decision planning.

---

## 2. Findings & Architectural Analysis

### Gap 1: Absence of Goal-Directed Decision & Planning Primitives in NSES
- **Current State**: The knowledge base contains 8 domains (0 through 7: System Core, Physics, Topology, Complexity, Biology, Causal Taxonomy, Language Discourse, Logic Reasoning).
- **Impact**: While the system can deduce facts via Modus Ponens or verify invariant constraints, it lacks formal representations of sequential decision theory (MDPs, Bellman recursion), equilibrium stability (Nash, Pareto), exploration/exploitation bounds (MCTS UCB1), and heuristic admissibility (A* search).
- **Remedy**: Ingest Domain 8 (`DECISION_PLANNING`) with 2 strict invariants and 8 relational rules.

### Gap 2: Missing Deductive-Decision Bridge
- **Current State**: Domain 7 (`LOGIC_REASONING`) and action execution are decoupled.
- **Architectural Link**: In classical planning and reasoning systems (PDDL, STRIPS, Situation Calculus), an action $A$ is permissible if and only if its preconditions $Pre(A)$ are deductively entailed by the current world state ($S \vdash Pre(A)$). Once satisfied, executing $A$ yields expected utility according to Bellman equations.
- **Remedy**:
  - Add Rule 70: "Deductive Action Preconditions: An action A is executable in state S if and only if the logical preconditions Pre(A) are deductively satisfied in S."
  - Wire CSR graph dependency: Rule 54 (Modus Ponens) $\to$ Rule 70 (Deductive Action Preconditions) $\to$ Rule 62 (Bellman Optimality).

### Gap 3: Decision Fallacy Veto & Contradiction Logit Suppression
- **Impact**: Unsound actions such as choosing strictly dominated alternatives or asserting intransitive preference loops ($A \succ B \succ C \succ A$) can corrupt policy evaluation during training.
- **Remedy**:
  - Add Rule 10 in `veto_gate.cl` catching decision fallacies.
  - Register contradiction tokens `801.0` through `804.0`.

---

## 3. Logical Dependency Tree

```
  src/std/sat_solver.cl (SMT/SAT Consistency Checking across 72 Variables)
       │
       ▼
  src/std/cargraph.cl (CarGraph SoA Binary Serialization, 9 Domains, 72 Rules)
       │
       ├─────────────────────────────────┐
       ▼                                 ▼
  src/std/guardrails.cl             src/std/csr_graph.cl
  (Strict Invariant Slices &        (256+ Dynamic Node Capacity &
   Domain Routing)                   Deductive-Decision BFS Topology)
       │                                 │
       ├─────────────────┬───────────────┤
       ▼                 ▼               ▼
  src/std/veto_gate.cl   src/std/burroughs.cl   src/std/prompt_scaffold.cl
  (Decision Fallacy Veto  (Game/Planning          (Scaffold Assembly &
   & Logits 801-804)      Lateral Primes)          Goal Conditioning)
       │                 │               │
       └─────────────────┼───────────────┘
                         ▼
             src/std/nses_pipeline.cl
             (Stage 1 Planning Intent Routing,
              Deductive Seed Traversal: Rule 54 -> 70 -> 62)
                         │
         ┌───────────────┴───────────────┐
         ▼                               ▼
    test/geomind/chat.cl             test/geomind/train.cl
    (Interactive Goal Planning)      (Domain 8 Planning Dataset Routing)
         │                               │
         └───────────────┬───────────────┘
                         ▼
             test/compiler_suite/run_tests.car
             (Target 76: test_nses_decision_domain.car)
```

---

## 4. Empirical Verification Standards (Zero-Mock Rule)
1. Ingestion of Domain 8 into `nses_knowledge.car_graph` yielding exactly 9 domains, 72 rules, and 18 strict invariants.
2. 72-variable SMT/SAT consistency proof with zero conflicts or cycles.
3. CSR traversal tracing the deductive-decision bridge: Modus Ponens (Rule 54) $\to$ Deductive Preconditions (Rule 70) $\to$ Bellman Optimality (Rule 62).
4. Veto gate detection of strictly dominated action selection and preference cycles, suppressing tokens 801-804.
5. All 76 regression test targets passing cleanly with exit code 0.
