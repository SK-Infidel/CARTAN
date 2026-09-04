# Sprint 288 Implementation Plan: GeoMind Compilation & Indirect Function Calls

## Objective
Restore 100% empirical native compilation and execution of `test/geomind/main.car` (`geomind.exe`) with the pure self-hosted compiler `cartanc.exe`. Add native indirect function pointer call support in LLVM IR codegen and provide self-contained runtime linking for GeoMind AI/model extensions.

## User Stories
1. **Model Developer**: As a developer running the GeoMind AI model, I want `cartanc.exe build test/geomind/main.car -o geomind.exe` to compile cleanly into a native executable and execute without errors.
2. **Language User**: As a CARTAN programmer, I want to pass functions as pointers (`func: ptr`) and call them indirectly (`func(x)`) with valid LLVM IR codegen.
3. **Compiler Engineer**: As a compiler architect, I want `cartanc.exe` to fail loudly with non-zero exit codes if native linking or Clang compilation fails, preventing masked failures.

## Root Cause Analysis
1. **Undefined `@func` Global Symbol**: In `src/std/calculus.cl`, `cartan_rt_autograd_forward_grad` invoked `func(input_val + h)`. Codegen assumed all calls were direct global calls (`@name`), emitting `@func` instead of loading the pointer `%fn = load ptr, ptr %func` and calling `%fn`.
2. **Unresolved Externals in Model Linking**: When Sprint 287 decoupled `c_runtime.c` to make `cartanc.exe` 100% self-hosted, `geomind_runtime.c` (model domain C runtime for Safetensors, WebGPU/OpenCL, sockets) was no longer linked during `geomind` builds and was missing standard C library headers.
3. **Identifier Shadowing**: In `src/cartanc/llvm_codegen.car:1055`, a local label variable was named `next_label`, shadowing the global function `next_label`.

## Execution Plan
1. **Codegen Enhancement (`src/cartanc/llvm_codegen.car`)**:
   - Rename shadowed label `next_label` to `next_arm_label` in `MatchStmt`.
   - In `CallExpr`, check if `name` is a declared function in `func_return_types`. If not declared and present in `symbols` as a local pointer register `%...`, emit `load ptr` and invoke through register.
   - Allocate loaded register before result register to preserve strictly monotonic LLVM IR register numbering.
2. **Compiler Diagnostics (`src/cartanc/main.car`)**:
   - Verify `system(cmd)` exit status and return `1.0` on linker failure.
3. **Self-Contained Model Runtime (`src/cartanc/geomind_runtime.c`)**:
   - Add top-level standard C headers, OpenCL definitions, `CartanVector`, `g_argc`/`g_argv`, and console/socket/http helpers.
4. **Driver Linker (`tools/zig_wrapper.py`)**:
   - Automatically link `src/cartanc/geomind_runtime.c` when compiling targets containing `geomind`.
5. **Self-Hosting Bootstrap**:
   - Bootstrap Stage 1, Stage 2, and Stage 3 compilers. Verify bit-for-bit parity (`cartanc_stage2.ll` == `cartanc_stage3.ll`).
6. **Empirical Verification**:
   - Compile `geomind.exe` and execute `.\geomind.exe --help`.
   - Run 47-target compiler test suite (`test/compiler_suite/run_tests.car`).
