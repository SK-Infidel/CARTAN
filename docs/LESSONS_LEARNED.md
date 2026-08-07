# CARTAN Lessons Learned & Technical Retrospective

## 1. AST Enum Variant Discriminator Alignment
- **Root Cause**: During frontend AST expansion (`ast.ch`), `FunctionDecl` and `ExternFunctionDecl` were assigned variants `#14.0` and `#15.0`. Earlier compiler passes in `llvm_codegen.car` (Pass 1) checked discriminator `#44.0` for function return type registration.
- **Symptom**: Function return types (e.g. `fn parse(...) -> ptr`) defaulted to `float` (`0.0`), causing return values to be passed via `%xmm0` instead of `%rax` in LLVM IR calls.
- **Resolution**: Updated `llvm_codegen.car` Pass 1 to check variant `#14.0` (`FunctionDecl`) and extract the return type string from field index `4.0`.
- **Lesson Learned**: Always maintain single-source-of-truth discriminator mapping between `ast.ch` enum definitions and compiler pass matchers.

---

## 2. Variadic C-ABI Floating Point Promotion in LLVM IR
- **Root Cause**: In C-ABI variadic functions (e.g., `printf(ptr, ...)`), floating point arguments MUST be promoted from 32-bit `float` to 64-bit `double` in LLVM IR (`fpext float %reg to double`) so arguments are placed in the correct floating-point registers (`%xmm0`, `%xmm1`).
- **Symptom**: Passing `float` arguments to `printf("%f", val)` printed garbage pointer-like double bit-patterns.
- **Resolution**: Updated `llvm_codegen.car` call emission pass to automatically emit `fpext float %reg to double` and format parameter signature as `double %reg` for `printf` invocations.
- **Lesson Learned**: LLVM IR code generators must explicitly respect target C-ABI argument promotion rules for variadic C functions.

---

## 3. Self-Hosting Bootstrap Toolchain Synchronization
- **Root Cause**: Rebuilding a self-hosted compiler binary (`cartanc.exe`) requires building with the current bootstrap compiler (`main.exe`) and linking with `zig cc` using MSVC target flags (`-target x86_64-windows-msvc`) and system libraries.
- **Resolution**: Standardized the build pipeline script to compile `src/cartanc/main.car` with `main.exe` and link via `zig cc` into `C:\Users\rich-\.cartan\bin\cartanc.exe`.
- **Lesson Learned**: Ensure environment runtime binaries (`c_runtime.c` and `cartanc.exe`) in `~/.cartan/` are kept in lockstep with codebase edits.
