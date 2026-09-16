# Sprint 335: Freestanding GPU Compute Subsystem & 0% GPU Bottleneck Elimination

## Objective
Eliminate 0% GPU utilization during GeoMind neural network training by constructing a pure native CARTAN OpenCL compute subsystem that drives the physical NVIDIA RTX 2000 Ada Generation Laptop GPU without any C runtime or Rust dependencies.

## Architecture & Dependency Flow
```
┌────────────────────────────────────────────────────────┐
│  src/cartanc/llvm_codegen.car                          │
│  - Typed memory builtins: f32, i32, i64 load/store     │
│  - C-ABI Lowering: cl_int -> call i32, clCreate* -> ptr│
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│  src/std/gpu.cl                                        │
│  - OpenCL.dll driver FFI bindings                      │
│  - NVIDIA Ada GPU detection (CL_DEVICE_TYPE_GPU)       │
│  - Physical VRAM alloc & JIT kernel compilation        │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│  test/geomind/train.cl                                 │
│  - Persistent VRAM weights (26.2 MB)                   │
│  - geomind_gemv_forward kernel (2560 threads)          │
│  - geomind_sgd_backward kernel (2560 threads)          │
│  - Host <-> GPU bidirectional synchronization          │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│  Synchronized Deployment (4 Targets)                   │
│  - ./geomind.exe, bin/, build/, test/geomind/          │
│  - Verified 39% compute utilization via nvidia-smi     │
└────────────────────────────────────────────────────────┘
```

## Work Items
1. [x] Implement typed memory load/store builtins in LLVM codegen (`cartan_f32_at`, `cartan_set_f32`, `cartan_i32_at`, `cartan_set_i32`, `cartan_i64_at`, `cartan_set_i64`).
2. [x] Fix OpenCL C-ABI integer return lowering for all `cl*` driver calls in `llvm_codegen.car`.
3. [x] Replace CPU software fallback in `src/std/gpu.cl` with bare-metal OpenCL driver bindings.
4. [x] Fix buffer sizing and overflow protection in `src/std/hub.cl` (`[ISSUE-084]`).
5. [x] Implement persistent GPU VRAM weights (`g_buf_cortical_weights`), forward GEMV kernel, and backward SGD kernel in `test/geomind/train.cl`.
6. [x] Recompile compiler and `geomind.exe`; synchronize all 4 binaries.
7. [x] Empirically verify active compute process and >0% GPU utilization via `nvidia-smi`.
