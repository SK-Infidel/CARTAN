# Sprint 307: Sasaki Tangent Bundle Phase-Space Brainstem Router & Dynamic 8-Stream Cortical Trajectory Routing

## 1. Objective & Mathematical Foundation
Activate the dormant Sasaki Phase-Space Brainstem Router (`test/geomind/moe.cl`) and wire tangent bundle momentum tracking into 42-layer manifold inference (`test/geomind/chat.cl`, `src/cartanc/geomind_runtime.c`, `test/geomind/streams.cl`).

### Tangent Bundle Phase-Space Metric
For state $(h, \dot{h}) \in TM = M \times T_x M$ with momentum $\dot{h}_t = h_t - h_{t-1}$:
$$E_s = \frac{1}{320} \sum_{d=320s}^{320s+319} \left( h[d]^2 + \dot{h}[d]^2 \right), \quad s \in \{0..7\}$$
$$z_s = \sqrt{E_s} + \frac{\sum_d h[d]\dot{h}[d]}{\|h_s\| \|\dot{h}_s\| + \epsilon}$$
$$w_s = \frac{\exp(z_s / T)}{\sum_{k=0}^7 \exp(z_k / T)}, \quad \text{mix}_s = \text{clamp}(0.10 \times (8.0 \times w_s), 0.02, 0.65)$$

## 2. Implementation Tasks
1. **Runtime Kernels (`src/cartanc/geomind_runtime.c`)**:
   - `cartan_sasaki_brainstem_route(pos, mom, stream_weights, dim, temp)`
   - `cartan_apply_8_lie_streams_routed(h, dim, stream_weights)`
   - `cartan_apply_8_lie_streams_routed_vec(hidden_ptr, weights_ptr)`
   - `e8_attention_forward_step_with_momentum(hidden_ptr, mom_ptr, temp)`
2. **GeoMind Core (`test/geomind/`)**:
   - `test/geomind/moe.cl`: `geomind_sasaki_stream_routing(pos, mom)`
   - `test/geomind/streams.cl`: `geomind_streams_manifold_forward_routed(x, weights)`
   - `test/geomind/chat.cl`: Tangent bundle momentum tracking $\dot{h}_t = h_t - h_{t-1}$ across token generation and reasoning pass.
3. **Regression Test Target 59 (`test/compiler_suite/test_sasaki_brainstem_routing.car`)**:
   - Test 5 assertions: momentum computation, Sasaki energy calculation, Softmax normalization, 8-stream routed pass, and 42-layer manifold step.
   - Register Target 59 in `test/compiler_suite/run_tests.car`.
4. **Documentation & Retrospective**:
   - Update `docs/ROADMAP.md` (Phase 65).
   - Mark `[ISSUE-058]` resolved in `ISSUES.md`.
   - Update `CHANGELOG.md` and save retrospective.
