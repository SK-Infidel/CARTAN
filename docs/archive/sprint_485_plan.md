# Sprint 485 Plan: Pure Native Cross-Platform Readline & Linux/Windows Runtime Purity

## Objective
Eliminate the last remaining C runtime file (`src/std/cartan_native_io.c`) by implementing `cartan_read_line()` in 100% pure native CARTAN using ISO C standard library primitives (`getchar()`, `fflush()`, `calloc()`), ensuring bit-accurate cross-platform compatibility across Windows and Linux, and establishing Linux-ready memory mapping in LLVM codegen.

---

## Architecture & Cross-Platform Design

### 1. Pure CARTAN Readline via ISO C `getchar()`
- **Portability**: `getchar(void)` is part of the C standard library across all platforms (Windows UCRT/MSVCRT, Linux glibc/musl, macOS libSystem). It requires zero platform-specific headers or runtime macros (`stdin`).
- **Algorithm**:
  1. Call `cartan_flush(0.0)` to flush pending stdout prompts.
  2. Dynamically allocate a 4096-byte line buffer via `calloc(4096.0, 1.0)`.
  3. Autoregressively consume characters via `getchar()` until `\n`, `\r`, or EOF (`-1`).
  4. Return `"exit"` if EOF is encountered on empty input.
  5. Strip UTF-8 BOM (`0xEF, 0xBB, 0xBF`) if present.
  6. Trim leading and trailing whitespace and control characters.
  7. Return null-terminated string pointer.

### 2. Elimination of `src/std/cartan_native_io.c`
- With `c_cartan_read_line` replaced by native `cartan_read_line()`, `cartan_native_io.c` becomes completely obsolete.
- Delete `src/std/cartan_native_io.c` and remove its invocation from `tools/zig_wrapper.py`.

### 3. Linux Cross-Platform Linker & Mmap Compatibility
- In `tools/zig_wrapper.py`, detect whether the compile target is Linux (`x86_64-linux-gnu`) or Windows (`x86_64-windows-msvc`).
- For Windows: link `-lkernel32 -lshell32 -lws2_32 -luser32 -lgdi32 -lwinmm -ladvapi32 -lOpenCL -lwinsqlite3`.
- For Linux: link `-lm -lpthread -ldl -lOpenCL -lsqlite3`.
- In `src/cartanc/llvm_codegen.car`, ensure `getchar` is registered as returning `double` and calling `@getchar()` with `i32` -> `double` conversion.

---

## 4 Gates of Verification
- **Gate 1**: `getchar()` intrinsic added to LLVM codegen and verified in 3-stage bootstrap fixpoint.
- **Gate 2**: Pure CARTAN `cartan_read_line()` implemented in `core_runtime.car` and verified via `test/compiler_suite/test_read_line.car`.
- **Gate 3**: `src/std/cartan_native_io.c` deleted; `tools/zig_wrapper.py` updated with target-aware library links.
- **Gate 4**: Cross-compilation test for Linux (`x86_64-linux-gnu`) and all 87 regression targets verified cleanly.
