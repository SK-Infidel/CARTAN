# Sprint 303 Implementation Plan: Autonomous Metacognitive Sleep Daemon

## 1. Context & Objectives
- **Target**: [Phase 59 Item 5](file:///C:/Users/rich-/source/repos/CARTAN/docs/ROADMAP.md#L179): "Autonomous Metacognitive Sleep Daemon: Re-implement background replay loop (`sleep.ctn` / `sleep.car`) consolidating episodic attractors into slow cortical weights during system idle."
- **Defect Identified**: `[ISSUE-054]` in [`ISSUES.md`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md): Missing offline consolidation daemon for Continuous Hopfield attractor memory and slow-weight Hebbian plasticity.

---

## 2. Mathematical & Architectural Design
1. **Generative Episodic Replay**:
   - For each active attractor basin $\xi_k \in \mathbb{R}^{2560}$ in `hopfield_basins.bin`:
     - Perturb $\xi_k$ with low-temperature exploratory noise: $\tilde{\xi}_k = \xi_k + \epsilon$.
     - Run relaxation: $h_k^* = \text{Relax}(\tilde{\xi}_k, \beta=2.0, \text{steps}=3)$.
     - Compute reconstruction resonance:
       $$\rho_k = \frac{\xi_k \cdot h_k^*}{\|\xi_k\| \|h_k^*\|}$$
2. **Hebbian Slow-Weight Consolidation**:
   - Update permanent cortical synaptic weights $W_{\text{slow}}$ using neuromodulated Hebbian replay:
     $$\Delta W_{\text{slow}} = \eta_{\text{sleep}} \cdot (\xi_k \otimes h_k^*) - \lambda_{\text{decay}} W_{\text{slow}}$$
   - Calls `cartan_tensor_hebbian_update(\xi_k, h_k^*, M=+1.0, \eta_{\text{sleep}})`.
3. **Metacognitive Pruning & Compaction**:
   - Evaluate basin energy $E(\xi_k)$. If $E(\xi_k) > \theta_{\text{unstable}}$ (spurious basin) or $\cos(\xi_k, \xi_j) > 0.98$ for $j < k$ (redundant duplicate basin), prune the basin.
   - Save consolidated, compacted basins back to `hopfield_basins.bin`.
4. **Daemon Architecture**:
   - Standalone executable script: `test/geomind/sleep.car`.
   - CLI flag in `test/geomind/main.car`: `--sleep [cycles]`.
   - Standard library module: `src/std/sleep.cl`.

---

## 3. Work Breakdown
1. **Standard Library Sleep Module (`src/std/sleep.cl`)**:
   - `sleep_replay_basin(basin_vec, beta, steps)`: Generates relaxed state and computes resonance.
   - `sleep_consolidate_weights(basin_vec, relaxed_vec, lr)`: Applies Hebbian slow-weight update.
   - `sleep_run_cycle(basins_path, max_cycles, prune_threshold)`: Full sleep cycle across all active basins.
2. **C Runtime Acceleration (`src/cartanc/geomind_runtime.c`)**:
   - `cartan_sleep_consolidate_cycle`: In-place replay, Hebbian slow-weight consolidation, and basin pruning.
3. **GeoMind CLI Integration (`test/geomind/main.car`)**:
   - Add `--sleep [cycles]` flag to trigger sleep memory consolidation.
4. **Standalone Daemon Script (`test/geomind/sleep.car`)**:
   - Standalone daemon entry point for background execution.
5. **Target 55 Regression Test Suite (`test/compiler_suite/test_sleep_consolidation.car`)**:
   - Test 1: Attractor basin generative replay and resonance.
   - Test 2: Hebbian slow-weight synaptic consolidation.
   - Test 3: Redundant/spurious basin pruning.
   - Test 4: Binary basin file persistence across sleep cycles.
   - Test 5: C Runtime `cartan_sleep_consolidate_cycle` binding.
6. **Test Runner Update (`test/compiler_suite/run_tests.car`)**:
   - Register Target 55 and verify all 55 tests pass.

---

## 4. Logical Dependency Graph
```
src/std/sleep.cl ──┬──> test/geomind/sleep.car
                   ├──> test/geomind/main.car (--sleep)
                   └──> test/compiler_suite/test_sleep_consolidation.car (Target 55)
                             │
src/cartanc/geomind_runtime.c ─┤
                             ▼
               test/compiler_suite/run_tests.car (55/55)
```
