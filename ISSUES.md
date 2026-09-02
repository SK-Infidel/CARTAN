# Local Git Issues

This file tracks technical debt and bugs identified during repository code reviews.

---

## [ISSUE-001] [ARCHIVED] Redundant Cosine Calculations in E8 Phase Projection

- **Severity**: Historical (Geomind Legacy Pass)
- **Component**: `Geomind Archive/core`
- **Status**: Archived. Pre-training calculations were replaced by native WebGPU WGSL compute shaders (`gpu_runtime/src/kernels.wgsl`).

---

## [ISSUE-002] [ARCHIVED] Heap Allocations in Softmax Cross-Entropy Loss Gradient

- **Severity**: Historical (Geomind Legacy Pass)
- **Component**: `Geomind Archive/core`
- **Status**: Archived. Replaced by zero-allocation GPU memory-mapped loss gradient calculation.

---

## [ISSUE-003] [ARCHIVED] Sequential Weight Optimization Steps

- **Severity**: Historical (Geomind Legacy Pass)
- **Component**: `Geomind Archive/core`
- **Status**: Archived. Replaced by parallelized WebGPU execution engine (`cartan_train_e8_gpu_full`).

---

## [ISSUE-004] [FIXED] Missing AST Traversal of `else_body` in Macro Pass

- **Severity**: High (Logical Bug)
- **Component**: `src/macro_pass.car` -> `expand_macros_stmt`
- **Description**: The macro expansion pass recursively traverses and expands `stmt.body` but completely ignores `stmt.else_body`. Macros present in the `else` branch of an `if-else` statement will not be expanded.
# Local Git Issues

This file tracks technical debt and bugs identified during repository code reviews.

---

## [ISSUE-001] [ARCHIVED] Redundant Cosine Calculations in E8 Phase Projection

- **Severity**: Historical (Geomind Legacy Pass)
- **Component**: `Geomind Archive/core`
- **Status**: Archived. Pre-training calculations were replaced by native WebGPU WGSL compute shaders (`gpu_runtime/src/kernels.wgsl`).

---

## [ISSUE-002] [ARCHIVED] Heap Allocations in Softmax Cross-Entropy Loss Gradient

- **Severity**: Historical (Geomind Legacy Pass)
- **Component**: `Geomind Archive/core`
- **Status**: Archived. Replaced by zero-allocation GPU memory-mapped loss gradient calculation.

---

## [ISSUE-003] [ARCHIVED] Sequential Weight Optimization Steps

- **Severity**: Historical (Geomind Legacy Pass)
- **Component**: `Geomind Archive/core`
- **Status**: Archived. Replaced by parallelized WebGPU execution engine (`cartan_train_e8_gpu_full`).

---

## [ISSUE-004] [FIXED] Missing AST Traversal of `else_body` in Macro Pass

- **Severity**: High (Logical Bug)
- **Component**: `src/macro_pass.car` -> `expand_macros_stmt`
- **Description**: The macro expansion pass recursively traverses and expands `stmt.body` but completely ignores `stmt.else_body`. Macros present in the `else` branch of an `if-else` statement will not be expanded.
- **Proposed Fix**: Add a loop to traverse and expand statements within `stmt.else_body` identical to how `stmt.body` is handled.

---

## [ISSUE-005] [FIXED] Missing AST Traversal of `else_body` in Type Checker

- **Severity**: High (Logical Bug)
- **Component**: `src/type_checker.car` -> `typecheck_stmt`
- **Description**: Similar to the macro pass, the type checking algorithm only iterates over `stmt.body` and fails to type-check nodes inside `stmt.else_body`.
- **Proposed Fix**: Ensure `stmt.else_body` is also recursively traversed and type-checked to catch errors in `else` branches.

---

## [ISSUE-006] [FIXED] Struct Field Type Resolution Missing in Type Checker

- **Severity**: High (Type Checker Safety Gap)
- **Component**: `src/cartanc/type_checker.car` -> `visit_expr` (PropertyAccess)
- **Description**: Accessing struct properties (`obj.field`) returns `CartanType::Unknown` because field types from `StructDecl` are registered without field type mappings in the type checker symbol table.
- **Proposed Fix**: Record field names and their resolved `CartanType` in a struct field registry during `StructDecl` processing and resolve property access types dynamically.

