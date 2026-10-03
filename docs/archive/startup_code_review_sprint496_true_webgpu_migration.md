# Startup Code Review: Sprint 496 — True WebGPU Native Migration & GPU Acceleration

## 1. Executive Summary
During Sprint 495 live testing, two critical architectural issues were identified:
1. **0% GPU Utilization**: GeoMind chat execution ran 100% on the CPU with 0% GPU utilization. The 42 Gemma layers and 262k LM Head soft-cap ran in single-threaded CARTAN loops in system RAM, resulting in multi-second per-token latencies.
2. **Faked WebGPU Abstraction (`[ISSUE-329]`)**: `src/std/gpu.cl` masqueraded as WebGPU (`gpu_create_pipeline`, etc.) while delegating to OpenCL driver calls. Crucially, `gpu_create_pipeline` completely discarded the WGSL shader string passed to it, substituting three hardcoded OpenCL C kernels via string-matching entry points.
3. **Compiler C-ABI Type Coercion Bug (`[ISSUE-330]`)**: In `src/cartanc/llvm_codegen.car`, literal `0.0` passed to `extern fn` expecting `ptr` was emitted as `double 0.0` in float registers (XMM0) for any non-OpenCL/non-SQLite extern functions (including `wgpu*`), causing `0xC0000005` Access Violations due to garbage in register `RCX`.

Per Rick's explicit architectural directive, we are eliminating the fake OpenCL substitution and executing the true WebGPU migration. CARTAN remains **100% self-hosting** with zero C and zero Rust compilers added to the CARTAN tree. We bind directly to the standard WebGPU C-ABI provided by `wgpu_native.dll`.

---

## 2. Logical Dependency Graph

```
                               ┌────────────────────────────────┐
                               │   tools/zig_wrapper.py         │
                               │   (-lwgpu_native.dll -Llib)    │
                               └──────────────┬─────────────────┘
                                              │
                                              ▼
┌─────────────────────────────────┐   ┌────────────────────────────────┐
│  src/cartanc/llvm_codegen.car   │──▶│      cartanc.exe (self-host)   │
│  (C-ABI ptr/i32/i64 type cast)  │   │      Stage 1 -> Stage 2 -> 3   │
└─────────────────────────────────┘   └──────────────┬─────────────────┘
                                                     │
                                                     ▼
                                      ┌────────────────────────────────┐
                                      │      src/std/wgpu.cl           │
                                      │  (Pure CARTAN WebGPU Driver)   │
                                      └──────────────┬─────────────────┘
                                                     │
                                                     ▼
                       ┌─────────────────────────────┴─────────────────────────────┐
                       │                                                           │
                       ▼                                                           ▼
       ┌───────────────────────────────┐                           ┌───────────────────────────────┐
       │   test/compiler_suite/        │                           │   test/geomind/chat.cl        │
       │   test_webgpu_compute.car     │                           │   test/geomind/train.cl       │
       │   (Target 23: Pure WGSL)      │                           │   test/geomind/main.car       │
       └───────────────────────────────┘                           └───────────────────────────────┘
```

---

## 3. Detailed Component Audit

### A. Compiler Core (`src/cartanc/llvm_codegen.car`)
- **Lines 3240–3300**: Hardcoded `is_cl_fn` and `is_sqlite_fn` checks determined whether literal arguments like `0.0` were converted to LLVM `ptr` or `i32`/`i64`.
- **Defect**: When calling `wgpuCreateInstance(0.0)`, `0.0` was emitted as `double 0.0` to a function declared as `@wgpuCreateInstance(ptr)`. In the Windows x64 ABI, `double` is placed in `XMM0`, leaving `RCX` (the first integer/pointer argument) undefined.
- **Fix**: Wire `is_wgpu_fn = cartan_string_starts_with(name, "wgpu")` so that pointer, integer, and buffer parameters are properly coerced to `ptr` (`null`), `i32`, and `i64`.

### B. Standard Library WebGPU Module (`src/std/wgpu.cl`)
- Implement authentic WebGPU driver functions:
  - `wgpu_init() -> float`: Creates `WGPUInstance`, requests adapter, and requests device.
  - `wgpu_alloc(size_bytes: float) -> ptr`: Invokes `wgpuDeviceCreateBuffer` with storage usage flags.
  - `wgpu_write(buffer: ptr, data: ptr, size_bytes: float) -> float`: Invokes `wgpuQueueWriteBuffer`.
  - `wgpu_read(buffer: ptr, data: ptr, size_bytes: float) -> float`: Uses staging buffer with map-read async workflow.
  - `wgpu_create_pipeline(wgsl_source: string, entry_point: string) -> ptr`: Passes actual WGSL text to `wgpuDeviceCreateShaderModule` and creates `WGPUComputePipeline`.
  - `wgpu_dispatch(pipeline: ptr, buffers: ptr, num_buffers: float, gx: float, gy: float, gz: float) -> float`: Creates bind group, encodes compute pass, and submits to queue.
  - `wgpu_sync() -> float`: Submits queue and polls for completion.
  - `wgpu_free(buffer: ptr) -> float`: Destroys buffer and releases reference.

### C. GeoMind Chat & Main Integration (`test/geomind/chat.cl`, `test/geomind/main.car`)
- Wire genuine WebGPU acceleration into `geomind_chat_generate_reply_multimodal`.
- Dispatch WGSL compute shaders on the NVIDIA RTX 2000 Ada GPU.
- Verify real VRAM allocation and active GPU compute utilization.

---

## 4. Empirical Verification Gates
- **Gate 1**: Compile and execute `scratch/test_wgpu_link.exe` with `cartanc.exe` proving zero `0xC0000005` errors.
- **Gate 2**: Compile and run `test/compiler_suite/test_webgpu_compute.car` using authentic WGSL execution via `wgpu_native.dll`.
- **Gate 3**: Verify full 88-target compiler regression suite (`tools/run_affected_tests.ps1 -All`).
- **Gate 4**: Execute live GeoMind chat with `-gpu` and verify real GPU utilization (>0%) and sub-second token generation on hardware.
