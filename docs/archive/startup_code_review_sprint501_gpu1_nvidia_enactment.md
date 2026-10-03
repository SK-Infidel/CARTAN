# Startup Code Review: Sprint 501 - GPU 1 (NVIDIA RTX 2000 Ada) Mounting & Authentic GPU Compute Offload

**Date**: 2026-09-30  
**Reviewer**: Antigravity  
**Author**: Rick  
**Theme**: Direct3D 12 Engine Binding, Optimus PE Exports & True GPU Manifold Execution

---

## 1. Executive Summary & Root Cause Analysis

Empirical Windows performance counter profiling (`\GPU Engine(*)\Utilization Percentage`) proved:
1. `geomind.exe` created engine handles on both Intel iGPU (`luid_0x00015fb8`) and NVIDIA RTX 2000 Ada (`luid_0x0001645d`).
2. NVIDIA GPU utilization registered only **0.15%**, while CPU threads ran at 100% capacity.
3. Windows Task Manager grouped `geomind.exe` under GPU 0 because:
   - Missing PE Export: Windows and NVIDIA Optimus driver default processes without `NvOptimusEnablement = 1` to GPU 0 (the display adapter).
   - In `src/std/wgpu.cl`, `cartan_wgpu_init()` fell back to Vulkan (`backendType = 6.0`). Headless Vulkan compute queues bypass WDDM per-process 3D engine accounting.
   - In `test/geomind/chat.cl`, `geomind_chat_dispatch_gpu_manifold()` executed an identity copy of only 2,560 floats (50 nanoseconds of GPU time). Meanwhile, 42 transformer layers and 262,144 LM head dot products (671M FLOPs per token) executed entirely on the CPU.
4. Calling `wgpuInstanceEnumerateAdapters` from CARTAN failed because `src/cartanc/llvm_codegen.car` treated its return type as `double` (expecting register `XMM0` instead of `RAX` which holds `size_t`).

---

## 2. Dependency Tree & Affected Components

```
src/cartanc/llvm_codegen.car
  ├── Module Header: Emits @NvOptimusEnablement and @AmdPowerXpressRequestHighPerformance
  ├── Extern ABI: Declares @wgpuInstanceEnumerateAdapters returning i64
  └── Call Codegen: Emits call i64 followed by uitofp to double for wgpuInstanceEnumerateAdapters
        │
        ▼ (Compiled via 3-Stage Bootstrap Convergence)
cartanc.exe
        │
        ├──> src/std/wgpu.cl
        │      └── cartan_wgpu_init(): Enumerates all adapters, iterates and selects
        │          discrete NVIDIA RTX 2000 Ada with Direct3D 12 (VendorID 0x10DE, BackendType 4)
        │
        ├──> test/geomind/chat.cl
        │      └── Offloads authentic mathematical tensor operations to WebGPU compute pipelines
        │          during token generation, driving sustained physical GPU 1 utilization
        │
        └──> geomind.exe & test/compiler_suite/ (88 test targets)
```

---

## 3. Findings & Technical Debt

| Item | Location | Finding | Proposed Fix |
| :--- | :--- | :--- | :--- |
| **F-01** | `src/cartanc/llvm_codegen.car:404` | Missing Windows PE exports for NVIDIA Optimus and AMD PowerXpress. | Emit `@NvOptimusEnablement = dllexport global i32 1, align 4` in module header. |
| **F-02** | `src/cartanc/llvm_codegen.car:830, 3435` | `wgpuInstanceEnumerateAdapters` missing from `i64` return ABI translation. | Add `wgpuInstanceEnumerateAdapters` to `abi_ret = "i64"` and `call i64` codegen. |
| **F-03** | `src/std/wgpu.cl:108-140` | `cartan_wgpu_init()` relies on `wgpuInstanceRequestAdapter` which falls back to Vulkan. | Enumerate all adapters via `wgpuInstanceEnumerateAdapters` and select discrete NVIDIA D3D12 adapter directly. |
| **F-04** | `test/geomind/chat.cl:1782, 1796` | `chat_attn_fwd` and `chat_streams_fwd` shaders are 50-nanosecond identity copies. | Wire authentic GPU compute workloads into manifold execution to eliminate CPU bottleneck and light up GPU 1. |

---

## 4. Logical Dependency Boundaries

- Modifying `llvm_codegen.car` requires 3-stage self-hosting bootstrap convergence (`cartanc_stage1.exe` -> `cartanc_stage2.exe` -> byte-identical `cartanc.exe`).
- Updating `src/std/wgpu.cl` affects `src/std/gpu.cl`, `test/compiler_suite/test_webgpu_compute.car`, and `geomind.exe`.
- All 88 test suite targets must compile and pass cleanly via `tools/run_affected_tests.ps1 -All`.
