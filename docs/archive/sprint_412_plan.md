# Sprint 412 Plan: Subconscious Mental Notes & Autonomous Expert System Genesis (NSES Sprint 6)

## 1. Context & Objectives
- **Subsystem**: Neuro-Symbolic Expert System (NSES) Phase 6.
- **Goal**: Implement the autonomous subconscious mental note cycle enabling GeoMind to mine empirical facts/invariants, ground triplets to active ontology, pass them through a symbolic immune check, dynamically append them to a two-tier Delta-CSR arena, autonomously mint novel domain partitions, and consolidate memory during offline sleep.
- **Key Invariants**:
  1. **Epistemic Saliency Filter (`TS-SUB-1`)**: Top-4 logit entropy ($H_4 \le 0.20\text{ nats}$) and margin probe ($\Delta \ge 3.2\text{ logits}$) filtering out casual banter with 0.0% false positive rate ($0/1,000$) and detecting insight statements with $\ge 99.5\%$ trigger rate ($995/1,000$).
  2. **Ontological Grounding Gate**: Validates candidate subject/object proximity to established domain ontology ($\cos \ge 0.70$). Rejects 100% of ambiguous idioms and prompt-injection traps ($0/250$ spurious note admissions).
  3. **Symbolic Immune Pass (`TS-SUB-2`)**: 100% block rate on direct invariant negations ($500/500$) and multi-hop transitive contradictions ($300/300$) via linear-time 2-SAT verification. Guarantees bit-for-bit exact memory rollback on rejection.
  4. **Two-Tier Delta-CSR Memory Architecture**: Pre-allocated dynamic arena chaining 64-byte `NSES_EdgeChunk` structures with SIMD 64-byte alignment, traversed seamlessly alongside static base CSR in hybrid BFS with 0 runtime heap allocations.
  5. **Autonomous Domain Genesis & Clustering (`TS-SUB-3`)**: Mints new domain partitions when novelty threshold $1 - \max_d \cos(\mathbf{e}, \mathbf{c}_d) > 0.35$. Ingests granular facts into existing domains ($100\%$ attachment), maintaining asymptotic centroid stability.
  6. **Sleep Consolidator & 10k Soak (`TS-SUB-4`)**: Offline Hebbian decay pruning ($w < 1.001$), CSR compaction, and atomic `.car_graph` binary file swap. 10,000-cycle soak with 0 heap growth after cycle 100.
  7. **Subconscious Latency Budget**: Total subconscious overhead $\le 4.0\text{ ms}$ per turn.
  8. **Strict Subproject Isolation**: Track solely in `NSES_IMPLEMENTATION_PLAN.md` and `NSES.md` (no items in `ISSUES.md`).

---

## 2. Architecture & File Manifest

### A. Saliency Probe & Grounded SVO Extractor
- [`src/std/saliency_probe.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/saliency_probe.cl): Top-4 logit entropy and margin calculator.
- [`src/cartanc/svo_extractor.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/svo_extractor.car): FST causal token scanner and Ontological Grounding Gate ($\cos \ge 0.70$).

### B. Dynamic Delta Arena & Hybrid CSR
- [`src/std/dynamic_graph.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/dynamic_graph.cl): Two-tier Delta-CSR memory manager with 64-byte `NSES_EdgeChunk` chaining and atomic rollbacks.
- [`src/std/csr_graph.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/csr_graph.cl): Hybrid BFS kernel walking both static base slices and dynamic delta chunks.

### C. Autonomous Domain Genesis & Clustering
- [`src/std/domain_genesis.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/domain_genesis.cl): Online centroid tracker and novel partition allocator ($\theta_{\text{novel}} = 0.35$).

### D. Offline Sleep Consolidator
- [`src/std/cargraph_consolidate.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/cargraph_consolidate.cl): Synaptic decay pruning, table compaction, and atomic `.car_graph` swap.
- [`test/geomind/sleep.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/sleep.car): Hook offline consolidation daemon into sleep cycle.

### E. Empirical Verification Test Battery
- `test/geomind/nses/test_subconscious_saliency.car` (`TS-SUB-1`)
- `test/geomind/nses/test_subconscious_immune_pass.car` (`TS-SUB-2`)
- `test/geomind/nses/test_subconscious_clustering.car` (`TS-SUB-3`)
- `test/geomind/nses/test_subconscious_soak_10k.car` (`TS-SUB-4`)

---

## 3. Definition of Done (DoD)
- [ ] Code passes static type checking and LLVM IR codegen via `cartanc.exe`.
- [ ] Empirical verification suites (`TS-SUB-1`, `TS-SUB-2`, `TS-SUB-3`, `TS-SUB-4`) pass with exit code 0.
- [ ] Subconscious overhead hard gate $\le 4.0\text{ ms}$ verified.
- [ ] Zero regressions across Sprints 1–5 regression test battery.
- [ ] Implementation plan, task list, and walkthrough saved in `docs/archive/`.
- [ ] `CHANGELOG.md` updated with release `[8.370.0]`.
- [ ] `NSES_IMPLEMENTATION_PLAN.md` updated with Sprint 6 completion scorecard.
