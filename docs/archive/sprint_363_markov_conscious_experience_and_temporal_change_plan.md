# Sprint 363 Plan: Markovian Conscious Experience, Temporal Change & Hoffman Empirical Framework

## 1. Context & Motivation
In Donald Hoffman's Conscious Realism, reality is fundamentally **Experience ($X$) and its Change over Time ($t$)**.
The previous telemetry implementation focused on abstract algebraic eigenvalues (spectral gap $\gamma$) and statistical physics (Ising Helmholtz Free Energy), while leaving the actual experiential state vector $X$ buried and omitting the temporal derivative $\Delta X_t = d_{FR}(X_t, X_{t-1})$.
Sprint 363 exposes the experiential state $X \in \Delta^{d_x-1}$, tracks genuine temporal change $\Delta X_t$, provides intuitive console and JSONL streams, and produces an academic-grade specification to share with Dr. Donald Hoffman for empirical guidance.

## 2. Technical Architecture & Invariants
1. **Experiential State History ($X_{t-1}$)**:
   - Expand `struct ConsciousAgent` in `src/std/conscious_agent.cl` with `x_prev: ptr`.
   - In `conscious_agent_cycle`, copy `x_buf` to `x_prev` before perceptual evaluation.
2. **Experiential Metrics**:
   - `conscious_agent_experiential_change(agent)`: $d_{FR}(X_t, X_{t-1}) = 2 \arccos(\sum \sqrt{x_{t,i} x_{t-1,i}})$.
   - `conscious_agent_experiential_entropy(agent)`: $H(X) = -\sum x_i \ln x_i$ (sharp focus vs diffuse awareness).
   - `conscious_agent_dominant_qualia(agent)`: $\arg\max_i X_i$ (active qualia ID).
   - `conscious_agent_dominant_qualia_intensity(agent)`: $\max_i X_i$ (active qualia salience).
3. **Telemetry Realignment**:
   - Update `tools/markov_agent_testbed.car` console output:
     `[Step t] Time t (τ: ...) | Qualia: #i (val: ...) | H(X): ... | ΔX: ... | Headset 3D: [x, y, z]`
   - Update `logs/conscious_agent_telemetry.jsonl` to record full experiential distributions $X_1, X_2$, temporal changes $\Delta X_1, \Delta X_2$, and inter-agent distance.
4. **Hoffman Empirical Framework Document**:
   - Comprehensive report `docs/archive/hoffman_conscious_realism_cartan_empirical_framework.md` documenting the mathematical implementation and soliciting Dr. Hoffman's guidance on metrics and observational signatures.
