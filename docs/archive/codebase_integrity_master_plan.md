# Codebase Integrity & Zero-Mock Master Plan: Purging Stubs, Mocks, Logit Hacks & C Bypasses

## 1. Executive Mission
Rick's mandate:
> *"For everything you found, I want a plan to make it right."*

This plan outlines the systematic eradication of all remaining technical debt, synthetic fallbacks, logit suppression clamps, stubs, and C runtime bypasses across the CARTAN repository. All operations will perform genuine calculations, query authentic databases, and execute through pure native CARTAN primitives.

---

## 2. Inventory of Targets & Mathematical Solutions

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                               MASTER PURGE & UPGRADE ARCHITECTURE                      │
├──────────────────────────┬─────────────────────────────┬───────────────────────────────┤
│ Target Component         │ Current Defect / Stub       │ Authentic CARTAN Architecture │
├──────────────────────────┼─────────────────────────────┼───────────────────────────────┤
│ 1. NSES Fallback Table   │ 40-case `if-else` hardcoded │ Dynamic SQLite & CarGraph CSR │
│    (`nses_pipeline.cl`)  │ strings for missing nodes   │ text query; fail on missing   │
├──────────────────────────┼─────────────────────────────┼───────────────────────────────┤
│ 2. Logit Suppression     │ Step 0 manual clamp on ?,!, │ Prompt scaffold format &      │
│    (`chat.cl`)           │ .,, and concept logit boost │ continuous Hopfield steering  │
├──────────────────────────┼─────────────────────────────┼───────────────────────────────┤
│ 3. Analogy Cosine Search │ `c_cartan_analogy_search`   │ Pure CARTAN parallel GEMV via │
│    (`main.car`, `io.c`)  │ C AVX2 bypass kernel        │ `@cartan_simd_dot_f32`        │
├──────────────────────────┼─────────────────────────────┼───────────────────────────────┤
│ 4. KV Cache & PLE Arenas │ C-allocated 411MB KV cache  │ Native CARTAN static buffers  │
│    (`transformer.cl`)    │ & C PLE projection cache    │ & pure SIMD PLE projection    │
├──────────────────────────┼─────────────────────────────┼───────────────────────────────┤
│ 5. Memory-Mapping        │ Windows `MapViewOfFile` in  │ Generic `cartan_mmap_file`    │
│    (`cartan_native_io.c`)│ custom C wrapper functions  │ compiler LLVM IR intrinsic    │
├──────────────────────────┼─────────────────────────────┼───────────────────────────────┤
│ 6. Core Runtime AD & ONNX│ Fake `1.0 + (v * 0.01)` grad│ Dual-number automatic diff &  │
│    (`core_runtime.car`)  │ & empty stubs (absorb/onnx) │ authentic weight absorption   │
└──────────────────────────┴─────────────────────────────┴───────────────────────────────┘
```

---

## 3. Phased Implementation Roadmap

### Phase 1 (Sprint 484): Inference Purity, Standard Library Hygiene & C Runtime Eradication
- **Purge NSES Hardcoded Fallback String Table**:
  - Delete lines 360–485 in [`src/std/nses_pipeline.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/nses_pipeline.cl).
  - Implement dynamic fallback: if node text is not present in `graph_file.rule_table`, query SQLite cognitive database (`pipe.db`). If still unresolved, log an explicit warning; never inject hardcoded text.
- **Purge Chat Logit Hacks**:
  - Delete lines 1419–1425 in [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl) (manual punctuation clamps `-10000.0`).
  - Rely exclusively on natural prompt structure (`<start_of_turn>user\n...<end_of_turn>\n<start_of_turn>model\n`) and causal attention.
  - Replace arbitrary concept logit boosts with genuine continuous latent manifold conditioning $(h_{\text{conditioned}} = h + \alpha \cdot e_{\text{concept}})$.
- **Port Analogy Search to Pure CARTAN**:
  - Implement `cartan_analogy_search_topk` directly in [`src/std/geom.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/geom.cl) / [`test/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car) using `@cartan_simd_dot_f32`.
  - Delete `c_cartan_analogy_search_topk` from [`src/std/cartan_native_io.c`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/cartan_native_io.c).
- **Port KV Cache & PLE Caches to Pure CARTAN**:
  - Allocate contiguous static KV cache arena directly in [`src/std/transformer.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/transformer.cl) using `malloc` or static buffers.
  - Implement `cartan_update_pli_cache` in pure CARTAN using `@cartan_simd_dot_f32` and `cartan_fast_gelu_tanh`.
- **Implement Generic `cartan_mmap_file` Intrinsic**:
  - Add native zero-copy `cartan_mmap_file(path: string) -> ptr` in [`src/cartanc/llvm_codegen.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car) (using Win32 `CreateFileMapping`/`MapViewOfFile` or POSIX `mmap` directly in LLVM IR).
  - Eliminate all `c_cartan_mmap_*` functions.
- **Dead C Code Purge**:
  - Remove `c_cartan_gqa_causal_attention_f32`, `c_cartan_gemv_f32`, `c_cartan_rmsnorm_f32`, `c_cartan_geglu_mlp_f32`, `c_cartan_ple_gate_f32` from [`src/std/cartan_native_io.c`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/cartan_native_io.c).

---

