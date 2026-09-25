# Sprint 410 Plan: Burroughs Lateral Injection Engine & Structured Prompt Scaffold (NSES Sprint 4)

## 1. Context & Objectives
- **Subsystem**: Neuro-Symbolic Expert System (NSES) Phase 4.
- **Goal**: Implement Burroughsian stochastic cut-up fragment pool, ultra-fast non-blocking PRNG sampler with atomic usage metrics, and an inviolable 4-block structured prompt assembly engine.
- **Key Invariants**:
  1. **Stratified Burroughs Fragment Pool**: Partitioned by domain and entropy tier (Tier 1: Adjacent Analogies, Tier 2: Structural Metaphors, Tier 3: Radical Abstractions).
  2. **Zero-Entropy Gating (`TS-4.1`)**: `entropy_tier == 0` strictly produces empty/NULL lateral context with zero text injection.
  3. **High-Uniformity PRNG (`TS-4.2`)**: Fast, non-blocking L'Ecuyer/Marsaglia combined generator passing Chi-Square ($\chi^2$) uniformity across 10,000 draws ($p > 0.01$) with atomic monotonic usage accounting.
  4. **Inviolable 4-Block Scaffold (`TS-4.3`)**: Fixed-capacity prompt buffer synthesizing `[SYSTEM BOUNDS - INVIOLABLE]`, `[OBJECTIVE KNOWLEDGE & ACTIVE MEMORY]`, `[LATERAL ASSOCIATION]`, `[USER INPUT]` with strict delimiter sanitization to prevent adversarial boundary overwrite.
  5. **Latency Budgets**: Sampling $\le 0.3\text{ ms}$, assembly $\le 0.4\text{ ms}$.
  6. **Strict Subproject Isolation**: Track solely in `NSES_IMPLEMENTATION_PLAN.md` and `NSES.md` (no items in `ISSUES.md`).

---

## 2. Architecture & File Manifest

### A. [`src/std/burroughs.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/burroughs.cl)
- In-memory `BurroughsPool` storing stratified lateral association primes.
- `BurroughsRngState` fast PRNG with seed initialization and uniform draw operators.
- `burroughs_sample_fragment(pool, domain_id, entropy_tier, rng)` with monotonic usage metrics.

### B. [`src/std/prompt_scaffold.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/prompt_scaffold.cl)
- `PromptScaffoldBuffer` pinned text buffer with bounds safety.
- Delimiter sanitization for boundary containment (`[SYSTEM BOUNDS - INVIOLABLE]` quarantine).
- 4-block assembler combining guardrails, episodic memory nodes, lateral primes, and user input.

### C. [`test/geomind/nses/test_sprint4_burroughs_prompt.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/nses/test_sprint4_burroughs_prompt.car)
- Verification harness executing:
  - `TS-4.1`: Zero-entropy lateral nullity.
  - `TS-4.2`: Chi-Square uniformity test on 10,000 draws ($p > 0.01$).
  - `TS-4.3`: Adversarial boundary containment test.
  - Latency benchmarks.

---

## 3. Definition of Done (DoD)
- [ ] Code passes static type checking and LLVM IR codegen via `cartanc.exe`.
- [ ] Zero runtime regressions across Sprint 1, 2, 3, and 4.
- [ ] Empirical verification tests (`TS-4.1`, `TS-4.2`, `TS-4.3`) pass with exit code 0.
- [ ] Implementation plan, task list, and walkthrough saved in `docs/archive/`.
- [ ] `CHANGELOG.md` updated with release `[8.368.0]`.
- [ ] `NSES_IMPLEMENTATION_PLAN.md` and `NSES.md` updated with Sprint 4 completion status.
