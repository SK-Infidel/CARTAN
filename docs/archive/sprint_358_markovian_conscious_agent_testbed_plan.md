# Sprint 358 Plan: Markovian Conscious Agent Network Test Bed Implementation

## 1. Objectives & Scope
- Implement Donald Hoffman's **Conscious Realism** mathematical architecture in CARTAN:
  - Multi-agent network with Perception ($P$), Decision ($D$), and Action ($A$) row-stochastic kernels.
  - Strict non-Euclidean information geometry on the probability simplex $\Delta^n$ (Fisher-Rao metric, Bhattacharyya geodesic distance, natural gradients).
  - Ising state machine mean-field Glauber relaxation decision engine (`ising_state_machine.cl`).
  - Asymptotic emergence of spacetime coordinates $(x, y, z)$ via spectral diffusion maps of the Markov transition operator $T$.
  - Dual Observability Pipeline: Structured `.jsonl` telemetry log + formatted real-time stdout console dashboard.
- Zero mock or placeholder calculations: 100% genuine numerical matrix algebra, power iteration, and spin dynamics.

## 2. Component Breakdown
1. **`src/std/markov.cl`**:
   - `markov_row_softmax(logits, rows, cols, out)`
   - `markov_matrix_mult(A, B, out, m, k, n)`
   - `markov_bhattacharyya_distance(p, q, len)`
   - `markov_fisher_rao_natural_grad(grad, probs, rows, cols, out_nat)`
   - `markov_stationary_distribution(T, pi_out, dim, max_iters)`
   - `markov_spectral_gap(T, pi_stat, dim, temp_v, temp_out)`
   - `markov_diffusion_coordinates(T, pi_stat, dim, coords_out)`
2. **`test/geomind/ising_state_machine.cl`**:
   - Upgrade `IsingState` to support coupling matrix $J_{ij}$ and external field bias $h_i$.
   - `geomind_ising_decision_step(spins, J, h, num_spins, beta, steps)`
   - `geomind_ising_free_energy(spins, J, h, num_spins, beta)`
3. **`src/std/conscious_agent.cl`**:
   - `ConsciousAgent` struct ($d_x, d_g, d_w, P, D, A, T, L_P, L_A, \text{spins}, J$).
   - `conscious_agent_create(...)`
   - `conscious_agent_step(...)`
   - `conscious_network_interact(...)`
   - Telemetry JSONL serialization to `logs/conscious_agent_telemetry.jsonl`.
4. **`tools/markov_agent_testbed.car`**:
   - Full CLI test bed executable demonstrating dual interacting agents, spectral gap, and emergent 3D coordinates.
5. **`test/compiler_suite/test_markov_conscious_agent.car`**:
   - Verification test target verifying stochastic invariants ($\sum_j M_{ij} = 1 \pm 10^{-6}$), stationary state convergence ($\|\pi^* T - \pi^*\| < 10^{-5}$), Fisher-Rao geodesic consistency, and Ising relaxation.

## 3. Definition of Done (DoD)
- [ ] All code compiles cleanly via self-hosting `cartanc.exe`.
- [ ] Zero runtime crashes, memory leaks, or NaN occurrences.
- [ ] Verified non-Euclidean information geometric invariants.
- [ ] Telemetry successfully logged to `logs/conscious_agent_telemetry.jsonl`.
- [ ] Walkthrough saved to `docs/archive/sprint_358_markovian_conscious_agent_testbed_walkthrough.md`.
- [ ] `CHANGELOG.md` updated.
