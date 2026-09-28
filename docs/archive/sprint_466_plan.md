# Sprint 466 Plan: Decision Making, Planning & Game Theory (Domain 8) & Deductive-Decision Integration

## Objectives
Synthesize **Domain 8: Decision Making, Planning & Game Theory (`DECISION_PLANNING`)** across the CARTAN Neuro-Symbolic Expert System (NSES) and wire the deductive-decision bridge between Domain 7 (Formal Logic) and Domain 8 (Decision Planning).

---

## Work Packages

### 1. Ingest Domain 8 into Knowledge Base (`tools/cargraph_ingest.car`)
- **Domain Configuration**:
  - Domain ID: 8.0 (`DECISION_PLANNING`)
  - Start Rule: 62.0, Num Rules: 10.0, Strict Count: 2.0 (Total: 72 rules, 9 domains, 18 invariants)
- **Strict Invariants**:
  - Rule 62: "Bellman Optimality Principle: An optimal policy satisfies the recursive optimality equation V*(s) = max_a [R(s,a) + gamma * sum(P(s'|s,a) * V*(s'))] with discount factor gamma in [0, 1)."
  - Rule 63: "Strict Action Dominance Invariant: A rational agent cannot select a strictly dominated action if an alternative yields strictly higher expected utility across all future states."
- **Factual / Relational Rules**:
  - Rule 64: "Nash Equilibrium Stability: A strategy profile is a Nash equilibrium if no player has a profitable unilateral deviation given the strategies of all other players."
  - Rule 65: "Pareto Efficiency: A state allocation is Pareto optimal if no player payoff can be increased without strictly decreasing the payoff of at least one other player."
  - Rule 66: "Temporal Credit Assignment: State-action values update under temporal difference error: Q(s, a) = Q(s, a) + alpha * [r + gamma * max_a' Q(s', a') - Q(s, a)]."
  - Rule 67: "MCTS UCB1 Exploration Balance: Upper Confidence Bound for Trees selects actions maximizing Q(s, a) + c * sqrt(ln(N(s)) / N(s, a)) balancing exploitation against exploration."
  - Rule 68: "Markov State Property: Future state transitions depend conditionally only upon the current state and action, independent of the historical trajectory."
  - Rule 69: "Goal-Directed Backward Induction: In finite extensive-form games, backward induction from terminal payoff nodes computes the subgame-perfect equilibrium."
  - Rule 70: "Deductive Action Preconditions: An action A is executable in state S if and only if the logical preconditions Pre(A) are deductively satisfied in S."
  - Rule 71: "Heuristic Admissibility: An A* state-space search heuristic h(s) must never overestimate the true minimal cost to the goal state to guarantee optimality."
- **SMT/SAT Invariant & Implication Verification**:
  - Scale SAT solver capacity to 80 variables.
  - Assert strict axioms 62.0 and 63.0.
  - Wire logical-decision implications: 54 $\to$ 70, 70 $\to$ 62, 62 $\to$ 66, 64 $\to$ 65, 67 $\to$ 71.
  - Compile and serialize `test/geomind/trainingdata/nses_knowledge.car_graph`.

### 2. Veto Gate & Burroughs Primes Integration (`src/std/veto_gate.cl`, `src/std/burroughs.cl`)
- In `veto_gate.cl`:
  - Add Rule 10 (Domain 8): Formal decision fallacy veto (irrational preference cycles, dominated action selection, negative discount rates, inadmissible heuristics).
  - Register contradiction tokens `801.0` (dominated action), `802.0` (intransitive preference cycle), `803.0` (negative discount factor), `804.0` (inadmissible heuristic).
- In `burroughs.cl`:
  - Add Domain 8 lateral primes for game-theoretic equilibria, minimax tree search, and strategic dominance.

### 3. Pipeline Intent Routing, CSR Topology & Training Routing (`src/std/nses_pipeline.cl`, `test/geomind/train.cl`)
- In `nses_pipeline.cl`:
  - Stage 1 intent detection matching `"decision"`, `"plan"`, `"game"`, `"policy"`, `"utility"`, `"nash"`, `"pareto"`, `"bellman"`, `"action"`, `"reward"`, `"mcts"`, `"heuristic"` to Domain 8.
  - Stage 3 seed selection: Seed Rule 70.0 (Deductive Action Preconditions).
  - CSR graph edges: Rule 54 (Modus Ponens) $\to$ Rule 70 (Deductive Preconditions) $\to$ Rule 62 (Bellman Optimality) $\to$ Rule 66 (Credit Assignment); Rule 67 (MCTS) $\to$ Rule 71 (Admissible Search).
  - Backward-compatible memory fallbacks for rules 62, 66, 70.
- In `train.cl`:
  - Route planning, decision, and game datasets (`"plan"`, `"decision"`, `"policy"`, `"game"`, `"pddl"`, `"mcts"`, `"reward"`, `"trajectory"`, `"alfworld"`) to Domain 8.

### 4. Author Target 76 & Full Regression (`test/compiler_suite/test_nses_decision_domain.car`)
- Author Target 76 verifying 9 domains, 72 rules, 18 strict invariants, deductive-decision CSR traversal, decision fallacy veto, logit shaping for tokens 801-804, and planning dataset routing.
- Whitelist Target 76 in `.gitignore` and register in `test/compiler_suite/run_tests.car`.
- Execute full 76-target regression suite with zero failures.
