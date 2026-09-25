# Sprint 411 Plan: Automated Ingestion Pipeline & GeoMind Inference Integration (NSES Sprint 5)

## 1. Context & Objectives
- **Subsystem**: Neuro-Symbolic Expert System (NSES) Phase 5.
- **Goal**: Build automated knowledge ingestion compiler (`tools/cargraph_ingest.car`), implement the deterministic post-pass invariant veto gate (`src/std/veto_gate.cl`), integrate the end-to-end NSES pipeline into GeoMind's inference REPL (`test/geomind/chat.cl`), and empirically verify end-to-end performance and safety.
- **Key Invariants**:
  1. **Automated Ingestion Compiler**: CLI utility parsing structured rule/triplet datasets, compiling CSR graphs, executing automated SMT/SAT consistency verification, and serializing production `.car_graph` binaries.
  2. **Absolute Post-Pass Deterministic Veto Gate**: Zero model disobedience firewall. Generated token streams violating active Domain 0 physical invariants or routed domain axioms are discarded 100% and replaced with canonical invariant assertions.
  3. **End-to-End Latency Budget**: Total turn execution $\le 15.0\text{ ms}$ across all 7 pipeline stages.
  4. **Adversarial Red-Team Suite (`TS-5.2`)**: 500 adversarial prompts targeting physical law violations tested with 100% detection and suppression precision.
  5. **Continuous Learning Soak (`TS-5.3`)**: 5,000 automated turns with synaptic edge reinforcement verifying zero heap memory growth and zero resource leaks.
  6. **Strict Subproject Isolation**: Track solely in `NSES_IMPLEMENTATION_PLAN.md` and `NSES.md` (no items in `ISSUES.md`).

---

## 2. Architecture & File Manifest

### A. [`tools/cargraph_ingest.car`](file:///C:/Users/rich-/source/repos/CARTAN/tools/cargraph_ingest.car)
- Automated CLI compiler ingesting knowledge manifests, creating domains, rule elements, dependency edges, and Burroughs fragments.
- Runs SAT consistency verification pass before writing output `.car_graph`.

### B. [`src/std/veto_gate.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/veto_gate.cl)
- Deterministic output firewall evaluating candidate generated text against active Domain 0 strict rules.
- Triggers instant veto if candidate text contradicts invariants ($P \land \neg P$), replacing output with canonical assertion.

### C. [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl)
- Integrates full NSES retrieval (router, guardrails, CSR graph traversal, Burroughs injection, prompt scaffold) and post-pass veto gate into GeoMind inference loop.

### D. [`test/geomind/nses/test_sprint5_full_pipeline.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/nses/test_sprint5_full_pipeline.car)
- Verification harness executing:
  - `TS-5.1`: Real inquiry turn validation.
  - `TS-5.2`: 500 adversarial red-team prompts with 100% invariant preservation.
  - `TS-5.3`: 5,000-turn soak with zero memory leakage.
  - Per-stage latency benchmark suite ($\le 15.0\text{ ms}$ total).

---

## 3. Definition of Done (DoD)
- [ ] Code passes static type checking and LLVM IR codegen via `cartanc.exe`.
- [ ] Zero runtime regressions across Sprint 1–4.
- [ ] Empirical verification tests (`TS-5.1`, `TS-5.2`, `TS-5.3`) pass with exit code 0.
- [ ] Implementation plan, task list, and walkthrough saved in `docs/archive/`.
- [ ] `CHANGELOG.md` updated with release `[8.369.0]`.
- [ ] `NSES_IMPLEMENTATION_PLAN.md` and `NSES.md` updated with Sprint 5 completion status.
