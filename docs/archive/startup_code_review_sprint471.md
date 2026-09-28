# Sprint 471 Startup Code Review: Domain 18 (Software Engineering, Application Programming & Algorithms)

## Review Objective
Evaluate readiness for synthesizing Domain 18 (`SOFTWARE_ENGINEERING_ALGORITHMS`), expanding the active knowledge base from 18 to 19 cognitive domains (0..18), 162 to 172 rules (0..171), and 36 to 38 strict invariants.

---

## Logical Dependency Tree

```
                       [tools/cargraph_ingest.car]
                                   │
                                   ▼
              [test/geomind/trainingdata/nses_knowledge.car_graph]
                                   │
                                   ▼
 ┌───────────────────────┬────────────────────────┬──────────────────────┐
 │                       │                        │                      │
 ▼                       ▼                        ▼                      ▼
[src/std/veto_gate.cl] [src/std/domain_lexicon] [src/std/burroughs] [src/std/dynamic_gamma]
 │                       │                        │                      │
 └───────────────────────┼────────────────────────┴──────────────────────┘
                         ▼
             [src/std/nses_pipeline.cl]
                         │
        ┌────────────────┴────────────────┐
        ▼                                 ▼
[test/geomind/chat.cl]          [test/geomind/train.cl]
        │                                 │
        └────────────────┬────────────────┘
                         ▼
   [test/compiler_suite/test_nses_software_engineering_domain.car] (Target 81)
                         │
                         ▼
      [test/compiler_suite/run_tests.car] (81 Targets)
```

---

## Codebase Findings & Readiness Audit

1. **`tools/cargraph_ingest.car`**:
   - Currently models 18 domains (0..17) and 162 rules.
   - SMT/SAT solver initialized with capacity for 192 variables.
   - Expanding to 19 domains and 172 rules requires scaling SAT capacity to 256 variables to ensure ample headroom for Horn-clause satisfiability checking.
   - Action: Add Domain 18 partition, Rules 162..171, 2 strict axioms (Rules 162 & 163), intra-domain and cross-domain implications (162 $\to$ 82, 163 $\to$ 21, 166 $\to$ 132), and scale solver capacity to 256.

2. **`src/std/veto_gate.cl`**:
   - `veto_registry_create` was upgraded in Sprint 470 to initialize 32 domain token slots (`d < 32.0`), which accommodates Domain 18 cleanly without buffer reallocation.
   - Action: Add Veto Rule 23 (Software Engineering Anti-Patterns: circular wait deadlock, infinite recursion / stack overflow, contract postcondition breach, unvalidated buffer injection).
   - Register contradiction tokens `1801.0`–`1804.0`.

3. **`src/std/domain_lexicon.cl`**:
   - Currently stores frames 0..17.
   - Action: Add Frame 18 (`[Software Engineering Frame]`), specialized terms (`hoare_logic`, `idempotence`, `cache_locality`, `circular_wait`, `amortized_time`), and extend category error validation to disallow biological and differential-form predicates on software engineering abstractions.

4. **`src/std/burroughs.cl` & `src/std/dynamic_gamma.cl`**:
   - Action: Add lateral primes 49, 50, 51 across Tiers 1..3 for Domain 18.
   - Action: Add Domain 18 baseline coupling factor (`b * 1.25`) in `dynamic_gamma_domain_baseline`.

5. **`src/std/nses_pipeline.cl`**:
   - Dynamic CSR node capacity handles $N_{rules} + 64$.
   - Action: Add Stage 1 intent detection for software engineering, algorithms, concurrency, and refactoring queries.
   - Action: Wire Stage 3 seed (162.0), CSR intra-domain edges (162 $\to$ 163 $\to$ 168, 166 $\to$ 169), cross-domain bridges (162 $\to$ 82, 163 $\to$ 21, 166 $\to$ 132), and linguistic hub edge (47 $\to$ 162).
   - Action: Add unbacked memory fallbacks for node IDs 162..171.

6. **`test/geomind/train.cl`**:
   - Action: Wire dataset stream routing for software engineering corpora to `active_d = 18.0`.

7. **Zero-Mock & Entropy Assessment**:
   - All rules, invariants, SMT/SAT checks, and veto scans will perform genuine calculations and string/token comparisons.
   - No mock or simulated operations.
