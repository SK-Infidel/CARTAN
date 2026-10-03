# Sprint 496 Task List: True WebGPU / WGSL Native Migration & Hardware Acceleration

- [ ] **Phase 1: Compiler Core C-ABI Type Coercion (`[ISSUE-330]`)**
  - [ ] Update `src/cartanc/llvm_codegen.car` to identify `wgpu*` foreign function calls.
  - [ ] Coerce literal `0.0` to `ptr null` when expected parameter type is pointer.
  - [ ] Coerce numeric arguments to `i32` or `i64` for WebGPU flag and dimension parameters.
  - [ ] Bootstrap `cartanc.exe` through 3-stage self-hosting convergence (`stage1 -> stage2 -> stage3`).
  - [ ] Empirically verify `scratch/test_wgpu_link.car` compiles and runs with exit code 0 via `cartanc.exe`.

- [ ] **Phase 2: Pure CARTAN WebGPU Driver Module (`src/std/wgpu.cl` & `src/std/gpu.cl`) (`[ISSUE-329]`)**
  - [ ] Define standard C-ABI extern declarations for `wgpu*` functions in `src/std/wgpu.cl`.
  - [ ] Implement `wgpu_init()` with synchronous future resolution for adapter and device.
  - [ ] Implement `wgpu_alloc(size_bytes: float) -> ptr` using `wgpuDeviceCreateBuffer`.
  - [ ] Implement `wgpu_write(buf: ptr, data: ptr, size_bytes: float) -> float` using `wgpuQueueWriteBuffer`.
  - [ ] Implement `wgpu_create_pipeline(wgsl_source: string, entry_point: string) -> ptr` with genuine WGSL shader compilation via `wgpuDeviceCreateShaderModule`.
  - [ ] Implement `wgpu_dispatch(pipeline: ptr, buffers: ptr, num_buffers: float, gx: float, gy: float, gz: float) -> float`.
  - [ ] Implement `wgpu_sync()` and `wgpu_free(buf: ptr)`.
  - [ ] Update `src/std/gpu.cl` to redirect `gpu_*` calls to the pure WebGPU engine.

- [ ] **Phase 3: Hardware Verification & Regression Test Suite**
  - [ ] Verify `test/compiler_suite/test_webgpu_compute.car` (Target 23) compiles and passes with genuine WGSL.
  - [ ] Run full 88-target compiler regression suite via `tools/run_affected_tests.ps1 -All`.

- [ ] **Phase 4: GeoMind Chat Integration & Physical VRAM Execution (`[ISSUE-331]`)**
  - [ ] Wire WebGPU compute pipelines into `test/geomind/chat.cl` and `test/geomind/main.car`.
  - [ ] Mount physical VRAM buffers for Gemma inference on boot when `-gpu` is active.
  - [ ] Dispatch GPU compute during token generation.
  - [ ] Rebuild production `geomind.exe` and verify live chat generation speed and >0% GPU utilization.

- [ ] **Phase 5: Sprint Review, Changelog & Archive**
  - [ ] Author walkthrough in `docs/archive/sprint_496_walkthrough.md`.
  - [ ] Update `CHANGELOG.md` (`[8.454.0]`).
  - [ ] Mark `[ISSUE-329]`, `[ISSUE-330]`, and `[ISSUE-331]` as `[FIXED]` in `ISSUES.md`.
