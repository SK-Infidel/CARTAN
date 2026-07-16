# Changelog

## [2026-07-16] - Phase 8 Tier 3 Completion

### Added
- **Geometric Autodiff**: Implemented parsing and C-ABI hooks for `riemannian grad(...)`, allowing for intrinsic gradient calculation on non-Euclidean manifolds.
- **Deep Learning Primitives**: Introduced the `layer` and `graph` first-class keywords, bridging the gap between mathematical primitives and traditional neural topologies (e.g. `layer fc = dense(512, relu)`).
- **Manifold-Aware Graph Nodes**: Hooked `layer` and `graph` instantiations directly into `tensor_runtime` via `cartan_rt_layer_create` and `cartan_rt_graph_create`, ensuring topology declarations map cleanly to spatial compute geometries.

### Changed
- Refactored `compiler/src/lexer.rs` and `compiler/src/token.rs` to support `layer`, `graph`, and `riemannian`.
- Updated `compiler/src/parser.rs` to support modifiers on functional transforms (`riemannian grad`) and explicit component blocks (`graph { ... }`, `layer = ...`).
- Added full `LayerDecl` and `GraphDecl` support across Type Checker, AST, CodeGen, and the execution engine.

## [2026-07-16] - Phase 8 Tier 2 Completion

### Added
- **Composable Transforms**: Implemented parsing and C-ABI hooks for functional transformation primitives (`grad(f)`, `vmap(f)`, `transform`).
- **Hardware Pointers**: Introduced `ptr` type annotations and `&`, `*` address/dereference operators for direct memory manipulation, bypassing C wrappers.
- **Model Interoperability**: Added the `import_onnx!` macro and `import "hf://..." as alias` for zero-cost transpilation and fetching topologies natively.
- **Deployment Optimizations**: Introduced the `quantize(INT8)` directive to emit specialized TensorCore math instructions, and implemented AST-level layer fusion.
- **Natural Language Parsing**: Added Prompt Literals (`p"..."`) which auto-tokenize at compile-time and extended the `match` statement to support native text-pattern resolution via `cartan_pattern_match`.
- **Architectural Ergonomics**: Implemented Keras-style `pipeline { }` syntax for sequential graphs, native `tensor[..., rgb8]` image tensors, and JIT compilation blocks (`jit { }`).
- **Grokking Hooks**: Added syntax for `project_vocab` to seamlessly map cross-lingual sub-networks and `weight_decay(w, val)` to attach exploration constraints strictly to parameters.

### Changed
- Refactored the core `parser.rs` variable declaration loop to support optional `ptr` and `identifier` type annotations.
- Registered new AST nodes (`Expr::ImportOnnx`, `Expr::Quantize`, `Expr::Transform`, `Expr::ProjectVocab`, `Stmt::PipelineDecl`, `Stmt::JitBlock`, etc.) across the LLVM CodeGen and Interpreter passes.
- Hooked external execution routes into `tensor_runtime/src/lib.rs` to safely intercept `cartan_internal_import_onnx`, `cartan_rt_transform`, and `cartan_tensor_quantize_int8`.

All notable changes to the CARTAN project will be documented in this file.

## [Unreleased] - 2026-07-16

### Added
- **Symbolic Structures & Data Types**: Introduced `lattice` and `tree` primitives to bridge the gap between connectionist and symbolic AI within CARTAN.
  - Added types in `compiler/src/types.rs` and `compiler/src/ast.rs`.
  - Stubbed runtime allocators (`cartan_rt_alloc_lattice`, `cartan_rt_alloc_tree`) in `tensor_runtime`.
  - Added support in the parser for declaration.
- **Tree Search (MCTS)**: Integrated native syntax for search algorithms over trees.
  - Added `TokenType::Search` to lexer.
  - Defined `Expr::TreeSearch` in the AST.
  - Added type-checking for `search(MCTS, my_tree)` in `type_checker.rs`.
  - Implemented LLVM code generation hooked to the `@cartan_rt_tree_search_mcts` runtime function.
- **Tangent Vectors (Planning)**: Distinguished Ambient Vectors (Global/Flat) from Intrinsic Tangent Vectors (Local/Curved) in the design, paving the way for non-Euclidean native types.
- **Multimodal Block**: Introduced the `multimodal { }` block for synchronizing ragged multimodal streams (image, audio, text) directly at compile-time.
  - Added AST, Lexer, and Parser representations.
  - Plumbed `MultimodalBlock` through optimizer, macro pass, liveness, and autodiff phases.
  - Emitted C runtime calls `@cartan_rt_multimodal_sync_start()` and `@cartan_rt_multimodal_sync_end()` in LLVM IR to orchestrate hardware synchronization lock acquisition.
- **Vmap Block**: Introduced the `vmap { }` block for implicitly broadcasting logic over batch dimensions (a la JAX).
  - Wired `VmapBlock` natively into the Lexer, Parser, and AST representations.
  - Recursively plumbed `vmap` scopes down through the compiler analysis passes.
  - Handled automated IR LLVM emissions for runtime hooks: `@cartan_rt_vmap_begin()` and `@cartan_rt_vmap_end()`.
- **Tier 1 Feature Completion**: Sequentially implemented the final remaining native blocks and memory semantics.
  - Added new keywords to `Lexer` and `Token`: `Lazy`, `Unified`, `Doubt`, `Chain`, `PagedAttention`, `Latent`, `Route`, `Grok`, `Tool`, `Override`.
  - Upgraded AST and Parser to support modifier-prefixed tensor allocations (e.g. `lazy tensor[128]`).
  - Added block structures: `doubt`, `chain`, `route`, `grok`, and `override`.
  - Added expression forms for `paged_attention` and `lazy`.
  - Recursively plumbed all block structures through `optimizer`, `macro_pass`, `liveness`, and `autodiff` to ensure full analytical fidelity.
  - Plumbed C hooks and allocations into `llvm_codegen.rs` with mapping into LLVM IR block injections.
  - Generated backing stub implementations for all C-ABI calls in `tensor_runtime`.

### Changed
- Refined codegen and parser to support symbolic-native compilation for trees and lattices.