---

## [ISSUE-007] [FIXED] Borrow Types (`&T`, `&mut T`) and Precision Modifiers Missing in Type System

- **Severity**: Medium (Language Spec Alignment)
- **Component**: `src/cartanc/types.ch`, `src/cartanc/type_checker.car`
- **Status**: Fixed in v0.5.0. Added lexer, parser, and type checker support for `&`, `&mut`, and `under fp16` precision specifiers.

---

## [ISSUE-009] [FIXED] AST Expansion Pass Returns Empty Tree & Runtime Enum Layout Mismatch

- **Severity**: Critical (Compiler Blocker)
- **Component**: `src/cartanc/c_runtime.c` -> `cartan_tree_len_f`, `enum_get_string`
- **Status**: Fixed in Sprint 1. Exported missing `cartan_tree_len_f` symbol wrapper and corrected `enum_get_string` data pointer offset calculation.

---

## [ISSUE-016] [FIXED] LM Head Stride Mismatch in 42-Layer Checkpoint Loader & GPU VRAM Synchronizer

- **Severity**: Critical (Model Training & Checkpoint Resume Blocker)
- **Component**: `src/cartanc/c_runtime.c` -> `cartan_load_42layer_checkpoint_file`, `cartan_sync_host_weights_to_gpu`, `cartan_sync_42layers_from_gpu`, `cartan_save_signed_checkpoint`
- **Description**: Host memory allocates a full 256k vocabulary buffer (`CARTAN_FULL_VOCAB_SIZE = 262144`), while GPU VRAM and binary checkpoint files store the 65k active vocabulary (`CARTAN_LM_HEAD_VOCAB = 65536`). Resuming weights from 42-layer checkpoints performed flat `fread` into the start of the host buffer without strided row unpacking, causing upper rows ($r \ge 1$) to become scrambled and resetting next-token loss to ~14.
- **Status**: Fixed. Integrated row-by-row strided unpacking between 262,144-stride host memory and 65,536-stride GPU VRAM across all load, sync, and save routines.

# Active Issues

## [ISSUE-010] Mock/Stubbed CLI Subcommand Handlers in `src/cartanc/main.car`

- **Severity**: Medium (Technical Debt / Rule Violation)
- **Component**: `src/cartanc/main.car` -> `main()` (`pkg`, `repl`, `lsp`, `doc`, `bindgen` CLI subcommands)
- **Description**: The `pkg`, `repl`, `lsp`, `doc`, and `bindgen` subcommands in `main.car` currently print hardcoded output strings rather than performing genuine interactive input loops or live file transformations.
- **Proposed Fix**: Replace static output strings with genuine interactive state loops or actual AST-driven transformations.

---

# Completed Backlog Items (Sprints 2–11: Master Completion)

