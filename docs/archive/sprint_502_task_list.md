# Sprint 502 Task List: Authentic WebGPU Transformer Layer Offload & Sustained GPU Utilization

- [ ] **Task 502.1**: Author and Validate WebGPU GeGLU & GEMV Compute Shaders
  - [ ] Implement `geglu_fwd` and `down_proj_fwd` WGSL compute shaders.
  - [ ] Benchmark in standalone test `scratch/test_webgpu_geglu.car` verifying mathematical output match against CPU reference.
- [ ] **Task 502.2**: Integrate GPU Layer Acceleration into `test/geomind/chat.cl`
  - [ ] Preallocate reusable working VRAM buffers for active layer execution.
  - [ ] Connect `geomind_execute_manifold_decode_step` to dispatch GPU GeGLU kernel for each of the 42 layers.
  - [ ] Replace dead identity pass-through shaders.
- [ ] **Task 502.3**: Empirical Performance & GPU Utilization Verification
  - [ ] Run `geomind.exe -prompt "Hello" -tokens 10` and measure per-token latency and sustained GPU 1 activity.
  - [ ] Verify fluency and coherence of generated response.
- [ ] **Task 502.4**: Regression Testing & DoD
  - [ ] Run `powershell -ExecutionPolicy Bypass -File tools/run_affected_tests.ps1 -All` to ensure 88/88 test targets pass cleanly.
  - [ ] Update `CHANGELOG.md` with concise session summary.
  - [ ] Update `ISSUES.md` with [ISSUE-336] and [ISSUE-337] resolutions.
  - [ ] Save walkthrough to `docs/archive/sprint_502_walkthrough.md`.
