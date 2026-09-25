# Sprint 423 Plan: Dynamic $\gamma$ Scaling & Adaptive Axiomatic Attractor Stabilization

## Objective
Implement closed-form, entropy- and surprisal-aware dynamic scaling of the Hopfield convex injection parameter $\gamma$ ($\text{hidden} \leftarrow (1-\gamma)\,\text{hidden} + \gamma\,\text{retrieved}$). Rather than statically fixing $\gamma = 0.10$, dynamically modulate coupling across both forward and backward GPU pipelines according to domain strictness, current entropy $H$, prediction certainty $C$, and localized loss surges $\frac{L}{\text{EMA}(L)}$, clamping safely within $[\gamma_{\min}, \gamma_{\max}]$.

---

## Technical Design & Mathematical Model

### 1. Mathematical Formulation
$$\gamma(D, H, C, L, L_{\text{EMA}}) = \text{clamp}\left(\gamma_{\text{base}}(D) \cdot \mu_{\text{uncertainty}}(H, C) \cdot \mu_{\text{surge}}(L, L_{\text{EMA}}), \gamma_{\min}, \gamma_{\max}\right)$$

1. **Domain Baseline Factor $\gamma_{\text{base}}(D)$**:
   - Domain 0 (System Core / Universal Physical Invariants): $0.14$
   - Domain 1 (Physics Sim / Mechanics Invariants): $0.12$
   - Domain 2 (Topology & Differential Forms): $0.12$
   - Domain 3 (Complexity Theory & Automata): $0.10$
   - Domain 4 (Biological Systems): $0.08$
   - Domain 5 (Causal Taxonomy): $0.08$

2. **Uncertainty Multiplier $\mu_{\text{uncertainty}}(H, C)$**:
   - Reference baseline: $H_{\text{ref}} = 6.0\text{ bits}$, $C_{\text{ref}} = 0.10$ ($10\%$).
   - When entropy is elevated ($H > 6.0$) or certainty drops ($C < 0.10$):
     $$\Delta H_{\text{rel}} = \frac{H - H_{\text{ref}}}{H_{\text{ref}}}, \quad \Delta C_{\text{rel}} = \frac{C_{\text{ref}} - C}{C_{\text{ref}}}$$
     $$\mu_{\text{uncertainty}} = 1.0 + 0.5 \cdot \text{clamp}(\Delta H_{\text{rel}}, -0.5, 1.5) + 0.5 \cdot \text{clamp}(\Delta C_{\text{rel}}, -0.5, 1.0)$$
   - When entropy is low ($H < 4.5$) and certainty is high ($C > 0.20$), $\mu_{\text{uncertainty}}$ drops smoothly down to $0.40 - 0.50$ (preventing attractor distortion).

3. **Loss Surge Multiplier $\mu_{\text{surge}}(L, L_{\text{EMA}})$**:
   - If $L_{\text{EMA}} > 0$ and $L > 1.15 \cdot L_{\text{EMA}}$ (sudden out-of-distribution spike or contradiction):
     $$\mu_{\text{surge}} = 1.0 + \min\left(1.0, \frac{L - 1.15 \cdot L_{\text{EMA}}}{L_{\text{EMA}}}\right)$$
   - Otherwise $\mu_{\text{surge}} = 1.0$.

4. **Safety Bounds**:
   - $\gamma_{\min} = 0.02$ (guarantees manifold continuity without locking).
   - $\gamma_{\max} = 0.35$ (prevents overwriting recurrent sequence representations).

---

## Pipeline & Kernel Integration

### 1. New Module: `src/std/dynamic_gamma.cl`
- `struct DynamicGammaConfig { base_gamma: float; min_gamma: float; max_gamma: float; ent_ref: float; cert_ref: float; }`
- `dynamic_gamma_create(base_gamma, min_gamma, max_gamma, ent_ref, cert_ref) -> DynamicGammaConfig`
- `dynamic_gamma_compute(cfg, domain_idx, cur_entropy, cur_certainty, cur_loss, ema_loss) -> float`

### 2. GPU Kernel Parameter Updates (`test/geomind/train.cl`)
- On each chunk launch:
  ```cartan
  let active_gamma = dynamic_gamma_compute(g_gamma_cfg, active_d, cur_ent, cur_cert / 100.0, c_loss, ema_train_loss);
  cartan_gpu_set_arg_f32(g_pipe_hopfield_inject, 5.0, active_gamma);
  cartan_gpu_set_arg_f32(g_pipe_hopfield_backward, 6.0, active_gamma);
  ```
- Expose `g_active_hopfield_gamma` to biological telemetry and console logs.

---

## Verification Plan

### Test Gates (`test/geomind/nses/test_sprint10_dynamic_gamma.car`)
1. **TS-10.1**: Domain Base Scaling (Domain 0/1 high baseline vs Domain 4/5 flexible baseline).
2. **TS-10.2**: Uncertainty Modulation (Entropy/Certainty sweep verifying smooth scaling and clamping).
3. **TS-10.3**: Loss Surge Response (Loss spikes trigger instantaneous attractor amplification $\le \gamma_{\max}$).
4. **TS-10.4**: Sub-Microsecond Evaluation Latency ($< 0.05\text{ }\mu\text{s}$ per chunk).
