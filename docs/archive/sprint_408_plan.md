# Sprint 408 Plan: Deterministic Symbolic Subsystem & SMT/SAT Verifier (NSES Sprint 2)

## 1. Context & Objectives
- **Subsystem**: Neuro-Symbolic Expert System (NSES) Phase 2.
- **Goal**: Implement deterministic symbolic guardrails and build-time axiomatic consistency verification.
- **Key Invariants**:
  1. **Domain 0 (`SYSTEM_CORE`) Immunity**: Always unconditionally routed on every query turn: `active_domain_ids = [0] + top_k(query_vec)`.
  2. **Complete ANN Bypass**: Strict invariants packed contiguously in slice `[0 .. num_strict_rules - 1]` with direct indexing ($\mathcal{O}(1)$), never susceptible to semantic eviction.
  3. **Build-Time 2-SAT / Horn Clause Verifier**: Detect direct contradictions ($A \land \neg A$) and circular implication conflicts ($A \implies B \implies \neg A$) to block malformed `.car_graph` compilation before serialization.
  4. **Strict Isolation**: Zero cross-domain leakage across orthogonal workspaces. All tracking remains strictly inside `NSES_IMPLEMENTATION_PLAN.md` and `NSES.md` (no items in `ISSUES.md`).

---

## 2. Architecture & File Manifest

### A. [`src/std/sat_solver.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/sat_solver.cl)
- Propositional 2-SAT implication graph verifier (Aspvall-Plass-Tarjan linear-time SCC).
- Literals: variable $v$ mapped to $2v$ (positive literal) and $2v + 1$ (negated literal).
- Clause support:
  - Implication: $A \implies B \equiv (\neg A \lor B)$.
  - Conflict / Contradiction: $A \implies \neg B \equiv (\neg A \lor \neg B)$.
  - Axiom / Unit assertion: $A = \top \equiv (A \lor A)$.
- SCC / Cycle detection: Identifies if any literal $x$ and $\neg x$ reside in the same strongly connected component.
- Unit propagation verifier: Flags contradictory reachability from active axioms.

### B. [`src/std/guardrails.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/guardrails.cl)
- `Domain 0` partition management and enforcement.
- Contiguous strict slice retrieval `guardrails_get_strict_slice(cg)`.
- Multi-domain router `guardrails_route_query(cg, query_emb, top_k)` enforcing `[0] + Top-K`.
- Rule extraction filtering ensuring zero cross-domain leakage across orthogonal domains.
- Prompt bounds generator formatting `[SYSTEM BOUNDS - INVIOLABLE]`.

### C. [`test/geomind/nses/test_sprint2_guardrails_sat.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/nses/test_sprint2_guardrails_sat.car)
- **`TS-2.1`**: 10 strict physical invariants in Domain 0 + 500 facts across 2 non-physics domains. 100 adversarial queries routed away from physics; assert 100.0% Domain 0 retention.
- **`TS-2.2`**: Intentional logical contradiction injection; assert SAT solver detects conflict and aborts compilation.
- **`TS-2.3`**: Cross-domain isolation test; assert zero leakage between orthogonal non-Domain-0 partitions.
- **Performance Gate**: Deterministic slice extraction $\le 0.8\text{ ms}$.

---

## 3. Definition of Done (DoD)
- [ ] Code passes static type checking and LLVM IR codegen via `cartanc.exe`.
- [ ] Zero runtime regressions.
- [ ] Empirical verification tests (`TS-2.1`, `TS-2.2`, `TS-2.3`) pass with exit code 0.
- [ ] Implementation plan, task list, and walkthrough saved in `docs/archive/`.
- [ ] `CHANGELOG.md` updated with release `[8.366.0]`.
- [ ] `NSES_IMPLEMENTATION_PLAN.md` and `NSES.md` updated with Sprint 2 completion status.
