# CARTAN Changelog

All notable changes to the CARTAN compiler, language specification, and runtime will be documented in this file.

## [Unreleased] - Current Session

### Language Architecture Roadmap (Completed)
- **Symbolic Structures (2026-07-16)**: Implemented `lattice` and `tree` primitives in CARTAN. This enables symbolic AI structures natively alongside connectionist types, supporting declarative structures like `lattice[Boolean, 128]` and `tree<tensor>`.
- **Intrinsic Tangent Vectors (2026-07-16)**: Implemented native distinction between ambient Euclidean arrays (`vector[N]`) and intrinsic tangent vectors (`vector[N] at anchor`). Tangent vectors are verified at compile-time to share the exact same `ManifoldSpace` anchor point before any standard arithmetic operations are allowed, preventing unphysical geometric calculations.
- **Parallel Transport Intrinsic (2026-07-16)**: Added `Cartan.parallel_transport(v, from: a, to: b)` to the parser and AST. Enforces compile-time checks to ensure `from` and `to` reside on the same manifold before generating the LLVM `call ptr @cartan_rt_parallel_transport` instruction.
- **Control Flow & Match Statements**: Added `match` and `=>` fat arrow branching unrolled directly into LLVM cascading conditionals, replacing basic equality checks with robust condition routing.
- **Goal-Directed Execution (satisfy)**: Introduced `satisfy { ... }` blocks with backtracking to auto-tune execution bounds and constraint violations by natively rewinding the graph state without runtime bloat.
- **Live Memory Hot-Swapping**: Implemented `hotswap` blocks for rewiring AST sub-graphs in real-time. Allowed tensor registry swapping without dropping weights from VRAM, keeping training loops alive during architectural modifications.
- **Mesh Supervisors**: Built `mesh` block scope and `supervisor("strategy")` nodes for distributed fault isolation. If a node running a parameter shard drops offline, the supervisor logic traps the signal.
- **Lisp-Style Homoiconicity**: Implemented wildcard `$x` AST term rewriting for the macro engine and `quote` blocks. CARTAN can now programmatically rewrite and optimize its own neural execution pipelines with zero runtime overhead prior to LLVM compilation.
- **Autodiff Unrolling**: Extended the LLVM-native in-place AST loop unrolling to map matrix multiplications natively inside the `backward Y` pass.
- **Transpose Operator**: Natively supported `.T` in the AST parser, type checker, and lowering logic for zero-cost algebraic transposition on tensors.
- **End-to-End E2E Model**: Shipped `e2e_model.ctn` proving out the seamless fusion of parameter allocation, block scoping, stream ingest, manifold matching, match statements, and autodiff.

### Agent OS Integration (Completed)
- **Agent Accessible Functions**: Added `@agent_accessible` function decorator for dynamic DLL/SO function exportation to support AgentOS interfacing natively.
- **Weight Absorption**: Added `absorb_layer_weights` AST statement and LLVM generation to map external model weights to tensors dynamically. Replaced stubs with actual file I/O using `std::fs`.
- **Dynamic Vocabulary Expansion**: Implemented `project_vocab` AST statement and LLVM generation to dynamically expand vocabularies at runtime for elasticity. Implemented C runtime function `cartan_project_vocab` which copies overlapping dimensional segments between source and target embeddings.
- **Memory Management (Graph Freeing)**: Implemented `cartan_free_compute_graph` to eagerly release intermediate tensors during graph traversal, preventing OOM during training loops.

