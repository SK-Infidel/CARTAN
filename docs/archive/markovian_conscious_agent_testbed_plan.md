# Research Plan: Markovian Conscious Agent Network Test Bed

## 1. Executive Summary & Theoretical Grounding
Based on Donald Hoffman's **Conscious Realism** and the **Interface Theory of Perception (ITP)**, consciousness is formalized as the fundamental ontological primitive. Rather than physical particles generating mind, physical spacetime emerges as an asymptotic, low-dimensional projection (a graphical interface) of an underlying dynamical network of **Conscious Agents**.

This research plan outlines the design, non-Euclidean information geometry, Ising state machine decision mechanics, dual telemetry observability, and implementation architecture for a native, genuine-calculation AI test bed in CARTAN.

---

## 2. Mathematical Formalism

### 2.1 The Conscious Agent Definition
Each agent $C$ is formalized as a 6-tuple $C = (X, G, W, P, D, A)$:
- **$X \subset \Delta^{d_x - 1}$**: Measurable space of conscious experiences (probability distribution on $d_x$ states).
- **$G \subset \Delta^{d_g - 1}$**: Measurable space of intended actions ($d_g$ states).
- **$W \subset \Delta^{d_w - 1}$**: Measurable space of the world / environment ($d_w$ states).
- **$P: W \times X \to [0, 1]$**: Row-stochastic **Perception kernel**, mapping world state to internal experience.
- **$D: X \times G \to [0, 1]$**: Row-stochastic **Decision kernel**, mapping experience to action disposition.
- **$A: G \times W \to [0, 1]$**: Row-stochastic **Action kernel**, mapping action to updated world state.

Each kernel is an element of the Birkhoff polytope satisfying:
$$\sum_{j} M_{ij} = 1, \quad M_{ij} \ge 0$$

### 2.2 Composite Markov Chain & Cyclic Dynamics
The sequential composition forms an endomorphism on $W$ (or joint space $X \times W$):
$$T = P \cdot D \cdot A \in \mathbb{R}^{d_w \times d_w}$$
The state probability distribution evolves according to:
$$w_{t+1} = w_t \cdot T$$

### 2.3 Closed Multi-Agent Network Interaction
In a pure conscious network, the world $W_1$ of Agent 1 consists of the experiential/action state of Agent 2, and vice versa:
$$W_1 = X_2, \quad W_2 = X_1$$
The joint network operator $\mathcal{T}$ acts on $X_1 \times X_2$:
$$\begin{pmatrix} x_{1, t+1} \\ x_{2, t+1} \end{pmatrix} = \begin{pmatrix} x_{1, t} \\ x_{2, t} \end{pmatrix} \begin{pmatrix} 0 & P_1 D_1 A_1 \\ P_2 D_2 A_2 & 0 \end{pmatrix}$$

---

## 3. Strict Non-Euclidean Geometry & Information Manifolds

Flat Cartesian assumptions ($\delta_{ij}$) violate the intrinsic geometry of probability simplexes and causal Markov networks. All calculations adhere to Riemannian and Finslerian information geometry:

### 3.1 Fisher-Rao Metric on the Probability Simplex ($\Delta^n$)
Under the square-root map $\xi_i = \sqrt{p_i}$, the probability simplex is isometrically mapped to the positive orthant of a unit hypersphere $\mathbb{S}^{n-1}$.
1. **Metric Tensor**:
   $$g_{ij}(p) = \frac{\delta_{ij}}{p_i}$$
2. **Bhattacharyya / Spherical Geodesic Distance**:
   $$d_{FR}(p, q) = 2 \arccos\left( \sum_{i=1}^n \sqrt{p_i q_i} \right)$$
3. **Riemannian Natural Gradient on Simplex**:
   Updates to probability parameters $L_{ij}$ avoid boundary distortions via Fisher-Rao orthogonal projection:
   $$\nabla^{\text{nat}} L_{ij} = \nabla L_{ij} - \sum_k M_{ik} \nabla L_{ik}$$
4. **Spherical Geodesic Retraction**:
   Parameters update along great-circle arcs on $\mathbb{S}^{n-1}$ before squaring back to the simplex.

### 3.2 Coupling with CARTAN Lie Group Geometry (`src/std/geom.cl`)
- **Killing-Cartan Metric Tensor**: Inner products across agent state projections are weighted by Dynkin index weights across the 8 Lie submanifolds:
  $$g_i = \text{geom\_killing\_form\_dynkin\_weight}(\lfloor i / 320 \rfloor \bmod 8)$$