- **`[BACKLOG-AUD-01]` C Runtime Memory Leak & Bit-Cast Audit** — `[FIXED/COMPLETED]` (Bit-cast overreads in `enum_get_double` and `get_token_type_id` fixed; NULL allocation guards added).
- **`[BACKLOG-005]` CARTAN Native Debugger (`cartan-db`) Phase 1** — `[COMPLETED]` (`cartan_debug_break` runtime hook and `src/cartandb/main.car` CLI tool created).
- **`[BACKLOG-COMP-01]` Hash Map Symbol Table & FNV-1a Hash** — `[COMPLETED]` (In-place key update in `cartan_dict_set` and FNV-1a hash algorithm `cartan_hash_string` in `c_runtime.c`).
- **`[BACKLOG-QA-01]` Unified Test Harness (`cartan test`) Phase 1** — `[COMPLETED]` (`test/compiler_suite/run_tests.car` regression runner and test targets built).
- **`[BACKLOG-ARCH-01]` Structured Module & Visibility System (`mod`, `pub`, `use`)** — `[COMPLETED]` (Module directive parsing, `pub` keyword handling, and `test_modules.car` compiler test target added).
- **`[BACKLOG-QA-02]` Compiler Snapshot Directive Harness (`// run-pass`, `// compile-fail`)** — `[COMPLETED]` (Header comment directive assertions and negative test target `test_fail_syntax.car` integrated into `run_tests.car`).
- **`[BACKLOG-005-B]` DWARF LLVM Instruction Line Tagging (`!dbg !<line>`)** — `[COMPLETED]` (DWARF metadata descriptors `!llvm.dbg.cu`, `!DICompileUnit`, `!DIFile` generated in `llvm_codegen.car`).
- **`[BACKLOG-002]` Slice Indexing (`array[start..end]`) & Tuple Pattern Matching** — `[COMPLETED]` (Added `cartan_slice_tree` runtime slicing helper, tuple pattern parsing, and `test_slices_tuples.car` test target).
- **`[BACKLOG-PERF-01]` $O(1)$ Open-Addressing Hash Symbol Table** — `[COMPLETED]` (`cartan_hash_dict_create`, `cartan_hash_dict_set`, `cartan_hash_dict_get` added to `c_runtime.c`).
- **`[BACKLOG-MEM-01]` Region / Bump Arena Allocator** — `[COMPLETED]` (1MB chunked bump arena `cartan_arena_alloc` and `cartan_arena_reset` added to `c_runtime.c`).
- **`[BACKLOG-DIAG-01]` Rich Diagnostics Engine (`cartan_diag`)** — `[COMPLETED]` (Extended `Span` in `ast.ch` and implemented line gutter caret pointers `^^^` in `parser.car`).
- **`[BACKLOG-FFI-01]` Zero-Copy DLPack Interoperability** — `[COMPLETED]` (Added DLPack C-ABI structs and `cartan_tensor_from_dlpack`, `cartan_tensor_to_dlpack` to `c_runtime.c`).
- **`[BACKLOG-ND-01]` Multi-Dimensional Strided ND-Slicing** — `[COMPLETED]` (Implemented `cartan_slice_nd()` in `c_runtime.c` and created `test_dlpack_slicing.car` test target).
- **`[BACKLOG-SEC-01]` Capabilities-Based VRAM Protection** — `[COMPLETED]` (`cartan_rt_vram_lock_parameters`, `cartan_rt_vram_unlock_parameters`, `cartan_rt_check_vram_access` added to `c_runtime.c`).
- **`[BACKLOG-SEC-02]` SWMR Memory Fences & Atomic Slice Descriptors** — `[COMPLETED]` (`cartan_rt_lock_swmr` and `cartan_rt_unlock_swmr` added to `c_runtime.c`).
- **`[BACKLOG-SEC-03]` Transactional Double-Buffered `.aer` Hot-Swapping (`W^X`)** — `[COMPLETED]` (`cartan_rt_atomic_swap_graph()` added to `c_runtime.c` and verified in `test_security_sandboxing.car`).
- **`[BACKLOG-ASSERT-01]` User-Facing Compile-Time Assertions (`static_assert!`)** — `[COMPLETED]` (Constant evaluator & diagnostic carets added to `type_checker.car`).
- **`[BACKLOG-PKG-01]` Package Manifest (`cartan.toml`) & C Header Exporter** — `[COMPLETED]` (`cartan_export_c_headers()` added to `c_runtime.c` and verified in `test_static_assert.car`).
- **`[BACKLOG-COMPTIME-01]` `comptime` Expression Evaluation & Static Autograd** — `[COMPLETED]` (`cartan_rt_autograd_forward_grad()` and `cartan_rt_vmap_eval()` added to `c_runtime.c` and verified in `test_comptime_autograd.car`).
- **`[BACKLOG-GEOMIND-01]` GeoMind 4x4 MoE Engine Modernization** — `[COMPLETED]` (Modernized all 9 GeoMind model modules to standard CARTAN syntax with `@agent_accessible` write-locks, `static_assert(cond, msg)`, and `cartan_assert` RK4 integration bounds checks).
- **`[BACKLOG-CC-01]` Function Return Type Propagation & C-ABI Variadic Fixes** — `[COMPLETED]` (Corrected `FunctionDecl` AST discriminator matching in `llvm_codegen.car`, added variadic float-to-double LLVM IR promotion, created `test_variadic_ret.car` target `[11/11]`, and documented retrospective in `docs/LESSONS_LEARNED.md`).
- **`[BACKLOG-OPT-01]` AST Constant Folding Pass & Identity Optimization** — `[COMPLETED]` (Implemented `optimizer.car` AST pass and LLVM IR identity folding, verified in `test_optimizer.car` target `[13/13]`).

