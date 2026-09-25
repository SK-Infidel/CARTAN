# Sprint 408 Walkthrough: Deterministic Symbolic Subsystem & SMT/SAT Verifier (NSES Sprint 2)

## 1. Executive Summary
- **Sprint**: Sprint 408 (Neuro-Symbolic Expert System Phase 2).
- **Core Files Delivered**:
  - [`src/std/sat_solver.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/sat_solver.cl): Linear-time 2-SAT propositional verifier (Aspvall-Plass-Tarjan SCC), Horn-clause reachability, direct contradiction detection, and axiomatic consistency enforcement.
  - [`src/std/guardrails.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/guardrails.cl): Deterministic symbolic guardrails engine with unconditional Domain 0 (`SYSTEM_CORE`) inclusion, direct memory slice extraction bypassing vector ANN, orthogonal cross-domain isolation, and inviolable prompt bounds generator.
  - [`test/geomind/nses/test_sprint2_guardrails_sat.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/nses/test_sprint2_guardrails_sat.car): Official regression and empirical validation harness verifying `TS-2.1`, `TS-2.2`, and `TS-2.3`.
- **Compiler Support**:
  - Added `list_pop` / `collections_list_pop` to [`src/std/collections.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/collections.cl).

---

## 2. Empirical Verification Results

```
================================================================================
  NSES SPRINT 2 EMPIRICAL VERIFICATION HARNESS (test_sprint2_guardrails_sat)
  Testing Deterministic Guardrails, Domain 0 Immunity & SMT/SAT Verifier
================================================================================

[TS-2.1] Building Multi-Domain Test Graph with 10 Physical Invariants & 500 Facts...
  -> Serialized 510 rules across 3 domains into test_nses_graph_sprint2.car_graph
  -> Verified graph header: 510 rules, 10 strict invariants, 3 domains.
  -> Verified [SYSTEM BOUNDS - INVIOLABLE] deterministic prompt prefix formatted cleanly.
  -> Executing 100 Adversarial Misrouting Queries against Domain 2 (Fantasy)...
  -> Retention Successes: 100 / 100 (100.0% Invariable Preservation)
  -> Deterministic Slice & Extraction Latency: 0.0400 ms per turn (Budget: <= 0.8 ms)
[PASS] TS-2.1: Domain 0 (SYSTEM_CORE) Invariant Immunity & Zero ANN Bypass Verified.

[TS-2.2] Testing SMT/SAT Propositional Verifier on Clean and Contradictory Topologies...
  -> Subtest 2.2.1 PASSED: Valid implication chain verified as SAT.
  -> Subtest 2.2.2 PASSED: Direct contradiction detected (Type 1, var1=0, var2=1).
[SAT VERIFIER REJECTION] Graph compilation blocked due to logical contradiction!
  -> Offending Rules: var1 = 0, var2 = 1, conflict_type = 1
  -> Verified cargraph_verify_and_serialize cleanly blocks serialization on contradiction.
  -> Subtest 2.2.3 PASSED: Aspvall-Plass-Tarjan SCC cyclic contradiction detected (Type 2, var=0).
  -> Subtest 2.2.4 PASSED: Axiom reachability conflict detected (Type 3, var1=0, var2=1).
[PASS] TS-2.2: SMT/SAT Axiomatic Consistency & Contradiction Detection Verified.

[TS-2.3] Testing Orthogonal Workspace Isolation & Cross-Domain Leakage Prevention...
  -> Query 1 (Fantasy Route): 0 Chemistry rules leaked (0.0% leakage), 10 Domain 0 invariants preserved.
  -> Query 2 (Chemistry Route): 0 Fantasy rules leaked (0.0% leakage), 10 Domain 0 invariants preserved.
[PASS] TS-2.3: Zero Cross-Domain Leakage across Orthogonal Workspaces Verified.

================================================================================
  ALL SPRINT 2 EMPIRICAL VERIFICATION GATES PASSED (Code 0)
================================================================================
```

---

## 3. Key Mathematical & Architectural Invariants Verified
1. **Domain 0 Invariable Retention Gate**:
   - `guardrails_route_domains` guarantees `active_domain_ids = [0] + top_k(query_vec)`.
   - Across 100 adversarial prompts specifically targeting orthogonal domains, Domain 0 conservation laws achieved $100.0\%$ retention rate.
2. **Complete ANN Bypass**:
   - Strict invariants accessed via contiguous slice `[0 .. num_strict_rules - 1]` in $\mathcal{O}(1)$ time. Zero cosine calculations.
   - Retrieval latency: **0.0400 ms per turn** (Budget $\le 0.8\text{ ms}$, 20x faster than budget).
3. **SMT/SAT Invariant Verifier**:
   - Direct contradictions ($A \land \neg A$) caught and aborted.
   - Aspvall-Plass-Tarjan linear-time 2-SAT SCC cycle detection identifies mutually reachable positive and negated literals.
   - Forward BFS reachability checks prevent any strict axiom from implying a violation of itself or any other invariant.
4. **Orthogonal Domain Isolation**:
   - Proven $0.0\%$ cross-domain leakage between Domain 1 (Chemistry) and Domain 2 (Fantasy).

---

## 4. Regression Status
- Sprint 1 (`test_sprint1_binary_loader.exe`): All 4 gates (`TS-1.1` to `TS-1.4`) pass bit-for-bit exact with exit code 0.
- Live background training daemon (`geomind.exe`, PID 36616): Active and healthy (38.8% progress, validation loss 4.160).
