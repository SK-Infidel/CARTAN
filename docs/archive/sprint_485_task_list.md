# Sprint 485 Task List: Pure Native Cross-Platform Readline & Linux Compatibility

## Gate 1: LLVM Codegen `getchar()` Support & Bootstrap Convergence
- [x] **Task 1.1**: Register `getchar` in `func_return_types` (`"double"`) in `src/cartanc/llvm_codegen.car`.
- [x] **Task 1.2**: Add `add_builtin_extern` for `getchar` (`"declare i32 @getchar()\n"`) in `src/cartanc/llvm_codegen.car`.
- [x] **Task 1.3**: Wire `getchar` to the `i32` call / `sitofp` conversion branch in `src/cartanc/llvm_codegen.car:3312`.
- [x] **Task 1.4**: Declare `extern fn getchar() -> float;` in `src/cartanc/core_runtime.car`.
- [x] **Task 1.5**: Rebuild compiler through 3-stage bootstrap fixpoint convergence (`bin/cartanc.exe`, SHA256: 8E9B12DFE37B2DCC733C3CF56A074A378DB7EBE82D7329BE17A9DCF912737DE2).

## Gate 2: Pure Native CARTAN `cartan_read_line()` Implementation
- [x] **Task 2.1**: Implement `cartan_read_line()` in `src/cartanc/core_runtime.car` using `getchar()`, `fflush()`, `calloc()`, BOM stripping, and whitespace trimming.
- [x] **Task 2.2**: Remove `extern fn c_cartan_read_line() -> string;` from `core_runtime.car`.
- [x] **Task 2.3**: Verify `test/compiler_suite/test_read_line.car` builds and executes cleanly with piped input.

## Gate 3: Elimination of `cartan_native_io.c` & Cross-Platform Linker
- [x] **Task 3.1**: Delete `src/std/cartan_native_io.c` from the repository (zero custom C files remain).
- [x] **Task 3.2**: Remove references to `cartan_native_io.c` in `tools/zig_wrapper.py`.
- [x] **Task 3.3**: Update `tools/zig_wrapper.py` with cross-platform target detection (linking Windows libraries vs Linux libraries).

## Gate 4: Linux Cross-Compilation & Regression Suite Verification
- [x] **Task 4.1**: Verify compiling a CARTAN program for Linux (`x86_64-linux-gnu`) produces a valid ELF binary (`7F-45-4C-46`) with zero unresolved symbols.
- [x] **Task 4.2**: Recompile `geomind.exe` and verify chat inference `"What is the capital of Iran"` -> `"The capital of Iran is **Tehran**."`.
- [x] **Task 4.3**: Run the full 87-target compiler regression suite (`tools/run_affected_tests.ps1 -All`: 87 Passed, 0 Failed).
- [x] **Task 4.4**: Synchronize all production binaries (`cartanc.exe`, `bin/cartanc.exe`, `geomind.exe`, `test/geomind/geomind.exe`).
- [x] **Task 4.5**: Update `CHANGELOG.md`, `ISSUES.md`, and write `docs/archive/sprint_485_walkthrough.md`.
