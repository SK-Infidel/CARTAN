# Sprint 488 Plan: Phase 4 Integrity — Eradicating Linker Traps, Fake Concurrency, Hardcoded Mocks & Toy Math

## 1. Executive Summary & Goals
In this sprint, we execute Phase 4 of the Codebase Integrity Master Plan, systematically eradicating the technical debt, linker traps, fake concurrency abstractions, hardcoded mock structures, and toy mathematical formulas identified during the post-Sprint 487 forensic audit ([`[ISSUE-307]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md) through [`[ISSUE-313]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md)). Every primitive in CARTAN must perform genuine operations, calculations, and allocations.

---

## 2. Architecture & Gate Breakdown

### Gate 1: Autodiff `backward` Linker Trap Resolution ([`[ISSUE-307]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md))
- **Problem**: In [`src/cartanc/llvm_codegen.car:2067-2075`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L2067-L2075), the `backward loss;` statement emits calls to `@cartan_tensor_backward(ptr)` and `@cartan_tensor_step(double)`, but neither function exists in [`src/cartanc/core_runtime.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/core_runtime.car), causing linker failures if used.
- **Solution**:
  1. Implement `@cartan_tensor_backward(target: ptr) -> void` in `core_runtime.car` executing authentic gradient propagation via `cartan_rt_transform("grad", target)`.
  2. Implement `@cartan_tensor_step(lr: float) -> void` in `core_runtime.car` applying parameter updates ($W = W - \eta \cdot \nabla W$) with weight decay and bounds checking.
  3. Author verification test ensuring `backward loss;` compiles, links, and runs cleanly.

### Gate 2: Authentic Concurrency & Actor Spawning ([`[ISSUE-308]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md))
- **Problem**: `cartan_async_spawn`, `cartan_async_yield`, and `cartan_async_await` in `core_runtime.car` merely increment a float counter `g_async_task_counter`, while `llvm_codegen.car:2347-2365` executes `spawn` blocks synchronously on the current thread.
- **Solution**:
  1. Port `cartan_async_spawn` to execute function pointers on authentic background OS threads using the native C-ABI (`CreateThread` on Windows / `pthread_create` on Linux).
  2. Implement thread synchronization in `cartan_async_await` using OS thread join / `WaitForSingleObject`.
  3. Ensure `spawn Actor { ... }` runs genuinely asynchronous workloads.

### Gate 3: Eradicate Hardcoded Mocks & Constant Primitives ([`[ISSUE-309]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md))
- **Problem**:
  - `cartan_reflect_repo()` returns a static array with hardcoded strings `["CARTAN_ACTIVE_GRAPH", "ACTIVE", "EPOCH_456"]`.
  - `cartan_init_fractal_attention()` returns `[[1.0, 0.5, 0.25], "FRACTAL_ATTENTION_HIERARCHY"]`.
  - `SpikePrimitive` and `NeuronPrimitive` lower to string constant `"1.0"`.
  - `SievingCacheInit` and `ElasticVocabularyInit` lower to empty tree allocations.
- **Solution**:
  1. Upgrade `cartan_reflect_repo()` to perform real filesystem directory inspection via `opendir` or count source files/symbols dynamically.
  2. Implement genuine hierarchical multi-resolution scaling in `cartan_init_fractal_attention()`.
  3. Implement authentic threshold-based leaky integrate-and-fire (LIF) stateful primitives for spikes and neurons.

### Gate 4: Replace Toy Formulas with Authentic Standard Library Integrations ([`[ISSUE-310]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md))
- **Problem**:
  - `cartan_tokenize_bpe`: Pushes raw ASCII codes without merges.
  - `cartan_align_spans`: Identity copy ignoring vocabulary arguments.
  - `cartan_lex_and_embed`: Uses `cos(phase) + sin(phase)` formula.
  - `cartan_align_geodesics`: Hardcodes `cos(0.2)` and `sin(0.2)` in a polynomial.
  - `cartan_geometric_bridge`: Computes arbitrary polynomial chord.
  - `cartan_tree_search`: MCTS uses vector length as node value.
- **Solution**:
  1. Wire `cartan_tokenize_bpe` directly to authentic vocabulary lookup and BPE pair merges from `src/std/tokenizer.cl`.
  2. Implement authentic Jaccard / token-overlap span alignment in `cartan_align_spans`.
  3. Endow `cartan_align_geodesics` and `cartan_geometric_bridge` with authentic Killing-Cartan metric tensor geodesic retraction from `src/std/geom.cl`.
  4. Implement authentic MCTS with UCB1 exploration-exploitation tree search over real child nodes.

### Gate 5: Upgrade Circular Regression Test Targets ([`[ISSUE-313]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md))
- **Problem**: Targets 7, 18, 66, and 68 test and assert against the exact mock counters, global flags, and toy trigonometric constants identified in ISSUE-308 through ISSUE-310.
- **Solution**:
  - Rewrite Target 18 (`test_async_coroutines.car`) and Target 68 (`test_async_spawn_evolve.car`) to verify real background thread computation and thread synchronization.
  - Rewrite Target 66 (`test_geometric_bridge_and_reflection.car`) to verify authentic Riemannian metric alignment, real chord geodesic distance, and genuine repository reflection.

### Gate 6: 3-Stage Bootstrap Fixpoint Rebuild & Verification
- Compile `cartanc_stage1.exe` $\to$ `cartanc_fresh.exe` $\to$ `cartanc_stage3.exe`.
- Prove bitwise fixpoint parity: `SHA256(bin/cartanc_fresh.ll) == SHA256(bin/cartanc_stage3.ll)`.
- Promote Stage 2 compiler to root `cartanc.exe`.
- Verify full 87-target compiler regression suite (`tools/run_affected_tests.ps1 -All`).
- Verify unprimed factual chat inference on `build/geomind.exe`.
