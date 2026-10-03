# Sprint 523 Plan: Sparse Cortical MoE, WebGPU Batched INT4 Prefill & End-to-End On-Device Acceleration

## 1. Sprint Objective & Scope
Sprint 523 transitions the GeoMind neural architecture from a monolithic dense forward pass into a true **Sparse Cortical Mixture-of-Experts (MoE)** architecture driven by the **Sasaki Brainstem Router**, while upgrading sequence prefill to the GPU-resident INT4 weights and expanding Hopfield speculative drafting.

---

## 2. Sprint Architecture & Milestones

### Gate 1: Sasaki Brainstem Router & Sparse Cortical MoE (`test/geomind/moe.cl`, `test/geomind/streams.cl`)
- Implement `cartan_sasaki_brainstem_route_top1(pos, mom, temp)` in `test/geomind/moe.cl` to return dominant stream index and confidence weight directly in $< 0.1\text{ ms}$.
- Ensure `geomind_multistream_forward(x, stream_idx)` in `test/geomind/streams.cl` supports zero-allocation in-place / scratch execution for single stream passes.

### Gate 2: Conditional Layer Bypass & Pre-Conditioned Manifold Search (`test/geomind/chat.cl`)
- Track dynamic velocity $\dot{x}_t = x_t - x_{t-1}$ across autoregressive decode steps in `geomind_execute_manifold_decode_step`.
- Fast Path: When dominant stream confidence $w^* \ge \tau_{\text{stream}}$ (default $\tau = 0.35$):
  - Execute specialized cortical stream ($\mathcal{O}(D)$, $< 0.05\text{ ms}$).
  - Route directly to Anchor Layer 41 ($\sim 1.5\text{ ms}$ on GPU INT4), completely bypassing layers 0..40.
  - Latency: $< 1.6\text{ ms}$ (~50x faster than full 42-layer pass).
- Complex Path: When $w^* < \tau_{\text{stream}}$:
  - Blend stream output into $x_t$ as an $E_8$ manifold pre-conditioning anchor ($\alpha = 0.10$).
  - Execute full manifold with thermodynamic early exit.
- Telemetry: Track stream dispatch distribution and bypass ratio in chat statistics.

### Gate 3: WebGPU Batched INT4 Sequence Prefill Engine (`src/std/transformer.cl`)
- Author WGSL compute shaders `geglu_int4_batch_fwd` and `down_proj_int4_batch_fwd` for batched prompt tokens.
- Implement `cartan_transformer_dispatch_gpu_geglu_batch_int4` in `src/std/transformer.cl`.
- Route batched INT4 sequence prefill on GPU resident weights when `is_int8 == 2.0 && g_trans_gpu_int4_ready == 1.0`.

### Gate 4: Expanded Hopfield Speculative Multi-Token Drafting (`test/geomind/chat.cl`)
- Expand continuous Hopfield burst drafting from single-token to 3–5 candidate tokens.
- Verify candidate bursts in a single batched prefill pass, rolling back only rejected suffixes.

### Gate 5: Empirical Verification & Regression Prevention
- Build and run parity tests for stream routing and GPU batched prefill.
- Rebuild `bin/geomind.exe` and test live prompt generation measuring throughput and bypass ratio.
- Run affected regression suite (`tools/run_affected_tests.ps1 -Sprint 523`).
- Update `CHANGELOG.md`, `ISSUES.md`, `docs/ROADMAP.md`, and author `docs/archive/sprint_523_walkthrough.md`.