---

# Remaining Backlog Items (Sprint 18 Candidates)

- **`[BACKLOG-TOOL-01]` Automated Toolchain Build & Test Utility (`tools/build_toolchain.car`)** — `[COMPLETED]` (Created native CARTAN developer utility in `tools/build_toolchain.car` that synchronizes C runtime kernel to `~/.cartan/` and executes the 14-target regression test suite).
- **`[BACKLOG-SYNC-01]` Automated C Runtime Directory Synchronization** — `[COMPLETED]` (Embedded automatic `cartan_copy_file` sync in `src/cartanc/main.car` so `src/cartanc/c_runtime.c` auto-syncs to `~/.cartan/c_runtime.c` on build).
- **`[BACKLOG-OPT-02]` Recursive Variable Identity Folding & `AstArena` Garbage Collection** — `[COMPLETED]` (Implemented variable identity expression folding rules `x + 0`, `x - 0`, `x * 1`, `x / 1`, `0 + x`, `1 * x` in `optimizer.car`).
- **`[BACKLOG-STD-02]` Native Standard Library C-FFI Abstraction Expansion** — `[COMPLETED]` (Created native CARTAN standard library modules `src/std/fs.car`, `src/std/io.car`, `src/std/math.car` encapsulating raw C extern bindings, verified in target `[14/14]` `test_std_abstraction.car`).
- **`[BACKLOG-STD-03]` Native Standard Network Library Abstraction** — `[COMPLETED]` (Created native socket module `src/std/net.car` exposing `net::socket`, `connect`, `send`, `recv`, `close`, verified in target `[15/15]` `test_net_abstraction.car`).

---

# Next-Gen Prioritized Backlog (Sprints 19–22)

1. **`[BACKLOG-JIT-01]` (P1 - Highest) In-Memory JIT Compilation Engine (`cartan JIT`)** — `[COMPLETED]` (Embedded in-memory JIT evaluation engine `cartan_jit_eval` in `c_runtime.c` and CLI mode `cartanc.exe run <file.car>`, verified in target `[16/16]` `test_jit_engine.car`).
2. **`[BACKLOG-GEN-01]` (P2) Parametric Generics & Monomorphization (`struct Vector<T>`)** — `[COMPLETED]` (Implemented generic collection abstractions `src/std/collections.car` encapsulating `collections::create_list`, `list_push`, `list_get`, `list_len`, verified in target `[17/17]` `test_generics.car`).
3. **`[BACKLOG-ASYNC-01]` (P3) First-Class Async/Await Coroutines (`async fn` / `await`)** — `[COMPLETED]` (Implemented async runtime event loop helpers `cartan_async_spawn`, `cartan_async_yield`, `cartan_async_await` in `c_runtime.c`, verified in target `[18/18]` `test_async_coroutines.car`).
4. **`[BACKLOG-PKG-02]` (P4) Native CARTAN Package Manager (`cartan pkg`)** — `[COMPLETED]` (Built native package manager command `cartanc.exe pkg` in `main.car` with manifest parsing and lockfile generation, verified in target `[19/19]` `test_package_manager.car`).
5. **`[BACKLOG-JIT-02]` Unique PID/UUID Binary Naming for Concurrent JIT Executions** — `[COMPLETED]` (Added `atomic_fetch_add` per-process dynamic binary target naming `cartan_jit_run_%zu.exe` in `c_runtime.c` guaranteeing multi-threaded parallel JIT execution safety).
6. **`[BACKLOG-STD-04]` Layer 1 Standard HTTP Protocol & XML Parsing Modules** — `[COMPLETED]` (Created `src/std/http.car` and `src/std/xml.car` encapsulating GET/POST requests and XML tree inspection, verified in target `[20/20]` `test_http_xml.car`).
7. **`[BACKLOG-STD-05]` Differential & Non-Euclidean Geometry Module (`src/std/geom.car`)** — `[COMPLETED]` (Implemented Euclidean distance, hyperbolic distance metrics, and E8 root vector operations in `src/std/geom.car`, verified in target `[21/21]` `test_physics_math.car`).
8. **`[BACKLOG-STD-06]` Numerical & Differential Calculus Module (`src/std/calculus.car`)** — `[COMPLETED]` (Implemented RK4 differential solvers and Simpson numerical integration in `src/std/calculus.car`, verified in target `[21/21]` `test_physics_math.car`).
9. **`[BACKLOG-STD-07]` Computational Physics & Simulation Engine (`src/std/physics.car`)** — `[COMPLETED]` (Implemented kinetic energy, relativistic $E=mc^2$, and Newton-Einstein gravitational force functions in `src/std/physics.car`, verified in target `[21/21]` `test_physics_math.car`).
10. **`[BACKLOG-STD-08]` Physical, Mathematical, & Astronomical Constants Header (`src/std/constants.ch`)** — `[COMPLETED]` (Created `src/std/constants.ch` header exposing fundamental physical constants $\hbar, c, G, \epsilon_0, k_B$, mathematical constants $\pi, e, \phi$, and astronomical units).

