# Startup Code Review & System Dependency Tree - Sprint 454

## 1. Executive Summary
- Current State: Stage 1 compiler binary `cartanc.exe` healthy, passes all 63 compiler test suite targets with zero regressions.
- Sprints 450–453 successfully resolved issues 211–224, bringing full freestanding runtime coverage, 30 language primitive keywords, higher-order transforms (`vmap`, `grad`), weight decay regularization, declarative logic (`satisfy`/`backtrack`), native `for` loops, prompt literals `p"..."`, project vocab, authentic `paged_attention`, and exception scoping.
- Code Review Goal for Sprint 454: Uncover dormant stubbed expressions, unlowered AST variants, and missing mathematical/geometric execution kernels across the compiler frontend and freestanding runtime.

---

## 2. Logical Dependency Tree

```
                       [ast.ch] (Canonical AST Grammar & Discriminants)
                        /    \
                       /      \
                      v        v
        [lexer.car] <----+    [type_checker.car] (Scope & Semantic Validation)
             |                 |
             v                 |
        [parser.car] ----------+
             \                 /
              \               /
               v             v
            [core_runtime.car] (Freestanding Math/Memory Kernels)
                     \       /
                      v     v
              [llvm_codegen.car] (LLVM IR Pass & Target Emission)
                     |
                     v
                 [main.car] (CLI Driver & Pipeline Orchestrator)
                     |
                     v
           [cartanc.exe] (Native Self-Hosting Executable)
           /         |          \
          v          v           v
    [run_tests] [std/*.cl] [geomind/*.cl]
```

### Component Analysis:
- `ast.ch`: Single source of truth for all AST node discriminants, token types, and struct layouts. Modifications propagate to lexer, parser, type checker, and codegen.
- `lexer.car`: Tokenizes incoming text streams. Must cleanly distinguish keywords from identifiers with contextual fallbacks.
- `parser.car`: Consumes token stream and constructs AST trees (`Stmt`, `Expr`).
- `core_runtime.car`: Self-hosting runtime implementing tensor math, memory allocations, vector manipulation, and domain-specific geometric operations. Emitted directly into LLVM IR by `llvm_codegen.car`.
- `type_checker.car`: Scoped type analysis validating variable existence, field types, and operator contracts.
- `llvm_codegen.car`: Lowers AST into LLVM IR basic blocks, manages symbol lookup dictionaries, and emits LLVM SSA registers. Must avoid non-dominating stack allocations (`alloca`) in conditional basic blocks.
- `main.car`: Drives compiler CLI subcommands (`build`, `run`, `repl`, `bindgen`, `doc`, `lsp`).

---

## 3. Discoveries & Technical Debt Identified

### [ISSUE-225] Unimplemented `Expr::MSELoss` across Runtime, Type Checker & Codegen
- **Component**: `src/cartanc/parser.car:1620`, `src/cartanc/type_checker.car`, `src/cartanc/llvm_codegen.car`, `src/cartanc/core_runtime.car`
- **Finding**: `parser.car` parses `mse_loss(pred, target)` into `Expr::MSELoss(arg0, arg1)`. However, `core_runtime.car` lacks `cartan_tensor_mse_loss`, `type_checker.car` does not validate it, and `llvm_codegen.car` drops it (returning `"0.0"`).
- **Required**: Implement genuine $\frac{1}{N}\sum (\hat{y}_i - y_i)^2$ in `core_runtime.car`, add type checking, and lower to `@cartan_tensor_mse_loss`.

### [ISSUE-226] Unimplemented `Expr::ParallelTransport` across Runtime, Type Checker & Codegen
- **Component**: `src/cartanc/parser.car:1683`, `src/cartanc/type_checker.car`, `src/cartanc/llvm_codegen.car`, `src/cartanc/core_runtime.car`
- **Finding**: `parser.car` parses `parallel_transport(v, from, to)` into `Expr::ParallelTransport(v, from, to)`. `core_runtime.car` lacks `cartan_tensor_parallel_transport`, `type_checker.car` lacks validation, and `llvm_codegen.car` lacks lowering.
- **Required**: Implement authentic Riemannian parallel transport rotating tangent vectors along geodesic paths in `core_runtime.car`, add type checking, and lower in `llvm_codegen.car`.

### [ISSUE-227] Missing `TokenizeBPE` & `AlignSpans` Runtime Implementations & Lowering Handlers
- **Component**: `src/cartanc/llvm_codegen.car:537-538`, `src/cartanc/core_runtime.car`, `src/cartanc/type_checker.car`
- **Finding**: `llvm_codegen.car` declares extern prototypes `@cartan_tokenize_bpe` and `@cartan_align_spans`, but neither is implemented in `core_runtime.car`, and neither expression discriminant is lowered in `llvm_visit_expr`.
- **Required**: Implement authentic BPE byte pair encoding and span alignment in `core_runtime.car` and wire lowering handlers in `llvm_codegen.car`.

### [ISSUE-228] Unhandled `TreeSearch` (`search(MCTS)`) Expression Lowering
- **Component**: `src/cartanc/parser.car:2006`, `src/cartanc/llvm_codegen.car`, `src/cartanc/core_runtime.car`
- **Finding**: `parser.car` parses `search(tree, algorithm, state)` into `Expr::TreeSearch(tree, algorithm, state)`. `core_runtime.car` lacks `cartan_tree_search` and `llvm_codegen.car` returns `"0.0"`.
- **Required**: Implement tree search traversal in `core_runtime.car` and lower in `llvm_codegen.car`.

---

## 4. Next Steps
1. Log issues `[ISSUE-225]` through `[ISSUE-228]` into `ISSUES.md`.
2. Hold pre-sprint scrum with Rick.
3. Formulate Sprint 454 plan and task list.
