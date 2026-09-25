# Sprint 409 Plan: Cycle-Safe CSR Graph Traversal & Hebbian Plasticity Kernel (NSES Sprint 3)

## 1. Context & Objectives
- **Subsystem**: Neuro-Symbolic Expert System (NSES) Phase 3.
- **Goal**: Implement high-performance, cycle-safe CSR graph traversal and adaptive Hebbian synaptic plasticity.
- **Key Invariants**:
  1. **Zero-Allocation BFS Traversal**: Pinned `NSES_Scratchpad` with monotonic epoch counter (`current_epoch`), eliminating all runtime `malloc`, `free`, and `memset` operations.
  2. **Cycle Rejection**: Static integer path history (`path_0`, `path_1`, `path_2`) instantly pruning self-loops ($A \to A$), mutual cycles ($A \to B \to A$), and multi-node rings ($A \to B \to C \to D \to A$).
  3. **Contradiction Masking & Attenuation**: Edges with `rel_type == REL_CONTRADICTS` dropped immediately. Activation attenuates via $\text{Activation}_{t+1} = \text{Activation}_t \times w_{\text{edge}} \times 0.85$; paths falling below $\tau = 0.50$ are pruned.
  4. **Hebbian Synaptic Plasticity**: Reinforcement saturation at $\min(w + \Delta w, 5.0)$ and lazy exponential decay $\max(w \cdot e^{-\lambda \Delta t}, 1.0)$.
  5. **Strict Isolation**: All tracking remains strictly inside `NSES_IMPLEMENTATION_PLAN.md` and `NSES.md` (no items in `ISSUES.md`).

---

## 2. Architecture & File Manifest

### A. [`src/std/csr_graph.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/csr_graph.cl)
- Compressed Sparse Row (CSR) graph storage and loader from `.car_graph`.
- Pinned `NSES_Scratchpad` supporting zero-allocation traversal and epoch-stamped deduplication (`DISTINCT ON (node_id)`).
- Cycle-safe BFS traversal engine up to `max_depth = 2` (or configurable).
- Immediate contradiction masking and activation attenuation thresholding.

### B. [`src/std/plasticity.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/plasticity.cl)
- Synaptic weight reinforcement operator `hebbian_strengthen_edge` with saturation clamp.
- Lazy exponential decay operator `hebbian_decay_edge` with minimum ground weight floor.
- Timestamp synchronization and edge update operators.

### C. [`test/geomind/nses/test_sprint3_graph_traversal.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/nses/test_sprint3_graph_traversal.car)
- Verification harness executing the full adversarial battery:
  - `TS-3.1`: Self-loop pruning ($A \to A$).
  - `TS-3.2`: Mutual cycle pruning ($A \to B \to A$).
  - `TS-3.3`: Multi-node ring cycle pruning ($A \to B \to C \to D \to A$).
  - `TS-3.4`: Direct and transitive contradiction masking ($A \xrightarrow{\text{contradicts}} B$).
  - `TS-3.5`: Hebbian plasticity saturation (cap 5.000) and exponential decay (floor 1.000).
- Performance Budget: Traversal latency $\le 3.5\text{ ms}$, heap allocations during traversal = 0 bytes.

---

## 3. Definition of Done (DoD)
- [ ] Code passes static type checking and LLVM IR codegen via `cartanc.exe`.
- [ ] Zero runtime regressions across Sprint 1, 2, and 3.
- [ ] Empirical verification tests (`TS-3.1` to `TS-3.5`) pass with exit code 0.
- [ ] Implementation plan, task list, and walkthrough saved in `docs/archive/`.
- [ ] `CHANGELOG.md` updated with release `[8.367.0]`.
- [ ] `NSES_IMPLEMENTATION_PLAN.md` and `NSES.md` updated with Sprint 3 completion status.
