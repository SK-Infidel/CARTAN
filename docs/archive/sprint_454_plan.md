# Sprint 454 Plan: Geometric Transport, MSE Loss, BPE Tokenization, & Tree Search Execution

## 1. Objectives & Scope
Sprint 454 resolves four identified compiler expressions and freestanding runtime gaps (`[ISSUE-225]` through `[ISSUE-228]`):
1. **Mean Squared Error Loss (`Expr::MSELoss`, `[ISSUE-225]`)**:
   - Implement `cartan_tensor_mse_loss(pred: ptr, target: ptr) -> float` in `src/cartanc/core_runtime.car` calculating genuine $\frac{1}{N}\sum (\hat{y}_i - y_i)^2$.
   - Add type checking in `src/cartanc/type_checker.car` returning `CartanType::Float`.
   - Lower `Expr::MSELoss` in `src/cartanc/llvm_codegen.car:llvm_visit_expr` to call `@cartan_tensor_mse_loss`.
2. **Riemannian Parallel Transport (`Expr::ParallelTransport`, `[ISSUE-226]`)**:
   - Implement `cartan_tensor_parallel_transport(v: ptr, p_from: ptr, p_to: ptr) -> ptr` in `src/cartanc/core_runtime.car` applying geodesic direction alignment and curvature rotation.
   - Add type checking in `src/cartanc/type_checker.car` returning `CartanType::Tensor`.
   - Lower `Expr::ParallelTransport` in `src/cartanc/llvm_codegen.car:llvm_visit_expr` calling `@cartan_tensor_parallel_transport`.
3. **Byte Pair Encoding & Span Alignment (`Expr::TokenizeBPE` & `Expr::AlignSpans`, `[ISSUE-227]`)**:
   - Implement authentic BPE merge encoding `cartan_tokenize_bpe(text: string, vocab_path: string) -> ptr` in `src/cartanc/core_runtime.car`.
   - Implement authentic span index mapping `cartan_align_spans(src_spans: ptr, tgt_spans: ptr, out_map: ptr)` in `src/cartanc/core_runtime.car`.
   - Lower `Expr::TokenizeBPE` (disc 31.0) and `Expr::AlignSpans` (disc 32.0) in `src/cartanc/llvm_codegen.car`.
4. **Tree Search Execution Engine (`Expr::TreeSearch`, `[ISSUE-228]`)**:
   - Implement `cartan_tree_search(tree_ptr: ptr, algorithm: string, state_ptr: ptr) -> ptr` in `src/cartanc/core_runtime.car` executing greedy/A* / MCTS state expansion.
   - Lower `Expr::TreeSearch` (disc 33.0) in `src/cartanc/llvm_codegen.car:llvm_visit_expr`.
5. **Regression Verification & Suite Expansion**:
   - Author regression Target 64: `test/compiler_suite/test_geometric_and_search_primitives.car`.
   - Register Target 64 in `test/compiler_suite/run_tests.car` and whitelist in `.gitignore`.
   - Rebuild self-hosting `cartanc.exe` and confirm 64/64 clean passes.

---

## 2. Squad Roles & Assignments
- **Compiler Core Squad (`cartan-compiler-engineer`)**: AST lowering in `llvm_codegen.car` and type rules in `type_checker.car`.
- **Runtime & Hardware Squad (`cartan_runtime_engineer`)**: Genuine runtime kernels in `core_runtime.car`.
- **Architecture & Geometry Squad (`cartan-architect`)**: Mathematical integrity of Riemannian parallel transport and MSE loss.
- **QA & Benchmark Squad (`cartan-qa-tester`)**: Regression Target 64 authoring and 64-target suite execution.
