# Sprint 488 Task List: Phase 4 Integrity — Eradicating Linker Traps, Fake Concurrency, Hardcoded Mocks & Toy Math

## Gate 1: Autodiff `backward` Linker Trap Resolution ([`[ISSUE-307]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md))
- [x] Implement `cartan_tensor_backward(target: ptr) -> void` in [`src/cartanc/core_runtime.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/core_runtime.car) using authentic analytical gradient computation.
- [x] Implement `cartan_tensor_step(lr: float) -> void` in [`src/cartanc/core_runtime.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/core_runtime.car) applying parameter gradient stepping.
- [x] Author test target verifying that `backward expr;` compiles, links, and executes without unresolved external symbols.

## Gate 2: Authentic Concurrency & Actor Spawning ([`[ISSUE-308]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md))
- [x] Implement authentic OS thread spawning in `cartan_async_spawn` via C-ABI (`CreateThread` / `pthread_create`) in [`src/cartanc/core_runtime.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/core_runtime.car) and [`src/cartanc/llvm_codegen.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car).
- [x] Implement authentic thread synchronization in `cartan_async_await`.
- [x] Update `spawn` lowering in `llvm_codegen.car` to dispatch genuinely asynchronous worker execution.

## Gate 3: Eradicate Hardcoded Mocks & Constant Primitives ([`[ISSUE-309]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md))
- [x] Upgrade `cartan_reflect_repo()` in [`src/cartanc/core_runtime.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/core_runtime.car) to perform authentic directory/file structure inspection.
- [x] Upgrade `cartan_init_fractal_attention()` to construct authentic multi-scale hierarchical resolution trees.
- [x] Replace `"1.0"` constant lowering for `SpikePrimitive` and `NeuronPrimitive` in [`src/cartanc/llvm_codegen.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car) with real stateful activation primitives.
- [x] Replace empty `cartan_tree_create()` for `SievingCacheInit` and `ElasticVocabularyInit` with authentic data structures.

## Gate 4: Replace Toy Formulas with Authentic Calculations ([`[ISSUE-310]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md))
- [x] Wire `cartan_tokenize_bpe` in [`src/cartanc/core_runtime.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/core_runtime.car) to authentic vocabulary lookup and BPE pair merges from `src/std/tokenizer.cl`.
- [x] Implement authentic span alignment in `cartan_align_spans`.
- [x] Upgrade `cartan_lex_and_embed` to perform real character-trigram / vocabulary embedding projections.
- [x] Upgrade `cartan_align_geodesics` and `cartan_geometric_bridge` to evaluate genuine Killing-Cartan metric tensor geodesic retraction and chord distance.
- [x] Upgrade `cartan_tree_search` to implement authentic Monte Carlo Tree Search over real tree child structures.

## Gate 5: Upgrade Circular Regression Test Targets ([`[ISSUE-313]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md))
- [x] Upgrade Target 18 ([`test/compiler_suite/test_async_coroutines.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/compiler_suite/test_async_coroutines.car)) to verify real thread spawning and result retrieval.
- [x] Upgrade Target 68 ([`test/compiler_suite/test_async_spawn_evolve.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/compiler_suite/test_async_spawn_evolve.car)) to verify asynchronous background mutation.
- [x] Upgrade Target 66 ([`test/compiler_suite/test_geometric_bridge_and_reflection.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/compiler_suite/test_geometric_bridge_and_reflection.car)) to verify authentic Riemannian geodesic metrics and genuine repository reflection.

## Gate 6: 3-Stage Bootstrap Fixpoint Rebuild & Full Regression Clearance
- [x] Compile `cartanc_stage1.exe` with current compiler.
- [x] Compile `cartanc_fresh.exe` with `cartanc_stage1.exe`.
- [x] Compile `cartanc_stage3.exe` with `cartanc_fresh.exe`.
- [x] Prove bitwise fixpoint parity: `SHA256(bin/cartanc_fresh.ll) == SHA256(bin/cartanc_stage3.ll)`.
- [x] Promote Stage 2 compiler to root `cartanc.exe`.
- [x] Verify full 87-target regression test suite (`tools/run_affected_tests.ps1 -All`).
- [x] Verify factual unprimed chat inference on `build/geomind.exe`.
- [x] Update `CHANGELOG.md` and check off tasks.
