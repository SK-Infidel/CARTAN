# Sprint 328 Walkthrough: Console Code Page Terminal Corruption Resolution

## Quick Recovery for Current Terminal
If your current terminal window still has invisible text from the previous run, execute:
```powershell
chcp 437
```
This immediately restores standard IBM437 encoding and resets text visibility in the current Windows Console window.

---

## What Happened

### Root Cause
1. In `src/cartanc/llvm_codegen.car`, the CRT bootstrap function `@cartan_crt_init` was unconditionally emitting:
   ```llvm
   define void @cartan_crt_init(i32 %argc, ptr %argv) {
   entry:
     %call_cp = call i32 @SetConsoleCP(i32 65001)
     %call_ocp = call i32 @SetConsoleOutputCP(i32 65001)
     ret void
   }
   ```
2. When `geomind.exe` ran, it mutated the Windows Console Host (`conhost.exe`) session code page to 65001 (UTF-8).
3. When cloze training stopped (either by completion or by pressing `Ctrl+C`), the console session was left permanently in code page 65001.
4. In `conhost.exe`, code page 65001 causes PowerShell's `PSReadLine` syntax highlighter to render text in dark colors identical to the console background. All typed characters and output became invisible until highlighted with the mouse cursor.

---

## Changes Made

1. **[`src/cartanc/llvm_codegen.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L380-L386)**:
   - Removed `SetConsoleCP` and `SetConsoleOutputCP` from builtin extern declarations.
2. **[`src/cartanc/llvm_codegen.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L886-L891)**:
   - Cleaned `@cartan_crt_init` to emit a pure `ret void` without touching host console code pages.
3. **Compiler Rebuild**:
   - Recompiled self-hosted `cartanc.exe` with zero errors.
4. **Binary Synchronization**:
   - Recompiled `geomind.exe` and synchronized across `bin/geomind.exe`, `build/geomind.exe`, and `./geomind.exe`.

---

## Verification Results

1. **Code Page Preservation**:
   ```
   > chcp 437
   > geomind.exe --help
   > chcp
   Active code page: 437
   ```
   No code page mutations occur during or after execution.
2. **Compiler Regression Suite**:
   - All 62 targets executed and passed (**62/62 PASS**).
3. **Training Resumption**:
   - `cloze_manifest.json` correctly tracks dataset `0.0` at offset `1305600.0` (Epoch 1.0) and will resume seamlessly without corrupting the terminal.