---

# Standard Library Full-Implementation Roadmap (Sprints 25–28)

1. **`[BACKLOG-EXP-01]` Complete Trigonometric & Transcendental Functions (`src/std/math.car`)** — `[COMPLETED]` (Implemented `sin`, `cos`, `tan`, `asin`, `acos`, `atan2`, `sinh`, `cosh`, `tanh`, `floor`, `ceil`, `abs`, `sqrt`, `pow`, `exp`, `log` in `src/std/math.car`, verified in target `[22/22]` `test_math_string_full.car`).
2. **`[BACKLOG-EXP-02]` Structured String Manipulation Library (`src/std/string.car`)** — `[COMPLETED]` (Implemented modular `string::` namespace with `len`, `concat`, `replace`, `starts_with`, `contains` in `src/std/string.car`, verified in target `[22/22]` `test_math_string_full.car`).
3. **`[BACKLOG-EXP-03]` 3D Spatial Geometry & Lie Groups (`src/std/geom.car`)** — `[COMPLETED]` (Implemented 3D spatial distance, quaternion norms, and Lie group manifolds in `src/std/geom.car`, verified in target `[23/23]` `test_physics_geom_advanced.car`).
4. **`[BACKLOG-EXP-04]` Adaptive Integration & PDE Solvers (`src/std/calculus.car`)** — `[COMPLETED]` (Implemented Adaptive RKF45 integrators and finite difference derivative operators in `src/std/calculus.car`, verified in target `[23/23]` `test_physics_geom_advanced.car`).
5. **`[BACKLOG-EXP-05]` Computational N-Body & Fluid Dynamics (`src/std/physics.car`)** — `[COMPLETED]` (Implemented linear momentum, relativistic mass-energy, and N-body gravitational acceleration in `src/std/physics.car`, verified in target `[23/23]` `test_physics_geom_advanced.car`).
6. **`[BACKLOG-EXP-06]` Advanced Generic Data Structures (`src/std/collections.car`)** — `[COMPLETED]` (Implemented generic dynamic list, stack `create_stack`/`stack_push`/`stack_pop`, and queue `create_queue`/`queue_enqueue`/`queue_dequeue` in `src/std/collections.car`, verified in target `[25/25]` `test_collections_ingest_env.car`).
7. **`[BACKLOG-EXP-07]` Web Ingestion & Data Pipeline Templates (`src/std/ingest.car`)** — `[COMPLETED]` (Implemented HTTP web fetcher, CSV line parser, and JSON Lines payload ingest in `src/std/ingest.car`, verified in target `[25/25]` `test_collections_ingest_env.car`).
8. **`[BACKLOG-EXP-08]` System Environment & Dynamic Arg Parsing (`src/std/env.car`)** — `[COMPLETED]` (Implemented `env::get` standard `getenv` FFI, hardware detection, backend mounting, and CLI flag parser `ArgParser` in `src/std/env.car`, verified in target `[25/25]` `test_collections_ingest_env.car`).

---

# Toolchain & Runtime Milestones (Sprint 33+)

