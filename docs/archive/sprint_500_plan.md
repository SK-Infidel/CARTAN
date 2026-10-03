# Sprint 500 Plan: Direct3D 12 Hardware Engine Binding & Multi-Platform Discrete GPU Enactment

## Sprint Goal
Enforce deterministic binding of physical compute workloads to the discrete NVIDIA RTX 2000 Ada Generation Laptop GPU across both WebGPU and OpenCL runtimes on dual-adapter hybrid laptop architectures, ensuring genuine hardware utilization and DXGKRNL engine tracking in Windows Task Manager.

## User Stories
1. **US-500.1 (WebGPU D3D12 Hardware Engine Binding)**: As a runtime engineer, I want `cartan_wgpu_init` to configure `backendType = WGPUBackendType_D3D12` (4.0) alongside `powerPreference = WGPUPowerPreference_HighPerformance` (2.0) so that WebGPU command queues are allocated directly on the discrete NVIDIA GPU and tracked by Windows Task Manager under the NVIDIA GPU engine.
2. **US-500.2 (OpenCL NVIDIA Platform Prioritization)**: As a runtime engineer, I want `cartan_gpu_init` in `src/std/gpu.cl` to inspect OpenCL platform names and prioritize NVIDIA CUDA / discrete GPU devices over integrated Intel graphics, preventing dual-GPU platform collisions.
3. **US-500.3 (Zero-Regression Empirical Verification)**: As a QA engineer, I want standalone GPU diagnostics, test target execution, live `geomind.exe` startup telemetry, and the full 88-target compiler regression suite to verify clean compilation and execution.

## Mathematical & Architectural Invariants
1. **DirectX Graphics Kernel (DXGKRNL) Accounting**: On Windows, headless Vulkan compute allocations on hybrid laptops do not register under the primary WDDM GPU 3D engine in Task Manager. Explicit Direct3D 12 backend allocation ensures native OS GPU engine accounting.
2. **OpenCL Platform Precedence**: On multi-platform Windows systems, Platform 0 is frequently Intel OpenCL Graphics. Scanning platforms for `NVIDIA` or `CUDA` guarantees deterministic hardware binding to the discrete RTX 2000 Ada GPU.
3. **Zero-Mock Discipline**: All compute operations execute authentic calculations and genuine physical GPU hardware dispatches.
