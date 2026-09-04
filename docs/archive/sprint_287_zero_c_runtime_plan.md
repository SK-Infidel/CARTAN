# Sprint 287 Implementation Plan: 100% Zero-C Runtime Decoupling

## Objective
Sever all dependencies on C source code (`c_runtime.c`) from the compiler build, JIT, and linker pipelines. Emit all 13 runtime primitives directly as native LLVM IR in `src/cartanc/llvm_codegen.car`, achieving 100% pure freestanding self-hosting CARTAN.

## User Stories
1. **Developer**: As a CARTAN developer, I want `cartanc.exe` to compile `.car` programs directly into pure `.ll` and link directly against system libc/DLLs without needing any `.c` source files or C runtime wrappers.
2. **Compiler Architecture**: As the compiler engine, I want runtime data structures (`CartanTree`, string utils, number formatters) to exist natively in LLVM IR with exact bit-for-bit parity to eliminate double-conversion traps.
3. **Self-Hosting Parity**: As a self-hosting language, Stage 2 and Stage 3 compilers built without C runtime code must achieve bit-for-bit identical LLVM IR (`cartanc_stage2.ll` == `cartanc_stage3.ll`).

## Affected Components
- `tools/zig_wrapper.py`: Ignore/drop `c_runtime.c` arguments and reset Clang mode via `-x none` after `.ll`.
- `src/cartanc/llvm_codegen.car`:
  - Add libc extern declarations (`realloc`, `strlen`, `memcpy`, `strncmp`, `snprintf`, `strchr`, `strncpy`, `llvm.floor.f64`).
  - Add format string constants to `@.globals`.
  - Emit native LLVM IR implementations of the 13 runtime primitives (`@cartan_c_tree_*`, `@c_cartan_string_char_at`, `@cartan_c_memcpy`, `@cartan_c_strncmp`, `@cartan_c_ptr_add`, `@cartan_c_int_to_string`, `@cartan_c_float_to_string`, `@cartan_c_sprintf_hex_byte`).
- `src/cartanc/core_runtime.car`:
  - Update `cartan_jit_eval` to invoke `python tools/zig_wrapper.py` without `c_runtime.c`.
- `src/cartanc/main.car`:
  - Remove `src/cartanc/c_runtime.c` auto-sync (lines 391-394).
  - Remove `src/cartanc/c_runtime.c` from link command in line 455.
- `src/cartanc/c_runtime.c`: Rename to `src/cartanc/c_runtime.c.deprecated`.

## Verification Steps
1. Bootstrap Stage 1 compiler using root `cartanc.exe`.
2. Bootstrap Stage 2 compiler using Stage 1 compiler.
3. Bootstrap Stage 3 compiler using Stage 2 compiler.
4. Diff `scratch/cartanc_stage2.ll` vs `scratch/cartanc_stage3.ll` using `fc.exe` to prove bit-for-bit fixed-point parity.
5. Promote Stage 3 compiler to root `cartanc.exe`.
6. Run full regression suite (`test/compiler_suite/run_tests.car`) and verify 47/47 test targets pass with exit code 0.
7. Record git issue, update `CHANGELOG.md`, and save retrospective.