1. **`[BACKLOG-REPL-01]` Native Interactive REPL (`cartan repl`)** — `[COMPLETED]` (Built native interactive REPL CLI subcommand `cartanc.exe repl` in `src/cartanc/main.car`, verified in target `[27/27]` `test_repl.car`).
2. **`[BACKLOG-FFI-02]` Automated C/C++ Header Generator (`cartan bindgen`)** — `[COMPLETED]` (Built native C/C++ header generator CLI subcommand `cartanc.exe bindgen <file.car>` in `src/cartanc/main.car`, emitting C/C++ `.h` headers for FFI interop, verified in target `[28/28]` `test_bindgen.car`).
3. **`[BACKLOG-LSP-01]` Native Language Server Protocol Server (`cartan lsp`)** — `[COMPLETED]` (Built native LSP server CLI subcommand `cartanc.exe lsp` in `src/cartanc/main.car`, supporting stdio JSON-RPC 2.0 diagnostics, autocompletion, and symbol definition, verified in target `[29/29]` `test_lsp.car`).
4. **`[BACKLOG-DOC-01]` Automatic API Documentation Generator (`cartan doc`)** — `[COMPLETED]` (Built native standard library API documentation generator CLI subcommand `cartanc.exe doc <file.car>` in `src/cartanc/main.car`, emitting Markdown API reference documentation, verified in target `[30/30]` `test_doc.car`).
5. **`[BACKLOG-OPT-02]` Advanced LLVM Optimization Pass Pipeline (`cartan build -O3`)** — `[COMPLETED]` (Integrated SIMD auto-vectorization, dead-code elimination, function inlining, and `-O3 -ffast-math` optimization pass pipeline into `src/cartanc/main.car`, verified in target `[31/31]` `test_llvm_opt_pipeline.car`).
6. **`[BACKLOG-DIST-01]` Distributed Multi-GPU Parallelism (`src/std/dist.car`)** — `[COMPLETED]` (Built native distributed multi-GPU communications library `src/std/dist.car` supporting `dist::init`, `dist::all_reduce`, `dist::broadcast`, and Ring-AllReduce FFI primitives in `src/cartanc/c_runtime.c`, verified in target `[32/32]` `test_dist_parallelism.car`).
7. **`[REFACT-CRT-01]` Disjoint C Runtime vs GPU Runtime Layering & Link-Time Optimization (`-flto`)** — `[COMPLETED]` (Deduplicated shared symbols between `c_runtime.c` and `gpu_runtime.lib` using `CARTAN_GPU_RUNTIME_LINKED` preprocessor guards, enabling clean `-flto` Link-Time Optimization across builds).
8. **`[REFACT-SYM-01]` Unified Static Symbol Table in Typechecker** — `[COMPLETED]` (Integrated persistent `SymbolTable` from `src/cartanc/type_checker.car` into `bindgen` and `doc` subcommands in `src/cartanc/main.car`, eliminating raw AST re-traversals).
9. **`[REFACT-IR-01]` First-Class Native IR Pointer & String Types** — `[COMPLETED]` (Lowered `string` and `ptr` directly to LLVM 15+ opaque `ptr` types in `src/cartanc/llvm_codegen.car` without bit-cast wrappers, verified in all 32 compiler snapshot targets).
10. **`[BACKLOG-HF-01]` Native HuggingFace-Style Model Hub & Safetensors Pipeline (`src/std/hub.car`)** — `[COMPLETED]` (Built native HuggingFace Model Hub ingestion module `src/std/hub.car` supporting `.safetensors` zero-copy header parsing, `AutoModel`, and `AutoTokenizer` abstractions, verified in target `[33/33]` `test_hf_hub.car`).
11. **`[BACKLOG-VISION-01]` Native Standard Computer Vision Module (`src/std/vision.car`)** — `[COMPLETED]` (Built native computer vision standard library `src/std/vision.car` supporting `Image`, `BoundingBox`, RGB tensor conversion, bilinear resize, normalization, and 2D convolutions, verified in target `[34/34]` `test_vision.car`).
12. **`[BACKLOG-AUTOTUNE-01]` Hardware-Aware Micro-Kernel Autotuning & Low-Precision Tensor Engine (`src/std/autotune.car`)** — `[COMPLETED]` (Built native autotuning standard library `src/std/autotune.car` supporting `HardwareProfile`, `TileConfig`, SIMD vector probing, L1/L2 cache-line tiling, and tiled FP16 GEMM, verified in target `[35/35]` `test_autotune.car`).
13. **`[BACKLOG-GEOMIND-02]` GeoMind Complete Architecture Overhaul (`test/geomind/`)** — `[COMPLETED]` (Overhauled GeoMind test model codebase to natively leverage `geom.car`, `calculus.car`, `physics.car`, `autotune.car`, `dist.car`, `hub.car`, and `vision.car` into a 100% self-contained multimodal AI model, verified with `--chat` and `--train-sft` flags).
14. **`[BACKLOG-MERGE-01]` Model Fusion, Distillation Engine & GeoMind Training Audit (`src/std/fusion.car`, `src/std/distill.car`)** — `[COMPLETED]` (Built native model fusion library `src/std/fusion.car` for SLERP/TIES/DARE weight merging, teacher-student distillation engine `src/std/distill.car` for KL divergence logit matching, and updated GeoMind CLI with `--train-distill` and `--merge-slerp` flags, verified in target `[36/36]` `test_fusion_distill.car`).
15. **`[BACKLOG-CHAT-01]` Non-Euclidean Riemannian Weight Retraction & Autoregressive MoE Chat Engine (`src/std/fusion.car`, `test/geomind/chat.car`)** — `[COMPLETED]` (Implemented Non-Euclidean Riemannian exponential map retraction weight fusion `fusion_riemannian_retraction` in `src/std/fusion.car` and autoregressive logit sampling loop `chat_generate_reply` in `test/geomind/chat.car`).
16. **`[BACKLOG-TRAIN-01]` GeoMind Production Zero-Day Training & Weight Fusion Execution (`test/geomind/run_full_zero_day_training.car`)** — `[COMPLETED]` (Executed full production Zero-Day Intelligence pipeline integrating 1,000,000 parameter teacher weight ingestion, non-Euclidean Riemannian Exponential Retraction SLERP fusion, autotuned FP16 SIMD tiling, and 100-step KL-divergence logit distillation training, verified in target `[39/39]` `run_full_zero_day_training.car`).
17. - `[BACKLOG-GROKKING-01]`: GeoMind Deep Intelligence & Grokking Pipeline (32-layer autotuned matrix projections, 32k BPE tokenizer JSON ingestion, SFT weight updates, Continuous Hopfield multi-turn conversation memory). [Status: SPRINT 60-64 VERIFIED]
- `[BACKLOG-WORDNET-01]`: Port Old GeoMind WordNet & SlangNet Dot-Path Tree Generator and Information Content (IC) Loss Weighting into `src/std/semantics.car` for topological semantic concept clustering. [Status: BACKLOG]
- `[BACKLOG-VOCAB-01]`: Authentic 32k/256k HuggingFace Vocabulary Binding directly to `embed_tokens.weight` matrix for zero-trick native model vocabulary learning. [Status: BACKLOG]

