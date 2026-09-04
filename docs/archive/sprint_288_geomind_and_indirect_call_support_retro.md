# Sprint 288 Retrospective: GeoMind Compilation, Indirect Function Calls & Self-Contained AI Runtime

## Executive Summary
In Sprint 288, we addressed the user inquiry `"Ok. Does geomind still compile?"` by performing an empirical diagnostic of `test/geomind/main.car`. We identified and resolved two fundamental issues: missing LLVM IR codegen for indirect function pointer calls, and missing model-domain runtime linkage for GeoMind following Sprint 287's pure Zero-C compiler decoupling. Both issues were resolved, the compiler was re-bootstrapped to 3-stage bit-for-bit parity, `geomind.exe` was compiled and verified, and all 47 compiler snapshot tests passed cleanly.

## Key Root Causes Identified & Resolved
1. **Undefined `@func` Global Symbol in LLVM IR**:
   - `cartan_rt_autograd_forward_grad` in `src/std/calculus.cl` calls `func(input_val + h)`.
   - `src/cartanc/llvm_codegen.car` previously assumed all call targets were global functions (`@name`). When calling a pointer variable/parameter, it emitted `@func`.
   - **Resolution**: Enhanced `CallExpr` in `llvm_codegen.car` to detect when the callee is not a declared function and is a local symbol in `symbols`, emitting `load ptr` and calling through the loaded register.
2. **Variable Shadowing & Dom-Tree Verification Error**:
   - In `MatchStmt` (`llvm_codegen.car:1055`), a local branch label variable was named `next_label`, shadowing the global `next_label` function in `symbols`.
   - **Resolution**: Renamed variable to `next_arm_label` and guarded indirect call generation with `is_declared_fn == 0.0`.
3. **GeoMind Model Runtime Linkage**:
   - Following Sprint 287's decoupling where `cartanc.exe` eliminated `c_runtime.c` to achieve 100% pure self-hosting, `geomind`'s 38 C extension functions (Safetensors, WebGPU/OpenCL, sockets) in `geomind_runtime.c` were missing, and `geomind_runtime.c` lacked standalone standard library headers.
   - **Resolution**: Encapsulated `geomind_runtime.c` with its own headers, types (`CartanVector`), and helpers. Configured `tools/zig_wrapper.py` to automatically include `geomind_runtime.c` when building `geomind` targets while preserving `cartanc.exe`'s 100% zero-C architecture.
4. **Native Linker Diagnostics**:
   - In `src/cartanc/main.car:452`, `system(cmd)` exit status was unchecked.
   - **Resolution**: Added validation and non-zero exit on failure.

## Empirical Verification
- **Bootstrap Fixed-Point Parity**:
  - `fc.exe /N scratch\cartanc_stage2.ll scratch\cartanc_stage3.ll` -> `FC: no differences encountered` (37,909 lines identical).
- **GeoMind Native Compilation & Execution**:
  - `cartanc.exe build test/geomind/main.car -o geomind.exe` -> compiled with exit code 0.
  - `.\geomind.exe --help` executed cleanly, printing all 10 engine modes with exit code 0.
- **Compiler Test Suite**:
  - `test/compiler_suite/run_tests.car` -> All 47 compiler snapshot test targets compiled and executed with exit code 0.
