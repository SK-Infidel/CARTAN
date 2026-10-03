# Sprint 500 Task List: Direct3D 12 Hardware Engine Binding & Multi-Platform Discrete GPU Enactment

- [x] **Task 1: WebGPU D3D12 Backend Selection (`src/std/wgpu.cl`)**
  - [x] Configure `backendType = 4.0` (`WGPUBackendType_D3D12`) at offset 20 in `WGPURequestAdapterOptions`.
  - [x] Implement fallback to `backendType = 0.0` (Undefined/Vulkan) if D3D12 adapter is unavailable.
  - [x] Verify adapter introspection returns `NVIDIA RTX 2000 Ada Generation Laptop GPU` with `backendType = 4.0`.

- [x] **Task 2: OpenCL NVIDIA Platform Prioritization (`src/std/gpu.cl`)**
  - [x] Inspect OpenCL platform names via `clGetPlatformInfo` (`CL_PLATFORM_NAME`).
  - [x] Prioritize platforms matching `NVIDIA` or `CUDA` over integrated Intel controllers.
  - [x] Preserve graceful fallback to secondary GPU platform if NVIDIA is absent.

- [x] **Task 3: Standalone Diagnostic & Engine Verification**
  - [x] Create `scratch/diag_gpus.car` to scan all OpenCL platforms and WebGPU adapters.
  - [x] Empirically verify `diag_gpus.exe` detects Platform 0 (NVIDIA CUDA) and D3D12 WebGPU on NVIDIA Ada.
  - [x] Recompile `geomind.exe` with D3D12 and NVIDIA prioritization and verify live execution.

- [ ] **Task 4: Regression Testing & Documentation**
  - [ ] Complete full 88-target compiler regression suite via `tools/run_affected_tests.ps1 -All`.
  - [x] Update `docs/archive/sprint_500_plan.md` and `docs/archive/sprint_500_walkthrough.md`.
  - [ ] Update `CHANGELOG.md` and `ISSUES.md`.
