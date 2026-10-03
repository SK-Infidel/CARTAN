# Sprint 496 Plan: True WebGPU / WGSL Native Migration & Hardware GPU Acceleration

## 1. Core Mission
Eliminate the faked OpenCL-based WebGPU mock in `src/std/gpu.cl` (`[ISSUE-329]`), fix the LLVM codegen argument type emission for `wgpu*` C-ABI externs (`[ISSUE-330]`), build a pure CARTAN WebGPU driver module executing authentic WGSL shaders via `wgpu_native.dll`, and integrate true WebGPU hardware acceleration into GeoMind chat inference (`[ISSUE-331]`).

Strict adherence to Rick's directives:
- **Zero Mock / Zero Fake**: Real WGSL compilation and physical GPU compute execution.
- **Pure Self-Hosting**: CARTAN remains 100% self-hosted; no C or Rust compilers in the CARTAN codebase.
- **Empirical Verification**: All 88 regression test targets passing cleanly, verified on the NVIDIA RTX 2000 Ada GPU.

---

## 2. User Stories

### Story 1: Compiler C-ABI Type Coercion for WebGPU (`cartan_compiler_engineer`)
As a language developer, I need `src/cartanc/llvm_codegen.car` to properly coerce literal `0.0` to `ptr null` and integers to `ptr`, `i32`, and `i64` for all `wgpu*` C-ABI foreign functions so that calling WebGPU native methods does not corrupt registers or trigger `0xC0000005` Access Violations.

### Story 2: Pure CARTAN WebGPU Standard Library Driver (`cartan_runtime_engineer`)
As a runtime engineer, I need `src/std/wgpu.cl` (and updated `src/std/gpu.cl`) to drive the WebGPU standard C-ABI (`wgpu_native.dll`) in pure CARTAN, compiling authentic WGSL shaders via `wgpuDeviceCreateShaderModule` and dispatching compute workgroups without hardcoded kernel substitution tables.

### Story 3: Hardware-Accelerated GeoMind Chat & Physical VRAM Execution (`cartan_architect`)
As a model architect, I need GeoMind chat mode to mount WebGPU pipelines, allocate tensors in physical GPU VRAM, and dispatch Gemma manifold and LM Head computation to the NVIDIA RTX 2000 Ada GPU, delivering sub-second token generation and genuine >0% GPU utilization.

### Story 4: Empirical QA & 88-Target Regression Verification (`cartan_qa_tester`)
As a QA engineer, I need to empirically verify `test_webgpu_compute.car` with authentic WGSL, verify live chat inference on hardware, and ensure zero regressions across all 88 test targets.

---

## 3. Definition of Done (DoD)
- [ ] `llvm_codegen.car` updated with `wgpu*` type coercion; `cartanc.exe` recompiled and self-hosted.
- [ ] `scratch/test_wgpu_link.car` compiles and executes cleanly with exit code 0 via `cartanc.exe`.
- [ ] `src/std/wgpu.cl` implemented in pure CARTAN with genuine WGSL pipeline compilation.
- [ ] `test/compiler_suite/test_webgpu_compute.car` compiles and passes using true WebGPU.
- [ ] GeoMind chat inference dispatches GPU compute and runs at physical GPU utilization on the RTX 2000 Ada.
- [ ] All 88 test targets in `test/compiler_suite/run_tests.car` pass cleanly.
- [ ] `CHANGELOG.md` updated (`[8.454.0]`).
- [ ] `ISSUES.md` updated with `[ISSUE-329]`, `[ISSUE-330]`, and `[ISSUE-331]` marked `[FIXED]`.