### Phase 2 (Sprint 485): Compiler Core Autodiff & Authentic Graph Absorption
- **Authentic Dual-Number / Reverse-Mode Autodiff**:
  - Replace toy `1.0 + (v * 0.01)` in [`cartan_rt_transform("grad", target)`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/core_runtime.car#L1646-L1658) with dual-number automatic differentiation ($v + \epsilon \cdot \dot{v}$) or genuine vector adjoint backward passes.
- **Authentic Tensor Weight Absorption**:
  - Implement binary weight reader in [`cartan_absorb_weights`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/core_runtime.car#L1505-L1507) reading `.bin` checkpoint buffers directly into allocated tensor parameters.
- **Structured Sparsity & Precision Dispatch**:
  - Wire [`cartan_sparsity_start`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/core_runtime.car#L1589-L1597) to genuine magnitude-based structured pruning ($|w| < \tau \implies 0$).
  - Wire [`cartan_fluid_precision_start`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/core_runtime.car#L1576-L1585) to genuine FP16/BF16/FP32 precision truncation passes.
- **Fail-Fast Diagnostic for Unimplemented Features**:
  - Update [`cartan_internal_import_onnx`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/core_runtime.car#L1635-L1643) to fail with a clear compile-time error (`Error: ONNX binary ingestion requires compiled cartan-onnx toolchain`) rather than silently returning a hollow mock tree node.

---

### Phase 3 (Sprint 487 - Completed): Standard Library Integrity & Complete C Runtime Elimination
- **Elimination of `cartan_sqlite.c`**:
  - Permanently deleted the final custom C source file `src/std/cartan_sqlite.c` and removed its compilation rule from `tools/zig_wrapper.py`. Zero custom C files remain across the entire repository.
- **Native 64-Bit Pointer Intrinsics & Direct SQLite3 C-ABI**:
  - Implemented `@cartan_ptr_at` and `@cartan_set_ptr` in `llvm_codegen.car`. Registered 14 SQLite3 C-ABI functions with argument/return translations and dynamic `SQLITE_TRANSIENT` handling.
- **Pure CARTAN `sqlite_vec.cl`**:
  - Re-implemented all 26 database routines and all 26 `cartan_sqlite_*` aliases in pure native CARTAN.
- **Cross-Platform Filesystem Operations**:
  - Replaced Win32 `MoveFileExA` in `src/std/fs.cl` with standard ISO C `remove(dst)` and `rename(src, dst)`.
- **Bitwise Fixpoint Convergence & Full Test Clearance**:
  - Proved bit-for-bit 3-stage bootstrap fixpoint convergence (`SHA256: F62C9D21341111A0B9D74D0C3E6088046CE5532E9D5836AA26152D825088DB6E`). Verified all 87 regression test targets and unprimed factual chat inference.

---

### Phase 4 (Sprint 488): Compiler Linker Traps, Fake Concurrency, Hardcoded Mocks & Toy Math Eradication
- **Gate 1: Resolve Autodiff `backward` Linker Trap (`[ISSUE-307]`)**:
  - Implement `@cartan_tensor_backward(ptr)` and `@cartan_tensor_step(double)` in `src/cartanc/core_runtime.car`, or update `llvm_codegen.car` lowering of `Stmt::Backward` to execute `cartan_rt_transform("grad", target)` directly, ensuring leak-free and crash-free execution.
- **Gate 2: Replace Mock Async Primitives & Synchronous Actor Fake (`[ISSUE-308]`)**:
  - Replace `g_async_task_counter` mock in `core_runtime.car:936-960` with authentic OS thread dispatch via C-ABI (`CreateThread` on Windows / `pthread_create` on Linux) or deterministic cooperative fibers; ensure `spawn Actor { ... }` runs asynchronously as intended.
- **Gate 3: Purge Hardcoded Mocks & Constant Primitives (`[ISSUE-309]`)**:
  - Replace static `cartan_reflect_repo()` tree with genuine filesystem/AST introspection.
  - Replace static `cartan_init_fractal_attention()` tree with authentic multi-scale hierarchical attention structure.
  - Implement stateful spike/neuron models in place of constant `"1.0"` emissions in `llvm_codegen.car`.
- **Gate 4: Replace Toy Formulas with Authentic Standard Library Integrations (`[ISSUE-310]`)**:
  - Wire `cartan_tokenize_bpe` to authentic BPE tokenizer from `src/std/tokenizer.cl` rather than pushing raw character ASCII.
  - Implement genuine span alignment in `cartan_align_spans`.
  - Replace toy trigonometric polynomial formulas in `cartan_lex_and_embed`, `cartan_align_geodesics`, `cartan_geometric_bridge`, and `cartan_tree_search` with authentic Riemannian geometry calculations and real MCTS tree evaluation.
- **Gate 5: Circular Regression Test Targets Upgrade (`[ISSUE-313]`)**:
  - Update Targets 7, 18, 66, and 68 to test and verify genuine operations rather than checking against mock counters and hardcoded toy constants.
- **Gate 6: 3-Stage Bootstrap Fixpoint Rebuild & Empirical Verification**:
  - Rebuild `cartanc.exe` across 3 bootstrap stages; prove bitwise fixpoint convergence (`SHA256(fresh.ll) == SHA256(stage3.ll)`).
  - Verify full 87-target compiler regression suite and unprimed neural chat generation.

