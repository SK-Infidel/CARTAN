# Sprint 286 Implementation Plan: Documentation Synchronization & Accuracy Verification

## Objective
Audit and update `README.md`, `docs/LANGUAGE_REFERENCE.md`, and `docs/spec.md` to guarantee 100% truth and alignment with the current state of the CARTAN language, self-hosting compiler (`cartanc.exe`), pure CARTAN runtime (`core_runtime.car`), and standard library (`src/std/*.cl`).

---

## 1. Audit Findings & Discrepancies

### A. `README.md`
1. **Frontend Architecture**: Erroneously refers to `cartanc` as a "Rust-based compiler" with instructions to run `cargo build`.
   - *Fix*: Document the 100% self-hosted native CARTAN compiler pipeline (`src/cartanc/`), building via `cartanc.exe build src/cartanc/main.car -o cartanc.exe`.
2. **Standard Library Paths**: References nonexistent `aether/geomind.car` and `import "std/io.car"`.
   - *Fix*: Update to canonical `src/std/` directory (`.cl` implementations, `.ch` headers), `include "..."` syntax, and `test/geomind/` model suite.
3. **Runtime Decoupling**: Mentions legacy C/Rust `tensor_runtime`.
   - *Fix*: Document pure CARTAN runtime (`src/cartanc/core_runtime.car`), bare-metal C hardware kernel (`src/cartanc/c_runtime.c`), and WebGPU WGSL shaders (`gpu_runtime/`).
4. **CLI Reference**: Outdated `build-exe` command.
   - *Fix*: Document `cartanc build`, `cartanc run`, `cartanc repl`, `cartanc pkg`, `cartanc bindgen`, `cartanc lsp`, `cartanc doc`.

### B. `docs/LANGUAGE_REFERENCE.md`
1. **Standard Library File Extensions**: Section 12 refers to standard library files with `.car` extension (e.g. `std/fs.car`, `std/tensor.car`, `src/std/semantics.car`).
   - *Fix*: Standardize all references to `.cl` and `.ch` (`src/std/fs.cl`, `src/std/tensor.cl`, etc.).
2. **Missing Modules**: Does not document newly decoupled pure CARTAN modules `std::async` (`src/std/async.cl`), `std::security` (`src/std/security.cl`), or `core_runtime.car`.
   - *Fix*: Add dedicated reference sections for async primitives, sandboxing/VRAM lock routines, and runtime injection.
3. **FFI Signatures**: Outdated signatures like `printf(format: ptr) -> f32`.
   - *Fix*: Update to `printf(format: string) -> i32`.
4. **Toolchain Subcommands**: Lacks documentation for `run` (JIT), `pkg`, `bindgen`, `lsp`, `doc`.
   - *Fix*: Add section detailing all compiler invocation subcommands.

### C. `docs/spec.md`
1. **Compiler Architecture**:
   - Mentions "Rust Semantic Type Checker" in Section 4.3.
   - *Fix*: Correct to "Self-Hosted CARTAN Semantic Type Checker (`src/cartanc/type_checker.car`)".
2. **Core Runtime Decoupling**:
   - Mentions `core_runtime.c` in compiler architecture.
   - *Fix*: Document pure CARTAN module `src/cartanc/core_runtime.car`, auto-injected during AST expansion pass, and isolation of `c_runtime.c` to bare-metal hardware operations.
3. **Execution Pipeline**:
   - Mentions bytecode VM `.aer` execution model as current.
   - *Fix*: Clarify that `.aer` was an early VM prototype; production CARTAN compiles directly to LLVM IR (`.ll`) and utilizes the Zig pass pipeline for native `-O3` binary generation.
4. **Keyword & Directive Accuracy**:
   - Accurately specify `include "path"` as canonical module inclusion. Add `std::async` and `std::security` annotations.

---

## 2. Task Breakdown

- [ ] Task 1: Update `README.md` with accurate self-hosting compiler, CLI commands, standard library overview, and sample code.
- [ ] Task 2: Update `docs/LANGUAGE_REFERENCE.md` with `.cl`/`.ch` standard library files, `std::async`, `std::security`, core runtime, and CLI toolchain reference.
- [ ] Task 3: Update `docs/spec.md` with self-hosted compiler architecture, pure CARTAN runtime injection, and LLVM/Zig compilation pipeline.
- [ ] Task 4: Verify that all documentation references point to existing files and valid syntaxes.
- [ ] Task 5: Document retrospective and update `CHANGELOG.md`.
