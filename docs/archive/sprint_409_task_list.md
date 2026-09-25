# Sprint 409 Task List: Cycle-Safe CSR Graph Traversal & Hebbian Plasticity Kernel (NSES Sprint 3)

- [x] **Task 1: CSR Graph Engine & Pinned Scratchpad (`src/std/csr_graph.cl`)**
  - [x] Implement `CsrGraph` struct with row pointers and edge arrays (`targets`, `weights`, `rels`, `timestamps`).
  - [x] Implement `NSES_Scratchpad` with monotonic epoch counter for zero-allocation reuse.
  - [x] Implement BFS traversal loop up to `max_depth = 2` with static integer path cycle rejection.
  - [x] Implement contradiction masking (`rel_type == REL_CONTRADICTS`) and attenuation pruning ($\text{Activation} \times w \times 0.85 < 0.50$).
  - [x] Implement epoch-stamped deduplication table (`DISTINCT ON (node_id)`).

- [x] **Task 2: Hebbian Synaptic Plasticity Kernel (`src/std/plasticity.cl`)**
  - [x] Implement `hebbian_strengthen_edge` with weight saturation cap ($\le 5.0$).
  - [x] Implement `hebbian_decay_edge` with lazy exponential decay formula and ground weight floor ($\ge 1.0$).
  - [x] Implement batch reinforcement and time-step synchronization operators.

- [x] **Task 3: Empirical QA Test Battery (`test/geomind/nses/test_sprint3_graph_traversal.car`)**
  - [x] `TS-3.1`: Self-loop pruning ($A \to A$).
  - [x] `TS-3.2`: Mutual cycle pruning ($A \to B \to A$).
  - [x] `TS-3.3`: Multi-node ring cycle pruning ($A \to B \to C \to D \to A$).
  - [x] `TS-3.4`: Direct and transitive contradiction masking ($A \xrightarrow{\text{contradicts}} B$).
  - [x] `TS-3.5`: Hebbian plasticity saturation (cap 5.000) and exponential decay (floor 1.000).
  - [x] Verify latency budget ($\le 3.5\text{ ms}$, Achieved: 1.00 $\mu$s) and zero runtime heap allocations during traversal.

- [x] **Task 4: Compilation, Verification & Agile Closure**
  - [x] Compile test harness via `cartanc.exe build ... -o build/test_sprint3_graph_traversal.exe`.
  - [x] Execute binary and assert exit code 0.
  - [x] Verify regression suites for Sprint 1 and Sprint 2.
  - [x] Save walkthrough to `docs/archive/sprint_409_walkthrough.md` and UI artifact.
  - [x] Update `NSES_IMPLEMENTATION_PLAN.md` and `NSES.md` with Sprint 3 completion status.
  - [x] Update `CHANGELOG.md` with release `[8.367.0]`.
