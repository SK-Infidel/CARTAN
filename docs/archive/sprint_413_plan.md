# Sprint 413 Implementation Plan: NSES-Guided Deterministic Loss Shaping & Knowledge Grounding Engine

**Document Version**: `v1.0.0`  
**System Release**: `[8.371.0]`  
**Sprint**: Sprint 413 (NSES Phase 7: Training Integration & Loss Shaping)  
**Goal**: Break the 4.07 cross-entropy training loss plateau by integrating NSES-guided deterministic loss shaping, multi-domain causal/taxonomic knowledge grounding, and interval sleep consolidation into GeoMind's training pipeline.

---

## 1. Architectural Dependency Graph

```
┌────────────────────────────────────────────────────────┐
│ tools/cargraph_ingest.car                              │
│ (Scaled Multi-Domain Ingestion: Core, Physics, Math,   │
│  Complexity, Biology, and WordNet Causal Taxonomy)     │
└───────────────────────────┬────────────────────────────┘
                            │ Compiles to
                            ▼
┌────────────────────────────────────────────────────────┐
│ test/geomind/trainingdata/nses_knowledge.car_graph     │
│ (64-byte aligned flat binary with 6 domains & 50+ rules)
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ src/std/veto_gate.cl & src/std/nses_pipeline.cl        │
│ (Symbolic Penalty Loss & Invariant Gradient Vector)    │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ test/geomind/train.cl                                  │
│ (Pre-Step Domain Routing, Symbolic Loss Hook,          │
│  and Metacognitive Sleep Consolidation Intervals)      │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ test/geomind/nses/test_sprint7_loss_shaping.car        │
│ (Dedicated Verification Suite & Loss Gradient Gate)    │
└────────────────────────────────────────────────────────┘
```

---

## 2. Technical Work Breakdown

### Milestone 1: Knowledge Ingestion Scale-Up (`tools/cargraph_ingest.car`)
- Expand `cargraph_ingest.car` from 4 specialized domains to 6 comprehensive cognitive domains:
  1. `SYSTEM_CORE` (Physical invariants, thermodynamics, relativity, non-contradiction).
  2. `PHYSICS_SIM` (Mechanics, energy conservation, restitution, friction, forces).
  3. `TOPOLOGY_MATH` (Differential forms, manifolds, Stokes theorem, metric tensors).
  4. `COMPUTATION_LOGIC` (Automata, Halting problem, NP-completeness, space hierarchy).
  5. `BIOLOGICAL_SYSTEMS` (Photosynthesis, cellular respiration, genetics, evolutionary inheritance).
  6. `CAUSAL_TAXONOMY` (WordNet hypernym entailments, causal directionality, mutual exclusion).
- Expand SAT solver consistency assertions and rebuild `test/geomind/trainingdata/nses_knowledge.car_graph`.

### Milestone 2: NSES Symbolic Loss Shaping Kernel (`src/std/veto_gate.cl` & `src/std/nses_pipeline.cl`)
- Implement `veto_compute_symbolic_loss_penalty(reg, domain_id, logits_ptr, vocab_len)`:
  - Scans candidate next-token vocabulary against active domain invariants and forbidden contradiction patterns.
  - Injects direct analytical negative gradients: $\Delta z_k = \lambda_{\text{sym}} \cdot P(k)$ on forbidden tokens.
  - Adds a scalar loss penalty term $\mathcal{L}_{\text{sym}}$ to reward valid completions and suppress hallucinations.

### Milestone 3: Training Engine Integration (`test/geomind/train.cl`)
- In `geomind_train_chunk_gpu_pipelined` and streaming train loops:
  - Route current sequence context through `nses_pipeline_execute_turn` to identify active domain.
  - Apply symbolic logit penalty before fused Softmax / cross-entropy step.
  - Add periodic interval sleep consolidation: every $N$ chunks, execute offline Hopfield and NSES sleep compaction to prune transient gradient jitter.

### Milestone 4: Empirical QA Verification (`test/geomind/nses/test_sprint7_loss_shaping.car`)
- `TS-7.1`: Validates that forbidden/contradictory tokens receive negative gradient penalty ($\Delta z < 0$).
- `TS-7.2`: Validates that compliant domain tokens are unperturbed ($\Delta z = 0$).
- `TS-7.3`: Multi-domain knowledge graph integrity test (monotonic CSR offsets, SAT satisfiability).
- `TS-7.4`: Comparative mini-batch training pass verifying faster loss convergence with NSES loss shaping.

---

## 3. Definition of Done (DoD)
- [ ] Scaled `.car_graph` compiled cleanly with 6 domains and zero SAT contradictions.
- [ ] Symbolic loss penalty kernel implemented with zero memory leaks.
- [ ] Integrated into `test/geomind/train.cl` with configurable $\lambda_{\text{sym}}$ and sleep intervals.
- [ ] Dedicated test harness `test_sprint7_loss_shaping.car` passes all gates with Exit Code 0.
- [ ] Zero regressions across all existing compiler suites and NSES suites.
- [ ] Walkthrough and CHANGELOG updated.