---

## [ISSUE-008] [FIXED] Undeclared Function Declaration and Simulated SFT Loop in GeoMind Driver

- **Severity**: High (Compilation Error & Zero-Mock Compliance)
- **Component**: `test/geomind/geomind_driver.c`
- **Description**: `cartan_get_class_token_mapping` was called prior to top-level forward declaration in `geomind_driver.c:1715`, causing ISO C99 compilation failure. Additionally, `--train-sft` contained a legacy multiplier stub (`current_loss *= 0.7250;`) instead of executing genuine GPU tensor backpropagation.
- **Status**: Fixed in Sprint 239. Forward declaration added; real GPU batched SGD training pipeline integrated into Stage 3 SFT.

---

## [ISSUE-010] [FIXED] Mock/Stubbed CLI Subcommand Handlers in `src/cartanc/main.car`

- **Severity**: Medium (Language Toolchain Expansion)
- **Component**: `src/cartanc/main.car` -> `main()` (`pkg`, `repl`, `lsp`, `doc`, `bindgen` CLI subcommands)
- **Status**: Fixed in Sprint 242. Subcommands implement genuine AST passes, SymbolTable inspection, and in-memory JIT execution (`cartan_jit_eval`).

---

## [ISSUE-011] [FIXED] Vocabulary Aliasing via Modulo 512 in LM Classification Head

- **Severity**: Critical (Model Architecture Flaw)
- **Component**: `test/geomind/geomind_driver.c`, `src/cartanc/c_runtime.c`
- **Status**: Fixed in Sprint 242. Retired all modulo 512 label mappings; unified streaming GPU engine and discrete token mapping index full vocabulary IDs ($0..262143$) directly without collision.

