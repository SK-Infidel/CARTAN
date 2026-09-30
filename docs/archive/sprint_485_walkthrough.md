# Sprint 485 Walkthrough: Pure Native Readline, Linux Compatibility & Complete C Runtime Elimination

## 1. Executive Summary
In Sprint 485, we addressed Rick's inquiries (*"Why do we need to do readline in c in cartan?"* and *"Alright. Make sure it's compatible with linux too."*):
1. **100% C Runtime Elimination**: We eliminated the last remaining custom C runtime file in CARTAN (`src/std/cartan_native_io.c`). Zero custom C source files remain in the language.
2. **Pure Native Cross-Platform Readline**: Implemented `cartan_read_line()` directly in `src/cartanc/core_runtime.car` in pure CARTAN using standard library primitives (`getchar()`, `fflush()`, `calloc()`, BOM stripping, whitespace trimming).
3. **Cross-Platform Linux & Windows Compatibility**: Purged Win32-specific APIs (`CreateFileA`, `CreateFileMappingA`, `MapViewOfFile`, `CloseHandle`, `UnmapViewOfFile`) from LLVM codegen. Re-implemented `cartan_mmap_file` and `cartan_munmap_file` using ISO C standard library operations (`fopen`, `fseek`, `ftell`, `malloc`, `fread`, `fclose`, `free`).
4. **Target-Aware Linker**: Updated `tools/zig_wrapper.py` with dynamic target branching (`-target x86_64-linux-gnu` with `-lm -lpthread -ldl` vs Windows MSVC with Win32 libraries).
5. **Verified ELF Linux Executable**: Empirically proved cross-compilation targeting Linux (`x86_64-linux-gnu`) generates valid Linux ELF binaries (`7F-45-4C-46`) with zero unresolved symbols.
6. **3-Stage Bootstrap Convergence**: Confirmed bit-for-bit fixpoint convergence across stages (`SHA256: 8E9B12DFE37B2DCC733C3CF56A074A378DB7EBE82D7329BE17A9DCF912737DE2`).
7. **Empirical Verification**: Tested interactive/piped readline execution, verified empirical neural chat inference (`"What is the capital of Iran"` -> `"The capital of Iran is **Tehran**."`), and passed all 87/87 compiler regression test targets.

---

## 2. Changes by Component

### A. Compiler Core (`src/cartanc/llvm_codegen.car`)
- Registered `getchar` return type as `"double"` in `func_return_types`.
- Added `add_builtin_extern` declaration for `getchar` (`"declare i32 @getchar()\n"`).
- Wired `getchar` to the `i32` call translation branch (`sitofp i32 %res to double`).
- Removed all Win32 extern declarations (`CreateFileA`, `CreateFileMappingA`, `MapViewOfFile`, `CloseHandle`, `UnmapViewOfFile`).
- Removed hardcoded Win32 LLVM IR emission for `cartan_mmap_file` and `cartan_munmap_file`.

### B. Standard Runtime Kernel (`src/cartanc/core_runtime.car`)
- Declared `extern fn getchar() -> float;`.
- Implemented `cartan_read_line() -> string` in pure native CARTAN:
  - Consumes characters using `getchar()` until `\n` or EOF.
  - Strips UTF-8 BOM (`0xEF, 0xBB, 0xBF`) on line start.
  - Trims trailing carriage returns (`\r`).
  - Dynamically manages buffer memory with `calloc()`.
- Implemented `cartan_mmap_file(path: string) -> ptr` and `cartan_munmap_file(view: ptr) -> float` in pure CARTAN using ISO C primitives (`fopen`, `fseek`, `ftell`, `malloc`, `fread`, `fclose`, `free`).

### C. Build Toolchain & Linker (`tools/zig_wrapper.py`)
- Removed all compilation steps for `src/std/cartan_native_io.c`.
- Added target-aware compiler selection:
  - Linux: uses `zig cc -target x86_64-linux-gnu -O2 -mavx2 -mfma` linking `-lm -lpthread -ldl`.
  - Windows: uses Intel oneAPI clang linking Win32 libraries.
- Handled `.ll` input arguments appropriately for Zig vs Clang.

### D. File Purge
- Permanently deleted [`src/std/cartan_native_io.c`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/cartan_native_io.c).

---

## 3. Empirical Verification Results

### 1. Piped Standard Input Verification
Command:
```powershell
cmd /c "echo Pure CARTAN Readline on Windows and Linux | .\build\test_read_line.exe"
```
Output:
```
Prompt> You typed: Pure CARTAN Readline on Windows and Linux
```
Exit Code: 0.

### 2. Linux Cross-Compilation Verification
Command:
```powershell
zig cc -target x86_64-linux-gnu build/test_read_line.ll -o build/test_read_line_linux -lm -lpthread -ldl
```
Magic Byte Header:
```
7F-45-4C-46 (\x7fELF)
```
Exit Code: 0. Valid 64-bit Linux ELF binary with zero unresolved symbols.

### 3. Empirical Chat Generation (`geomind.exe`)
Command:
```powershell
.\build\geomind.exe --chat -prompt "What is the capital of Iran" --no-expert-priming -temp 0.0 -tokens 20
```
Output:
```
GeoMind> The capital of Iran is **Tehran**. [Hopfield Energy Minimum: -0.269911]
[Hybrid Ensemble Discriminator] Trajectory Confidence Score: 0.667681
```
Exit Code: 0.

### 4. 87-Target Compiler Regression Suite
Command:
```powershell
powershell -ExecutionPolicy Bypass -File tools/run_affected_tests.ps1 -All
```
Result:
```
================================================================================
  REGRESSION RUN SUMMARY: 87 Passed, 0 Failed (204.08s total)
================================================================================
```
Exit Code: 0. Zero regressions across all 87 test targets.

### 5. 3-Stage Bootstrap Fixpoint SHA256 Hashes
```
Algorithm  Hash                                                              Path
---------  ----                                                              ----
SHA256     8E9B12DFE37B2DCC733C3CF56A074A378DB7EBE82D7329BE17A9DCF912737DE2  bin/cartanc_fresh.ll
SHA256     8E9B12DFE37B2DCC733C3CF56A074A378DB7EBE82D7329BE17A9DCF912737DE2  bin/cartanc_stage3.ll
```
Bit-for-bit fixpoint convergence achieved.
