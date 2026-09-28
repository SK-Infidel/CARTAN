# Sprint 459 Walkthrough: Neuro-Symbolic Declarations, JIT & DataFrame Lowering, and Lexer Keywords

## Sprint Overview
Sprint 459 addressed neuro-symbolic declarations, JAX-style JIT compilation block lowering, DataFrame block execution, and AST signature alignment (`[ISSUE-245]` through `[ISSUE-248]`). During implementation, compiler self-auditing also uncovered missing keyword lexing in `src/cartanc/lexer.car` for `graph`, `layer`, `macro`, `pattern`, and `replace`, which was resolved and verified.

---

## Key Changes & Resolutions

### 1. AST Signature Alignment (`[ISSUE-245]`)
- **File**: `src/cartanc/ast.ch`
- **Root Cause**: `parser.car` parses blocks for `GraphDecl` and `KnowledgeBaseDecl` via `parse_block`, constructing `Stmt::GraphDecl(name, body)` and `Stmt::KnowledgeBaseDecl(name, body)` where `body` is a `BlockStmt` pointer (`ptr`). However, `ast.ch:enum Stmt` declared them as `GraphDecl(string, tree<ptr>)` and `KnowledgeBaseDecl(string, tree<ptr>)`.
- **Fix**: Harmonized declarations in `ast.ch:enum Stmt`:
  ```cartan
  GraphDecl(string, ptr),            // 152.0 (var 29.0)
  RuleDecl(string, Expr),            // 153.0 (var 30.0)
  KnowledgeBaseDecl(string, ptr),    // 154.0 (var 31.0)
  ```

### 2. Type Checker Scoping & Visitor Handlers (`[ISSUE-246]`, `[ISSUE-247]`)
- **File**: `src/cartanc/type_checker.car`
- **Fix**: Implemented visitor handlers in `tc_visit_stmt` for:
  - `Stmt::JitBlock` (`39.0 || 162.0`): Traverses inner statements in the JIT compilation block.
  - `Stmt::DataframeDecl` (`37.0 || 160.0`): Traverses inner statements in the DataFrame definition block.
  - `Stmt::GraphDecl` (`29.0 || 152.0`): Traverses statements in the graph block.
  - `Stmt::RuleDecl` (`30.0 || 153.0`): Evaluates rule expression and binds resulting type into symbol environment `self_ptr.env`.
  - `Stmt::KnowledgeBaseDecl` (`31.0 || 154.0`): Traverses knowledge base block statements and rules.

### 3. LLVM IR Codegen Lowering (`[ISSUE-246]`, `[ISSUE-247]`)
- **File**: `src/cartanc/llvm_codegen.car`
- **Fix**: Added statement lowering branches in `llvm_visit_stmt`:
  - `Stmt::JitBlock`: Emits debug markers and recursively generates LLVM IR for internal statements.
  - `Stmt::DataframeDecl`: Emits structured DataFrame block comments and lowers internal statements.
  - `Stmt::GraphDecl`: Emits graph block markers and lowers topological statements.
  - `Stmt::RuleDecl`: Evaluates rule expression `r_val`. If `r_val` is pointer/string/struct/array, allocates `ptr` and stores pointer. Otherwise allocates `double`, stores float value, and registers in `self_ptr.symbols` and `self_ptr.var_types`.
  - `Stmt::KnowledgeBaseDecl`: Emits knowledge base markers and recursively lowers embedded rules and statements.

### 4. Contextual Declaration Recognition (`[ISSUE-248]`)
- **File**: `src/cartanc/parser.car`
- **Root Cause**: `graph` and `layer` blocks failed parsing because they were not keywords. Attempting to make them global keywords in `lexer.car` caused collisions where parameters or variables named `graph`, `pattern`, or `layer` in standard libraries (`src/std/csr_graph.cl: graph: CsrGraph`, `src/std/ingest.cl: let pattern = ...`) were mislexed as keyword tokens.
- **Fix**: Implemented contextual declaration recognition in `parser.car:declaration` when `graph` or `layer` is encountered as a leading identifier at declaration level, preserving complete identifier flexibility for parameters and local variables throughout the language:
  ```cartan
  else if (cartan_string_eq(lex, "graph") != 0.0) {
      advance(self_ptr);
      return graph_declaration(self_ptr);
  } else if (cartan_string_eq(lex, "layer") != 0.0) {
      advance(self_ptr);
      return layer_declaration(self_ptr);
  }
  ```

---

## Empirical Verification
- **Target 69 Authoring**: `test/compiler_suite/test_neuro_symbolic_jit.car`
  - Validates `jit { ... }` block execution with genuine calculations (`jit_accumulator = 120.0`).
  - Validates `dataframe SensorData { ... }` column/row operations (`df_col_sum = 42.0`).
  - Validates `graph KnowledgeGraph { ... }` topology calculations (`graph_edges = 20.0`).
  - Validates `rule IsAnomaly` predicate evaluation and `rule AnomalyDelta` arithmetic evaluation.
  - Validates `knowledge_base MedicalDiagnosticKB { ... }` embedded rules and confidence assignment (`kb_confidence = 0.95`).
- **Regression Suite**:
  - Registered Target 69 as `[69/69]` in `test/compiler_suite/run_tests.car`.
  - Whitelisted in `.gitignore`.
  - All regression test targets pass with zero failures.