### Foundations & Tooling
- **Shape-Safe Typing**: Rewrote the Type Checker to mathematically prove matrix dimension alignments for the `@` operator at compile-time (e.g., $N \times K \cdot K \times M$). Mismatches cause immediate fatal errors, neutralizing runtime dimension crashes.
- **Hardware Layout Modifiers**: Added the `layout()` syntax to the parser and AST. Developers can now explicitly swizzle memory alignments using `layout(SoA)` or `layout(Tiled(x, y))` on matrix declarations.
- **Parameter Type**: Introduced the `parameter` declaration type to differentiate pinned, persistent network weights from ephemeral `tensor` variables.
- **Native BPE Tokenization Foundation**: Implemented `Expr::TokenizeBPE` in the AST. Added `compiler/src/bpe_compiler.rs` to ingest HuggingFace `tokenizer.json` files and extract vocabulary and merge rules at compile-time. Hooked up LLVM IR generation for BPE token array allocation.
- **Dynamic Build Artifacts**: The compiler now intelligently routes generated `.ll` files to `build/` and compiled executables to `release/`, rather than polluting the root workspace.
- **Master Roadmap Sync**: Re-aligned `docs/ROADMAP.md` with the ultimate bare-metal vision found in `TheBigIdea.md`.
- **Runtime Linkage**: Pre-compiled `tensor_runtime` and `gpu_runtime` into optimized `.lib` files. Resolved the `lld-link` missing library error, enabling the `cartanc build-exe` command to successfully link and generate standalone `.exe` binaries from `.ctn` files.
- **LLVM Type System Generation**: Rewrote `llvm_codegen.rs` mapping for `f32` types to resolve mismatch errors in `ExternFunctionDecl` and `FunctionDecl` when passing primitive numbers into `cartanc`.
- **Standard Library Unification**: Unified arguments in `std/io.ctn` and `std/env.ctn` to `f32` exclusively to prevent integer-to-float IR type mismatch during cross-compilation.
- **Topology-Aware Code Generation**: The `@` contraction operator now branches based on manifold type, dynamically routing to `@cartan_tensor_matmul_minkowski` or `@cartan_tensor_matmul_poincare`.
- **Riemannian Autograd Backend**: Rewrote the reverse-mode auto-differentiation in the C runtime to correctly warp gradients back into curved spaces by applying the inverse metric tensor $g^{-1}$ for both Lorentzian (Minkowski) and Hyperbolic (Poincaré Disk) topologies.
- **Strict Warning Compliance**: Resolved all IDE-flagged compiler warnings (`unused_imports`, `unused_mut`, `static_mut_refs`) in both `cartanc` and the `tensor_runtime`, ensuring a perfectly clean build process.
- **Optimizer Fusion**: Added `parameter[Adam]` and `parameter[SGD]` syntax. Optimiziers are now implemented directly in the runtime memory allocations and integrated into the global `.step()` backward pass, eliminating the need to pass huge weight tensors back to Python space.
- **Data Structures for Attention**: Added `sequence` (for ragged token streams) and `block` (for paged KV caches) primitives to the AST and compiler, allowing developers to define specialized memory arenas.
## [0.1.6] - Tier 3 Primitive Parsing
### Added
- Implemented layer and graph logic in the compiler AST.
- Implemented knowledge_base and ule primitives for neuro-symbolic logic.
- Implemented evolve blocks for genetic algorithm structure.
- Implemented spawn blocks for concurrent multi-agent structure.
- Implemented dataframe blocks for relational data logic.
- Implemented satisfy {} otherwise {} constraint blocks.
- Added iemannian optimizer modifier to transform expressions.
- Fixed AST matching structure in parser.rs and eval.rs.

### Fixed
- Restored VarDecl AST types and parsing broken by large file patching scripts.
- Verified parser stability across all Tier 3 structures, ensuring safe 0.1.6 baseline.
## [0.1.7] - Phase 9: Data-Oriented OOP & Actor State Management
### Added
- Added 	rait keyword and parser integration for structural behavior signatures.
- Added impl and impl ... for syntax for binding behaviors to flat data structs.
- Added eceive block syntax to handle message passing within spawn actor declarations.
- Extended AST with TraitDecl, ImplDecl, and ReceiveDecl structures.
- Updated 	oken.rs and lexer.rs to support new keywords natively.
- Full type checker compatibility and parser stabilization.
## [0.1.8] - Phase 10: Backend Execution Engine Upgrades
### Added
- Overhauled eval.rs backend to support full OOP State modifications.
- Introduced MethodCall dynamic dispatch against globally registered impl structures.
- Connected spawn actor keyword natively to OS-level std::thread::spawn for isolated multithreading.
- Implemented core mathematical arithmetic (float extensions) and unary operations directly in backend evaluator.

## [0.1.9] - Phase 11: Self-Hosted Compiler Refactoring
### Added
- Ported lexer.car to pure native CARTAN OOP using Traits and Impls.
- Ported parser.car to pure native CARTAN OOP, solving struct initialization ambiguity.
- Ported st.car logic to CARTAN struct properties.
- Passed full e2e validation: compiling .car scripts via Rust backend parses cleanly.
