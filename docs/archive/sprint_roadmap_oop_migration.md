# Compiler Evolution: Roadmap of Sprints

Based on our architectural decisions, we are embracing the low-level, bare-metal capabilities of `cartanc` first. Once the self-hosted compiler is completely bulletproof, we will systematically teach it how to parse, type-check, and compile the cleaner Object-Oriented syntax (`struct`, `trait`, `impl`), eventually allowing us to refactor the compiler itself from the inside out.

Here is our sprint roadmap:

## Sprint 1: The Discriminant Alignment (Current)
**Goal:** Stabilize the self-hosted LLVM backend so it perfectly matches the parser's AST.
- [ ] **Archive Prototypes:** Move all older `.car` files in the root `src/` directory to `src/archive/legacy_prototypes/` to establish `src/cartanc/` as the single source of truth.
- [ ] **Python Mapping Script:** Write a targeted Python script to analyze `llvm_codegen.car` and map the shifted discriminant checks (e.g., `114.0`) to the correct values defined in `ast.ch` (e.g., `24.0`).
- [ ] **Manual Verification & Diff Review:** Carefully review the script's output to ensure no node logic was mangled.
- [ ] **Self-Hosting Test:** Rebuild `cartanc_stage2.exe` and compile a simple program to prove LLVM IR generation is functioning perfectly with the newly aligned AST.

## Sprint 2: Standard Library Expansion & Core Primitives
**Goal:** Strengthen the bare-metal foundations before introducing high-level OOP concepts.
- [ ] **Standard Library Enhancements:** Expand `src/std/` to include core mathematical tensor operations (`relu`, `matmul`) linking directly to `c_runtime.c` or LLVM intrinsics.
- [ ] **Array Indexing Standardization:** Audit and standardize the use of native array indexing (e.g., `s[len]`) for C-strings vs. `tree_get()` for AST nodes to prevent future memory access violations.
- [ ] **Compiler Error Ergonomics:** Improve error reporting in the parser so that when we start writing complex structs, we get precise line-number feedback on failures.

## Sprint 3: Teaching `cartanc` about `struct`
**Goal:** The first step toward the OOP migration. We add native struct support to the low-level compiler.
- [ ] **Parser Updates:** Extend `src/cartanc/parser.car` to parse `struct { ... }` definitions and field access (`obj.field`).
- [ ] **Type Checker Updates:** Implement type safety in `src/cartanc/type_checker.car` to enforce that struct instantiations match their declared fields.
- [ ] **LLVM Codegen Updates:** Map struct declarations to LLVM `%MyStruct = type { i32, ptr }` and use `getelementptr` for field accesses.
- [ ] **Validation:** Compile a Cartan program that allocates and uses a native struct.

## Sprint 4: Traits, Impl, and Method Resolution
**Goal:** Bring full OOP capability to the language.
- [ ] **Parsing Traits & Impl:** Update `parser.car` to handle `trait`, `impl`, and method definitions (`fn (self) ...`).
- [ ] **Method Resolution (vtable / static dispatch):** Update `type_checker.car` to bind method calls to the correct `impl` block based on the caller's type.
- [ ] **LLVM Lowering:** Convert method calls into standard LLVM function calls by implicitly passing `self` as the first argument.

## Sprint 5: The Grand Refactor (Bootstrapping the OOP Compiler)
**Goal:** Eat our own dog food. Rewrite the compiler using the new OOP syntax.
- [ ] **Port Legacy Designs:** Resurrect the clean designs from `src/archive/legacy_prototypes/` (like `struct LLVMGenerator` and `trait AstNode`).
- [ ] **Rewrite `parser.car` & `llvm_codegen.car`:** Swap out the raw `tree_get` loops for elegant, object-oriented syntax.
- [ ] **Final Bootstrap:** Compile the OOP-written compiler using the old low-level compiler. Then, compile the OOP compiler *with* the OOP compiler to complete the full evolution!
