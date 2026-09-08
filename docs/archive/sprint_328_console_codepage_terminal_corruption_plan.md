# Sprint 328 Plan: Console Code Page Terminal Corruption Resolution

## Objective
Eliminate terminal display corruption (invisible text unless highlighted in PowerShell/conhost) caused by unconditional `SetConsoleCP(65001)` and `SetConsoleOutputCP(65001)` calls in the Cartan compiler runtime entrypoint (`cartan_crt_init`).

## Architecture & Root Cause
1. `src/cartanc/llvm_codegen.car:L888-L893` injects `SetConsoleCP(65001)` and `SetConsoleOutputCP(65001)` into `@cartan_crt_init` called by `@main`.
2. Win32 console code page mutation is session-wide in `conhost.exe`. When `geomind.exe` stops (exit or Ctrl+C), code page 65001 remains active.
3. In `conhost.exe`, code page 65001 corrupts PSReadLine syntax coloring, causing characters to match the terminal background (invisible unless highlighted).
4. Standard Cartan CRT I/O (`printf`, `fgets`) does not require codepage switching.

## Implementation Steps
1. **Immediate User Recovery**: Provide command `chcp 437` to restore visibility in active console.
2. **`src/cartanc/llvm_codegen.car`**:
   - Remove `SetConsoleCP` and `SetConsoleOutputCP` declarations from `add_builtin_extern`.
   - Modify `cartan_crt_init` definition to emit pure `ret void` without touching console code pages.
3. **Recompile Compiler (`cartanc.exe`)**:
   - `cartanc.exe build src/cartanc/main.car -o cartanc.exe`.
4. **Recompile `geomind.exe`**:
   - `cartanc.exe build test/geomind/main.car -o bin/geomind.exe` and synchronize to `build/geomind.exe` and `geomind.exe`.
5. **Empirical Verification**:
   - Verify generated LLVM IR does not contain `SetConsoleCP` or `SetConsoleOutputCP`.
   - Run 62-target compiler regression suite (`test/compiler_suite/run_tests.car`).
   - Verify `geomind.exe` execution does not alter active console code page (`chcp`).
6. **Definition of Done**:
   - Update `CHANGELOG.md` and `ISSUES.md` (`ISSUE-077`).
   - Archive retrospective and walkthrough.
