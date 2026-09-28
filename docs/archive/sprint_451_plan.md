# Sprint 451 Plan: Language Keywords & Freestanding Allocator Alignment

**Author**: Rick & Antigravity Pair Programmer  
**Sprint**: 451  
**Goal**: Resolve `[ISSUE-213]`, `[ISSUE-214]`, `[ISSUE-215]`, and `[ISSUE-216]`: restore keyword recognition in `lexer.car`, implement native allocators and lifecycle hooks in `core_runtime.car`, wire `Expr::Quantize` lowering, eliminate standard library dummy artifacts, and add Target 61 to the regression suite.

---

## 1. Scope & Objectives

1. **Resolve `[ISSUE-213]`**: Wire all disconnected keywords into `src/cartanc/lexer.car:check_keyword`:
   - `sequence`, `block`, `lattice`, `layout`, `manifold`, `topology`, `quantize`, `spike`, `neuron`, `satisfy`, `otherwise`, `backtrack`, `supervisor`, `mesh`, `jit`, `lazy`, `unified`, `latent`, `fluid`, `sparsity`, `emit`, `rule`, `knowledge_base`, `fuzzy`, `evolve`, `paged_attention`.
2. **Resolve `[ISSUE-214]`**: Implement native freestanding allocators and hooks in `src/cartanc/core_runtime.car`:
   - `cartan_alloc_sequence(size: float) -> ptr`
   - `cartan_alloc_block(size: float) -> ptr`
   - `cartan_rt_alloc_lattice(lattice_type: float, dim: float) -> ptr`
   - `cartan_rt_alloc_tree(element_type: float) -> ptr`
   - `cartan_alloc_parameter_adam(size: float) -> ptr`
   - `cartan_alloc_parameter_adam_nd(ndim: float, d0: float, d1: float, d2: float, d3: float) -> ptr`
   - `cartan_emit_spike(intensity: float) -> void`
   - `cartan_fluid_precision_start(primary: ptr, fallback: ptr) -> void` / `cartan_fluid_precision_end() -> void`
   - `cartan_sparsity_start(block_size: float, density: float) -> void` / `cartan_sparsity_end() -> void`
   - `cartan_prune_graph(threshold: float) -> void`
   - `cartan_tensor_quantize_int8(target: ptr) -> ptr`
   - Synchronize LLVM extern signatures in `src/cartanc/llvm_codegen.car:485-523` to `double`.
3. **Resolve `[ISSUE-215]`**: Wire `Expr::Quantize` in `type_checker.car:tc_visit_expr` and `llvm_codegen.car:llvm_visit_expr` calling `@cartan_tensor_quantize_int8(target)`.
4. **Resolve `[ISSUE-216]`**: Clean up dead `struct ArgParser` in `src/std/env.cl` and update `azr_evaluate_binary_reward(candidate_code: string) -> float` in `src/std/evolution.cl` to take real candidate code.
5. **Regression Target 61**: Create `test/compiler_suite/test_language_primitives.car` validating `sequence`, `block`, `lattice`, `quantize`, `emit spike`, and `parameter[Adam]`.
6. **Empirical Verification**: Rebuild `cartanc.exe` and execute `build/run_tests.exe` verifying all 61 targets pass with 0 failures (Exit Code 0).
