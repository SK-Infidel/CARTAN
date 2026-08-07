# Implementation Plan - Full Code Review, Comments, Runtime Fixes & Spec Updates

This plan addresses the missing runtime definitions that cause link-time failures during native binary builds, adds comprehensive code commenting to the compiler/runtime, and aligns the language documentation (`LANGUAGE_REFERENCE.md` and `spec.md`) with the actual syntax and primitives implemented in the CARTAN codebase.

## User Review Required

> [!IMPORTANT]
> - **C Runtime Linkage Fixes (`tensor_runtime/src/lib.rs`)**: During the code review, we discovered that the LLVM backend (`llvm_codegen.rs`) declares and emits calls to 30+ C runtime utility functions (like `cartan_string_length`, `cartan_rt_vmap_begin`, and `cartan_rt_doubt_begin`) which were completely missing from the runtime library. This causes compilation with `cartanc build` to fail at the linkage stage. We propose adding robust implementations and stubs for all missing functions directly to the runtime library.
> - **Documentation Unification**: We will document a wide array of existing but undocumented features (Lattices, Trees, Backtracking Satisfy blocks, Actor model with Spawn/Receive, and OOP Traits/Impls) to bring both `spec.md` and `LANGUAGE_REFERENCE.md` to parity with the compiler's actual implementation.

## Open Questions

- *None at this stage.*

---

## Proposed Changes

### Component 1: Compiler Code Comments & Review

We will review and add clarifying comments to the Rust compiler source files to explain design decisions, layout modifiers, type checks, and AST structures.

#### [MODIFY] [ast.rs](file:///c:/Users/rich-/source/repos/CARTAN/compiler/src/ast.rs)
- Document the AST variants (e.g. `VectorSpace::TangentSpace`, `StorageBackend`, and statement blocks like `Satisfy` / `Doubt` / `Grok`).
#### [MODIFY] [parser.rs](file:///c:/Users/rich-/source/repos/CARTAN/compiler/src/parser.rs)
- Comment parser grammar mappings, including structured backtracking loops for `Satisfy` and `Backtrack`.
#### [MODIFY] [type_checker.rs](file:///c:/Users/rich-/source/repos/CARTAN/compiler/src/type_checker.rs)
- Comment shape type checking, tangent vector anchor space verification, and custom manifold metrics.
#### [MODIFY] [llvm_codegen.rs](file:///c:/Users/rich-/source/repos/CARTAN/compiler/src/llvm_codegen.rs)
- Comment the code emission process: mapping variables, building nested scopes, and emitting dynamic routing hooks.
#### [MODIFY] [eval.rs](file:///c:/Users/rich-/source/repos/CARTAN/compiler/src/eval.rs)
- Comment the stack-based VM evaluator, dynamic method dispatch logic, and multithreading spawn hooks.

---

### Component 2: C Runtime Linkage Fixes

We will add missing declarations and stub/utility implementations to `tensor_runtime/src/lib.rs` to allow LLVM-emitted code to link successfully.

#### [MODIFY] [lib.rs](file:///c:/Users/rich-/source/repos/CARTAN/tensor_runtime/src/lib.rs)
- Implement missing C runtime functions:
  - String utilities: `cartan_float_to_string`, `cartan_int_to_string`, `cartan_string_substring`, `cartan_string_length`, `cartan_string_concat`, `cartan_string_char_at`, `cartan_is_alpha`, `cartan_is_alphanumeric`, `cartan_panic`.
  - Tree/Lattice/Search allocations: `cartan_rt_alloc_lattice`, `cartan_rt_alloc_tree`, `cartan_rt_tree_search_mcts`.
  - Cognitive control blocks: `cartan_rt_doubt_begin` / `end`, `cartan_rt_chain_begin` / `end`, `cartan_rt_route_begin` / `end`, `cartan_rt_grok_begin` / `end`, `cartan_rt_override_begin` / `end`.
  - Vectorization and Sync: `cartan_rt_vmap_begin` / `end`, `cartan_rt_multimodal_sync_start` / `end`.
  - Model operations: `cartan_tensor_print`, `cartan_tensor_graft`, `cartan_tensor_translation_barrier`, `cartan_tokenize_bpe`, `cartan_tensor_ones_like`, `cartan_tensor_linear_relu`, `cartan_rt_paged_attention`, `cartan_rt_load_ctb`, `cartan_rt_parallel_transport`.

---

### Component 3: Language Specification & Reference Updates

Update documentation to align with the actual compiler codebase.

#### [MODIFY] [spec.md](file:///c:/Users/rich-/source/repos/CARTAN/docs/spec.md)
- Document the Actor Concurrency model (`spawn` blocks, `receive` structures) and how it maps to OS-level threads.
- Document Data-Oriented OOP (`trait` definition, `impl` blocks, stateful method dispatch).
#### [MODIFY] [LANGUAGE_REFERENCE.md](file:///c:/Users/rich-/source/repos/CARTAN/docs/LANGUAGE_REFERENCE.md)
- Complete overhaul to include documentation, details, and code examples for:
  - Non-Euclidean and Tangent Vector syntax (`vector[N] at anchor`).
  - Specialized AI types: `lattice[E8]`, `tree<T>`, and the `search(MCTS)` operator.
  - Stateful method binding: `trait` and `impl` definitions.
  - Actor Concurrency: `spawn` and `receive`.
  - Reasoning blocks: `satisfy { } otherwise { }`, `backtrack`, `vmap`, `lazy`, `doubt`, `chain`, `route`, `grok`, `override`, `multimodal`.
  - Dataframes: `dataframe`.
  - Vocabulary Projection and stitching: `@agent_accessible`, `absorb_layer_weights`, `project_vocab`, `import_onnx!`, `quantize`.

---

## Verification Plan

### Automated Tests
1. Verify compiler unit tests and rebuild:
   `cd compiler && cargo test`
2. Rebuild the tensor runtime and verify compilation:
   `cd tensor_runtime && cargo build --release`
3. Execute `tests/hello.car` to verify standard compile/evaluate pipeline:
   `.\compiler\target\release\cartanc.exe run tests/hello.car`
4. Execute `tests/test_phase10_oop.car` (or similar OOP/actor script) to verify dynamic dispatcher functionality.
