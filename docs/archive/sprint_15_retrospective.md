# CARTAN Engineering Team Formal Retrospective & Excellence Roadmap

**Date:** August 6, 2026  
**Scope:** Sprints 1–15, GeoMind MoE Engine Modernization, Compiler Architecture & Repository Cleanup  
**Participants:** Supervisor Agent, CARTAN Language Architect, Compiler Engineer, QA Tester, Code Auditor  

---

## 1. Key Lessons Learned
- **Target C-ABI Calling Conventions**: In LLVM IR textual emission, variadic C function calls (e.g., `printf`) require explicit 32-bit float to 64-bit double promotion (`fpext float %reg to double`) to prevent argument placement register mismatches.
- **AST Discriminator Single-Source-of-Truth**: Enum variant index definitions in `ast.ch` must strictly mirror discriminator match cases across all compiler passes (`type_checker.car`, `llvm_codegen.car`, `optimizer.car`) to avoid default type fallback desynchronization.
- **Strict Repository Payload Boundaries**: Staging multi-megabyte/gigabyte dataset files in Git causes severe sync degradation. Enforcing explicit ignore patterns in `.gitignore` preserves low-entropy repository performance.

---

## 2. Process & Technical Improvements (What We Can Do Better)
- **Arena-Scoped AST Memory Management**: AST-level node replacements in `optimizer.car` currently generate new tree structures without freeing superseded nodes. Integrating `AstArena` bump allocation across compiler passes will eliminate heap fragmentation.
- **Full Recursive Identity Folding**: Expanding `optimizer.car` to evaluate variable-identity expressions (`x + 0.0`, `x * 1.0`) prior to backend code generation reduces LLVM register allocation pressure.

---

## 3. Current Friction Points & Hindering Issues
- **Toolchain Binary & C-Runtime Synchronization**: Modifications to `src/cartanc/c_runtime.c` require manual copying to `C:\Users\rich-\.cartan\c_runtime.c` to update installed `cartanc.exe` builds.
- **Client UI Command Approval Gate**: Client application UI confirmation modals interrupt multi-command execution workflows.

---

## 4. Forward-Looking Roadmap to Development Excellence
- **Automated Toolchain Installer (`tools/build_toolchain.car`)**: Develop a native CARTAN utility in `tools/` that automatically compiles `c_runtime.c`, synchronizes `~/.cartan/` binaries, and executes all 13 snapshot regression targets in a single atomic command.
- **Self-Hosting Standard Library Expansion**: Continue replacing raw C-FFI externs with native CARTAN abstractions in `src/std/` (`fs.car`, `tensor.car`, `math.car`, `io.car`, `collections.car`).
