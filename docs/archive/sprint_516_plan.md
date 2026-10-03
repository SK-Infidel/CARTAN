# Sprint 516 Plan: Native Standalone Compiler Linker Driver (Zero-Python Toolchain)

**Sprint Goal**: Implement a pure CARTAN native toolchain resolver and linker driver in `src/cartanc/main.car`, eradicate all frontend debug include noise, and achieve bit-for-bit SHA-256 fixpoint parity across a 3-stage self-hosting bootstrap.

---

## 1. User Stories & Scope
- **User Story 1**: As a developer and compiler builder, I want `cartanc.exe` to link native Windows executables directly via Clang/LLD without spawning `python tools/zig_wrapper.py`, so that CARTAN is truly standalone and free of external scripting dependencies.
- **User Story 2**: As a developer, I want compiler output to be clean, professional, and free of extraneous `[DEBUG include]` and `[DEBUG lex]` trace noise, so that actionable compilation status and errors are immediately visible.
- **User Story 3**: As a compiler architect, I want a 3-stage self-hosting bootstrap verification ensuring that the compiler compiling itself produces identical, bit-for-bit verifiable machine code.

---

## 2. Technical Architecture
1. **Toolchain Resolution (`cartan_resolve_compiler_path`)**:
   - Priority 1: Check `cartan_getenv("CARTAN_CLANG")`. If non-empty and file exists, return it.
   - Priority 2: Check `C:/Program Files (x86)/Intel/oneAPI/compiler/latest/bin/compiler/clang.exe`.
   - Priority 3: Check `C:/Program Files (x86)/Intel/oneAPI/2025.3/bin/compiler/clang.exe`.
   - Priority 4: Check `C:/Program Files/LLVM/bin/clang.exe`.
   - Fallback: `"clang"`.
2. **Library Resolution (`cartan_get_compiler_lib_flags`)**:
   - Probe `lib` and `../lib`.
   - Resolve CUDA lib path from `cartan_getenv("CUDA_PATH")` (`/lib/x64`) or fallback to `C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v13.2/lib/x64`.
   - Resolve oneAPI lib path from `C:/Program Files (x86)/Intel/oneAPI/compiler/latest/lib` or `2025.3/lib`.
3. **Command Assembly**:
   - Construct Clang invocation string:
     `"<clang>" -target x86_64-pc-windows-msvc -g -O2 -mavx2 -mfma -Wno-override-module -Wl,/FORCE:MULTIPLE -Wl,/STACK:67108864 <lib_paths> -DCARTAN_GPU_RUNTIME_LINKED -DCARTAN_COMPILED_LLVM -D_CRT_SECURE_NO_WARNINGS -x ir "<out_ll>" -o "<output_file>" -lkernel32 -lshell32 -lws2_32 -luser32 -lgdi32 -lwinmm -ladvapi32 -lOpenCL -lwinsqlite3 -lwgpu_native.dll`
4. **Clean Logging**:
   - Eliminate `[DEBUG include]` prints on lines 96, 144, 150, 160, 168, 172 of `src/cartanc/main.car`.
5. **3-Stage Bootstrap**:
   - Stage 1: `.\cartanc.exe build src/cartanc/main.car -o bin/cartanc_stage1.exe`
   - Stage 2: `.\bin\cartanc_stage1.exe build src/cartanc/main.car -o bin/cartanc_stage2.exe`
   - Stage 3: `.\bin\cartanc_stage2.exe build src/cartanc/main.car -o bin/cartanc_stage3.exe`
   - Parity Check: `Get-FileHash bin/cartanc_stage2.ll, bin/cartanc_stage3.ll`
   - Promotion: `Copy-Item bin/cartanc_stage2.exe cartanc.exe -Force`.