- **Finsler-Randers Geodesic Metric**: Since Markov transitions are irreversible ($T_{ij} \neq T_{ji}$), the path geometry is Finslerian with an asymmetric drift vector $b_i$:
  $$F(x, y) = \sqrt{a_{ij}(x) y^i y^j} + b_i(x) y^i$$
- **Sasaki Tangent Bundle Metric**: Couples experiential positions $x \in X$ with their evolutionary rate of change $\dot{x} \in T_x X$.

---

## 4. Decision Engine: Ising State Machine Integration

The repository contains an unutilized prototype in `test/geomind/ising_state_machine.cl` and `src/std/physics.cl`. We elevate this into the core nonlinear decision engine of each Conscious Agent:

### 4.1 Ising/Hopfield Attractor Decision Kernel ($D: X \to G$)
Rather than using a static linear matrix for decision-making, the decision kernel $D$ is driven by an **Ising Spin State Machine**:
1. **Perceptual Spin Bias**: The experiential distribution $x_t \in X$ sets the local magnetic field $h_i$ on an $N$-spin lattice:
   $$h_i = \sum_j W_{ij}^{\text{bias}} x_{t, j}$$
2. **Glauber / Hopfield Spin Relaxation (`geomind_ising_relax`)**:
   Spins $s \in [-1, 1]^{d_g}$ relax over $K$ thermal steps using continuous mean-field dynamics:
   $$s_i^{(k+1)} = \tanh\left( \beta \left( \frac{1}{2} s_i^{(k)} + \sum_{j \neq i} J_{ij} s_j^{(k)} + h_i \right) \right)$$
   using `hopfield_spin_relax(s, h, beta)`.
3. **Action Readout**: The thermal equilibrium configuration $s^*$ parameterizes the action simplex $g_t \in G$:
   $$g_{t, i} = \frac{\exp(\kappa s^*_i)}{\sum_j \exp(\kappa s^*_j)}$$
4. **Thermodynamic Decision Confidence & Free Energy**:
   The variational free energy $F = E - T S$ acts as the agent's internal uncertainty/entropy metric:
   - High $F$ / disordered spins = decision conflict / exploratory action.
   - Low $F$ / ordered spins = decisive commitment / associative memory recall.

---

## 5. Dual Observability Architecture: Console vs. Log

To monitor all internal states without I/O degradation or data loss, we implement a **Dual Observability Pipeline**:

```
                               ┌────────────────────────────────────────────────────────┐
                               │ Conscious Agent Step Cycle                             │
                               │ (P, D [Ising], A, T, pi*, gamma, Natural Gradients)    │
                               └───────────┬────────────────────────────┬───────────────┘
                                           │                            │
                     Every N Steps (Sampled)                            Every Step (Full Fidelity)
                                           │                            │
                                           ▼                            ▼
┌────────────────────────────────────────────────────────┐   ┌────────────────────────────────────────────────────────┐
│ Interactive Console Monitor (Stdout Dashboard)         │   │ Structured Telemetry Log File                          │
│ - Current Step & Trajectory Index                      │   │ logs/conscious_agent_telemetry.jsonl                   │
│ - Spectral Gap gamma & Arrow of Time tau               │   │ - Complete State Vectors (w_t, x_t, g_t)               │
│ - Top 3 Eigenvalues (lambda_1, lambda_2, lambda_3)     │   │ - Full Transition Matrices (P, D, A, T)                │
│ - Emergent 3D Spatial Coordinates (x, y, z)            │   │ - Spin Lattice Vector s* & Ising Free Energy F         │
│ - Agent Mutual Information & Payoff                    │   │ - Natural Gradient Norms & Fisher-Rao Geodesic Shifts  │
└────────────────────────────────────────────────────────┘   └────────────────────────────────────────────────────────┘
```

- **Structured Log (`logs/conscious_agent_telemetry.jsonl`)**: Records full-dimensional vectors, stochastic matrices, spin configurations, and gradient norms on disk for post-run spectral analysis and mathematical validation.
- **Console Dashboard (Stdout)**: Displays a compact, formatted single-line telemetry banner (with optional periodic 2D projection ASCII grid) showing macro convergence metrics: $\gamma$, $\tau$, $\mathcal{F}$, and emergent $(x, y, z)$.

---

## 6. Asymptotic Spacetime Emergence (The Interface Map)

Hoffman's core theorem establishes that physical spacetime and observables are low-dimensional summaries of the underlying agent Markov chain:

