# Sprint 408 Task List: Deterministic Symbolic Subsystem & SMT/SAT Verifier (NSES Sprint 2)

- [x] **Task 1: SMT/SAT Propositional Verifier (`src/std/sat_solver.cl`)**
  - [x] Implement `SatSolver` struct with implication graph adjacency lists.
  - [x] Implement literal mappings ($2v$ positive, $2v+1$ negated) and clause operators (`sat_add_implication`, `sat_add_contradiction`, `sat_set_axiom`).
  - [x] Implement Tarjan/Kosaraju SCC & reachability contradiction detector (`sat_solve_consistency`).
  - [x] Implement graph validation gate `cargraph_verify_axiomatic_consistency` rejecting conflicting topologies.

- [x] **Task 2: Deterministic Guardrails Engine (`src/std/guardrails.cl`)**
  - [x] Implement `GuardrailSlice` struct and `guardrails_get_strict_slice(cg)` extracting slice `[0 .. num_strict_rules - 1]` with zero ANN computation.
  - [x] Implement domain-aware router `guardrails_route_query(cg, query_emb, top_k)` with unconditional `active_domain_ids = [0] + top_k`.
  - [x] Implement rule extraction and domain filtering with strict orthogonal cross-domain isolation.
  - [x] Implement prompt boundary formatter `guardrails_format_inviolable_bounds(cg)`.

- [x] **Task 3: Empirical QA Test Suite (`test/geomind/nses/test_sprint2_guardrails_sat.car`)**
  - [x] `TS-2.1`: Build graph with 10 Domain 0 strict invariants + 500 facts in Domains 1 & 2. Run 100 adversarial queries; verify 100.0% Domain 0 retention.
  - [x] `TS-2.2`: Inject direct and transitive logical contradictions; verify SAT verifier detects conflict and prevents graph build.
  - [x] `TS-2.3`: Verify complete cross-domain isolation between Domain 1 (e.g. Physics) and Domain 2 (e.g. Fantasy Fiction).
  - [x] Verify execution time under 0.8 ms budget (Achieved: 0.04 ms).

- [x] **Task 4: Compilation, Verification & Agile Closure**
  - [x] Compile test harness with `cartanc.exe build ... -o build/test_sprint2_guardrails_sat.exe`.
  - [x] Execute binary and assert exit code 0.
  - [x] Save walkthrough to `docs/archive/sprint_408_walkthrough.md` and UI artifact.
  - [x] Update `NSES_IMPLEMENTATION_PLAN.md` and `NSES.md` with Sprint 2 completion status.
  - [x] Update `CHANGELOG.md` with release `[8.366.0]`.
