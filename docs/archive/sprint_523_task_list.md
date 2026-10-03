# Sprint 523 Task List
## Sparse Cortical MoE, WebGPU Batched INT4 Prefill & End-to-End Acceleration

- [x] **Gate 1: Sasaki Brainstem Router & Sparse Cortical MoE (`test/geomind/moe.cl`, `test/geomind/streams.cl`)**
  - [x] Implement `cartan_sasaki_brainstem_route_top1` in `test/geomind/moe.cl`.
  - [x] Optimize single-stream dispatch in `geomind_single_stream_forward` with zero-allocation scratch buffer.
  - [x] Verify $< 0.1\text{ ms}$ routing latency and mathematical correctness (Targets 46 & 53 passed).

- [x] **Gate 2: Conditional Layer Bypass & Pre-Conditioned Manifold Search (`test/geomind/chat.cl`)**
  - [x] Implement momentum/velocity tracking $\dot{x}_t = x_t - x_{t-1}$ in `geomind_execute_manifold_decode_step`.
  - [x] Add Fast Path layer bypass when $w^* \ge \tau_{\text{stream}}$ directly into Anchor Layer 41 with KV continuity.
  - [x] Add Complex Path $E_8$ manifold pre-conditioning when $w^* < \tau_{\text{stream}}$.
  - [x] Add MoE stream telemetry reporting to chat statistics.

- [x] **Gate 3: WebGPU Batched INT4 Sequence Prefill Engine (`src/std/transformer.cl`, `src/std/wgpu.cl`)**
  - [x] Write `geglu_int4_batch_fwd` and `down_proj_int4_batch_fwd` WGSL compute shaders.
  - [x] Implement `cartan_wgpu_dispatch_fused_geglu_down_batch_read` in `src/std/wgpu.cl`.
  - [x] Implement `cartan_transformer_dispatch_gpu_layer_batch_int4` in `src/std/transformer.cl`.
  - [x] Wire GPU resident batched INT4 prefill into `cartan_manifold_layer_forward_batch_int4`.

- [x] **Gate 4: Expanded Hopfield Speculative Multi-Token Drafting (`test/geomind/chat.cl`)**
  - [x] Implement multi-token (3-5 token) sequence candidate retrieval from Hopfield basins.
  - [x] Verify candidate bursts in a single batched pass with synchronized KV advancement.

- [x] **Gate 5: Empirical Verification & Closeout**
  - [x] Test live prompt inference on `bin/geomind.exe` measuring speedup (11.0 tok/s) and bypass ratio (96.7%).
  - [x] Run regression suite via `tools/run_affected_tests.ps1 -Sprint 523` (15/15 passed).
  - [x] Update `ISSUES.md`, `docs/ROADMAP.md`, `CHANGELOG.md`, and author `docs/archive/sprint_523_walkthrough.md`.
