# Sprint 501 Plan: Deterministic GPU 1 (NVIDIA RTX 2000 Ada) Mounting & Authentic GPU Manifold Execution

**Date**: 2026-09-30  
**Supervisor**: Antigravity  
**Author**: Rick  
**Theme**: Direct3D 12 Engine Binding, Optimus PE Exports & True GPU Manifold Execution

---

## 1. Sprint Goal
Eliminate hybrid laptop GPU misallocation by exporting PE Optimus symbols, implementing deterministic NVIDIA Direct3D 12 adapter selection in pure CARTAN WebGPU standard library via `wgpuInstanceEnumerateAdapters`, and offloading genuine mathematical compute workloads in `geomind.exe` so Windows Task Manager actively tracks sustained compute on GPU 1 (NVIDIA RTX 2000 Ada) with zero compiler regressions across all 88 test suite targets.

---

## 2. User Stories
1. **As a developer (Rick)**, I want `geomind.exe` to mount GPU 1 (NVIDIA RTX 2000 Ada Generation Laptop GPU) under Direct3D 12 so that Task Manager and DXGKRNL accurately associate the process with the discrete GPU.
2. **As a language architect**, I want `cartanc.exe` to automatically emit `@NvOptimusEnablement` PE exports and correctly map `wgpuInstanceEnumerateAdapters` C-ABI so all CARTAN binaries default to discrete GPU power on Windows.
3. **As a performance engineer**, I want authentic GPU compute shaders executing on the NVIDIA GPU during inference so that the CPU is relieved of compute bottlenecks and GPU utilization is visibly reflected in Task Manager.

---

## 3. Implementation Strategy

### Stage 1: Compiler Core Squad (`cartan-compiler-engineer`)
- In `src/cartanc/llvm_codegen.car`:
  - Module Header: Emit `@NvOptimusEnablement = dllexport global i32 1, align 4` and `@AmdPowerXpressRequestHighPerformance = dllexport global i32 1, align 4`.
  - Extern ABI: Register `wgpuInstanceEnumerateAdapters` with parameter types `ptr, ptr, ptr` and return type `i64`.
  - Call Translation: Handle `wgpuInstanceEnumerateAdapters` via `call i64` + `uitofp to double`.
- Execute 3-stage self-hosting bootstrap fixpoint convergence to produce updated `cartanc.exe`.

### Stage 2: Runtime Squad (`cartan_runtime_engineer`)
- In `src/std/wgpu.cl`:
  - Declare `extern fn wgpuInstanceEnumerateAdapters(instance: ptr, options: ptr, adapters: ptr) -> float;`.
  - In `cartan_wgpu_init()`:
    1. Query total adapters via `wgpuInstanceEnumerateAdapters(g_wgpu_instance, 0.0, 0.0)`.
    2. Allocate buffer `malloc(total_adapters * 8.0)` and populate adapter list.
    3. Loop through adapters, reading `vendorID` and `backendType`.
    4. Select `vendorID == 4318.0` (0x10DE) with `backendType == 4.0` (D3D12), with graceful fallback to `vendorID == 4318.0` (Vulkan) and fallback to `adapterType == 1.0` (Discrete).
    5. Request device and queue directly on selected adapter.

### Stage 3: Architecture & Model Squad (`cartan-architect`)
- In `test/geomind/chat.cl`:
  - Offload genuine mathematical tensor calculations to WebGPU compute shaders during prefill and decode passes.
  - Ensure zero mock / zero simulation compliance: all GPU dispatches execute real linear algebra, Lie group projections, or attention calculations.

### Stage 4: QA & Verification Squad (`cartan-qa-tester`)
- Run `scratch/test_geomind_gpu_engine.ps1` to empirically measure GPU 1 engine activity.
- Run `tools/run_affected_tests.ps1 -All` to guarantee 100% pass rate across all 88 test suite targets.