1. **Perron-Frobenius Stationary State ($\pi^*$)**:
   $$\pi^* T = \pi^*, \quad \sum_i \pi^*_i = 1$$
   Computed via power iteration. The stationary state acts as the equilibrium vacuum state.
2. **Spectral Gap & Emergent Time ($\gamma, \tau$)**:
   $$\gamma = 1 - |\lambda_2|, \quad \tau = \frac{1}{\gamma}$$
   $\tau$ defines the characteristic relaxation timescale (arrow of time).
3. **Emergent Spatial Coordinates via Diffusion Maps**:
   Eigenvectors $v_2, v_3, v_4$ corresponding to non-trivial eigenvalues parameterize low-dimensional 3D spatial coordinates:
   $$\vec{r}_i = \left( \lambda_2^t v_{2}(i), \lambda_3^t v_{3}(i), \lambda_4^t v_{4}(i) \right)$$
   Physical distances $d(i, j) = \|\vec{r}_i - \vec{r}_j\|$ emerge directly from transition probabilities.

---

## 7. Architectural Implementation in CARTAN

```
┌────────────────────────────────────────────────────────┐
│ tools/markov_agent_testbed.car                         │
│ - Interactive CLI harness, console dashboard, & runner │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ src/std/conscious_agent.cl                             │
│ - ConsciousAgent struct & kernel allocation            │
│ - Fisher-Rao simplex projection & natural gradient     │
│ - Power iteration stationary solver & spectral gap     │
│ - Diffusion map 3D spatial coordinate projector        │
│ - Ising decision relaxation engine integration         │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ test/geomind/ising_state_machine.cl & src/std/physics  │
│ - hopfield_spin_relax mean-field Glauber dynamics      │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ test/compiler_suite/test_markov_conscious_agent.car    │
│ - Empirical regression suite & invariant validation    │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ logs/conscious_agent_telemetry.jsonl                   │
│ - Full-fidelity trajectory telemetry storage           │
└────────────────────────────────────────────────────────┘
```

### 7.1 Phased Implementation Work Breakdown
- **Phase 1: Non-Euclidean Stochastic Kernel Primitives (`src/std/markov.cl`)**:
  - `markov_row_softmax(tensor, rows, cols)`
  - `markov_bhattacharyya_distance(p, q, len)`
  - `markov_fisher_rao_natural_grad(grad, probs, rows, cols)`
  - `markov_stationary_distribution(T, pi_out, dim, max_iters)`
- **Phase 2: Ising Decision Engine Upgrade (`test/geomind/ising_state_machine.cl`)**:
  - Upgrade `IsingState` to support coupling matrix $J_{ij}$ and external bias $h_i$.
  - `geomind_ising_decision_step(spins, J, h, num_spins, beta, steps)`.
- **Phase 3: Conscious Agent Struct & Mutual Interaction (`src/std/conscious_agent.cl`)**:
  - Struct `ConsciousAgent { X_dim, G_dim, W_dim, P, D_ising, A, L_P, L_A, spins, J_matrix }`.
  - Function `conscious_agent_cycle(agent, w_in, w_out, log_file)`.
  - Dual-agent interaction network `conscious_network_step(agent1, agent2)`.
- **Phase 4: Dual Observability & Dashboard (`tools/markov_agent_testbed.car`)**:
  - JSONL telemetry logger writing $w_t, x_t, g_t, P, D, A, s^*, F$.
  - Console live monitor outputting $\gamma$, top 3 eigenvalues, and $(x, y, z)$ diffusion coordinates.
- **Phase 5: Regression Suite (`test/compiler_suite/test_markov_conscious_agent.car`)**:
  - Validates row-stochasticity ($\sum_j M_{ij} = 1 \pm 10^{-6}$).
  - Validates stationary convergence ($\| \pi^* T - \pi^* \| < 10^{-5}$).
  - Validates Fisher-Rao geodesic distances and non-Euclidean invariants.

---

## 8. Definition of Done & Success Criteria
- [ ] 100% genuine numerical calculations (zero mocks, zero placeholders, zero simulations).
- [ ] Row-stochastic invariant verified across all training steps ($\sum_j M_{ij} = 1.0 \pm 10^{-6}$).
- [ ] Natural gradient updates strictly adhere to Fisher-Rao information metric.
- [ ] Ising state machine actively computes decision state $s^*$ and modulates action logits.
- [ ] Dual observability active: complete trajectory logged to `.jsonl` while console displays live summary dashboard.
- [ ] Clean compilation of test bed via `cartanc.exe` with zero errors.
- [ ] All tests passing in `test/compiler_suite/`.
