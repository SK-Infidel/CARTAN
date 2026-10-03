# Sprint 520 Plan: Thermodynamic Layer Early Exit & Hopfield Speculative Drafting

## 1. Architectural Strategy
To overcome DDR5 memory bus bottlenecks during autoregressive decode (which limits streaming 3.95 GB INT8 weights to ~12 tok/s), Sprint 520 implements a dual-path acceleration strategy:
1. **Thermodynamic Layer Early Exit**:
   - Evaluates hidden state convergence $\Delta h_l = \frac{\|h_l - h_{l-1}\|_2}{\|h_l\|_2}$ at or after layer 24.
   - Because layers 0..23 write KV cache while layers 24..41 share KV from layers 22/23, exiting at layer 24..41 skips up to 18 layers (43% of parameters) with zero loss of KV completeness.
2. **Continuous Hopfield Speculative Drafting**:
   - Queries attractor transition basins in L1/L2 cache (<0.1 ms).
   - On high resonance ($R > 0.85$), drafts $K=3..5$ candidate tokens.
   - Verifies the draft burst in a single batched pass via `cartan_manifold_layer_forward_batch_int8`, streaming DDR5 weights once for multiple tokens.

---

## 2. Gated Implementation Sequence
- **Gate 1: Thermodynamic Layer Early Exit Implementation**
  - Implement vector norm delta metric in `src/std/transformer.cl`.
  - Add early exit threshold checks in `geomind_execute_manifold_decode_step` (`test/geomind/chat.cl`).
  - Ensure terminal character stream buffer flushes on early exit.
- **Gate 2: Continuous Hopfield Speculative Drafting**
  - Implement speculative sequence drafting from attractor transitions in `src/std/resonator.cl`.
  - Integrate speculative candidate burst generation and batch verification in `test/geomind/chat.cl`.
- **Gate 3: Empirical Verification & Benchmarking**
  - Recompile compiler and GeoMind neural engine.
  - Benchmark decode tok/s, early exit frequency, and speculative burst acceptance.
  - Run regression test suite (`tools/run_affected_tests.ps1`).
- **Gate 4: Documentation & Sprint Closeout**
  - Update `ISSUES.md` (`[ISSUE-377]` resolved).
  - Update `docs/ROADMAP.md`.
  - Update `CHANGELOG.md`.
  - Author `docs/archive/sprint_520_walkthrough.md`.
