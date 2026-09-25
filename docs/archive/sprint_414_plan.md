# Sprint 414 Plan: Dynamic Adaptive Domain Focus & Lag Catch-Up Scheduler

## Objective
Implement an autonomous, dynamic domain catch-up scheduler in GeoMind's multi-domain streaming engine (`test/geomind/train.cl`). When an individual dataset falls behind the fleet validation loss baseline, the engine automatically engages focused training bursts on the lagging dataset until parity is restored, while interleaving periodic anti-forgetting fleet rehearsal passes.

---

## Architecture & Algorithm

### 1. Lagging Domain Detection
- Periodically compute the fleet mean validation loss $\overline{VL}_{\text{fleet}}$ and domain-specific gap:
  $$\Delta_d = VL_d - \frac{1}{N-1}\sum_{k \ne d, VL_k > 0} VL_k$$
- If $\Delta_d > 0.85$ (domain $d$ lags fleet by $> 0.85$ loss units), trigger **Focused Catch-Up Mode** on domain $d$.

### 2. Focused Training Bursts
- Retain continuous recurrent hidden state `g_buf_domain_h[d]` across consecutive chunks to accelerate gradient convergence.
- Run consecutive chunks on the lagging dataset until the validation gap closes below tolerance:
  $$\Delta_d \le 0.35$$

### 3. Anti-Forgetting Rehearsal Guard
- To prevent catastrophic forgetting across the other $N-1$ domains during extended focus, every 4 focused chunks (`focus_streak >= 4.0`), execute an interleaved single-pass rehearsal sweep across the fleet.
- Once the rehearsal sweep wraps, immediately resume focused bursts if $\Delta_d > 0.35$.

### 4. Telemetry & Transition Logging
- Emit explicit, human-readable notifications when focus engages, during rehearsal switches, and when parity is restored.