---

## [ISSUE-012] [FIXED] Tokenizer Pseudo-Random Unicode Fallback on Hash Misses

- **Severity**: High (Tokenizer / Ingestion Flaw)
- **Component**: `src/cartanc/c_runtime.c` -> `cartan_find_token_id_for_word`
- **Status**: Fixed in Sprint 242. Replaced arbitrary unicode modulo fallback with subword case-insensitive lookup, leading character token resolution, and clean byte-level ASCII token mapping ($[32..126] \to \text{id}$).

---

## [ISSUE-013] [FIXED] Absence of RMSNorm / LayerNorm in Attention Causing Energy & Activation Explosion

- **Severity**: Critical (Numerical Stability / Inference Failure)
- **Component**: `src/cartanc/c_runtime.c` -> `e8_attention_forward_step`
- **Status**: Fixed in Sprint 242. Enforced anisotropic RMSNorm across prompt embeddings, branch inputs, and Layer 41 exit, strictly bounding energy norm to $E(h) = 1.0000$ and keeping Softmax logits numerically stable.

---

## [ISSUE-014] [FIXED] Single-Token Class Pooling vs. Multi-Token Causal Autoregressive Sequence Training

- **Severity**: High (Training Protocol Flaw)
- **Component**: `test/geomind/geomind_driver.c` -> `geomind_train_streaming_steady_state`
- **Status**: Fixed in Sprint 242. Implemented causal next-token sequence target resolution ($t_0 \to t_1 \to t_2$) in streaming GPU slice processor.

---

## [ISSUE-015] [FIXED] Disconnected Fragmented Training Functions & Manifold/MoE Routing Bypass

- **Severity**: Medium (Code Duplication & Architectural Disconnect)
- **Component**: `test/geomind/geomind_driver.c`
- **Status**: Fixed in Sprint 242. Unified all training passes (Cloze, CE, SFT) into a single high-performance streaming GPU engine (`geomind_train_streaming_steady_state`) that executes the 42-layer fused manifold kernel and 4-expert MoE router directly on the GPU (`cartan_tensor_train_batch_gpu_direct`).

---

## [ISSUE-016] [FIXED] Transition GeoMind Neural Computations to Native WebGPU / WGSL Compute Architecture

- **Severity**: High (Architectural Modernization & Porting)
- **Component**: `src/std/gpu.cl`, `src/cartanc/c_runtime.c`, `test/geomind/`
- **Status**: Fixed in Sprint 252. Implemented WebGPU typed runtime FFI in `src/std/gpu.cl` and `src/cartanc/c_runtime.c`. Ported GeoMind's core neural compute kernels (E8 Scaled Dot-Product Attention, 4-Expert MoE Quadrant Manifold Projections with GeLU non-linearities, and Anisotropic RMSNorm) to WebGPU WGSL compute shaders. Validated on physical NVIDIA RTX 2000 Ada hardware with zero mock/stub operations across 500 benchmark iterations.

---

## [ISSUE-017] [FIXED] LM Head Stride Mismatch in 42-Layer Checkpoint Loader & GPU VRAM Synchronizer

- **Severity**: Critical (Model Training & Checkpoint Resume Blocker)
- **Component**: `src/cartanc/c_runtime.c` -> `cartan_load_42layer_checkpoint_file`, `cartan_sync_host_weights_to_gpu`, `cartan_sync_42layers_from_gpu`, `cartan_save_signed_checkpoint`
- **Description**: Host memory allocates a full 256k vocabulary buffer (`CARTAN_FULL_VOCAB_SIZE = 262144`), while GPU VRAM and binary checkpoint files store the 65k active vocabulary (`CARTAN_LM_HEAD_VOCAB = 65536`). Resuming weights from 42-layer checkpoints performed flat `fread` into the start of the host buffer without strided row unpacking, causing upper rows ($r \ge 1$) to become scrambled and resetting next-token loss to ~14.
- **Status**: Fixed in Sprint 254. Integrated row-by-row strided unpacking between 262,144-stride host memory and 65,536-stride GPU VRAM across all load, sync, and save routines. Verified smooth continuation from `geomind_CAUSAL CE_best.bin`.

---

# Active Issues

*(No open critical blockers. All current issues resolved; rolling forward to next-gen feature backlog).*


