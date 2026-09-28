# Sprint 453 Plan: Native `for` Loops, Expression Lowering, Paged Attention & Exception Handling

## 1. Objectives & Scope
Sprint 453 addresses the four core compiler debt items identified during the Sprint 453 startup review:
1. **`[ISSUE-221]` Native `for` Loop (`ForStmt`) across Compiler Pipeline**: Parse `for <var> in <iterable> { <body> }`, provide scope-aware type checking, and emit vectorized LLVM IR loop structures.
2. **`[ISSUE-222]` Unhandled AST Expressions `Expr::ProjectVocab` & `Expr::PromptLiteral`**: Lower `project_vocab(src, tgt)` to `@cartan_project_vocab` and lower prompt literals `p"..."` as global strings.
3. **`[ISSUE-223]` Argument Mismatch & Codegen for `Expr::PagedAttention` & `Expr::Lazy`**: Align 4-argument `PagedAttention` in `parser.car` and implement runtime lowering for paged attention and lazy thunks.
4. **`[ISSUE-224]` Exception Handling (`Throw` Statement & `TryCatch` Fallback)**: Parse `throw <expr>;`, provide type checking, and wire exception propagation in LLVM IR.
5. **Target 63 & Regression Verification**: Author `test/compiler_suite/test_loops_and_primitives.car`, add as Target 63 in `run_tests.car`, and achieve 100% pass across all 63 targets with 0 failures.

---

## 2. Technical Architecture & Implementation Steps

### 2.1 Native `for` Loop Implementation (`[ISSUE-221]`)
- **Parser (`src/cartanc/parser.car`)**:
  - In `statement(self_ptr)`, match token 21.0 (`TokenType::For`).
  - Consume loop variable identifier (`consume(self_ptr, 107.0)`).
  - Consume `in` keyword (token 32.0 / `TokenType::In`).
  - Parse iterable expression via `expression(self_ptr)`.
  - Parse body via `parse_block(self_ptr)`.
  - Return `Stmt::ForStmt(var_name, iterable, body)`.
- **Type Checker (`src/cartanc/type_checker.car`)**:
  - In `tc_visit_stmt`, match discriminant 19.0 (`ForStmt`).
  - Evaluate iterable expression type via `tc_visit_expr`.
  - Push new scope, register loop variable (as `CartanType::Float` or element type), recursively check body statements, pop scope.
- **LLVM Codegen (`src/cartanc/llvm_codegen.car`)**:
  - In `llvm_visit_stmt`, match discriminant 19.0.
  - Lower iterable expression: if vector, evaluate length via `@cartan_vec_len`.
  - Emit loop preheader, condition check (`fcmp ult`), body block, variable load, body statement execution, increment, and loop latch branch back to condition.

### 2.2 Unhandled AST Expressions `ProjectVocab` & `PromptLiteral` (`[ISSUE-222]`)
- **Type Checker (`src/cartanc/type_checker.car`)**:
  - Add `disc == 48.0 || disc == 112.0` (`Expr::ProjectVocab`): check source and target expressions, return `CartanType::Ptr`.
  - Add `disc == 4.0 || disc == 68.0` (`Expr::PromptLiteral`): return `CartanType::String`.
- **LLVM Codegen (`src/cartanc/llvm_codegen.car`)**:
  - In `llvm_visit_expr`, lower `Expr::ProjectVocab` by calling `@cartan_project_vocab(src, tgt)`.
  - Lower `Expr::PromptLiteral` to global string literal pointer.

### 2.3 `PagedAttention` & `Lazy` (`[ISSUE-223]`)
- **Parser (`src/cartanc/parser.car`)**:
  - Support optional 4th argument `block_table` in `paged_attention` matching `ast.ch:111` `PagedAttention(ptr, ptr, ptr, ptr)`.
- **Runtime Kernel (`src/cartanc/core_runtime.car`)**:
  - Implement `cartan_rt_paged_attention(query: ptr, key: ptr, value: ptr, block_table: ptr) -> ptr` computing causal attention over paged KV memory buffers.
- **Codegen (`src/cartanc/llvm_codegen.car`)**:
  - Add extern prototype and lower `Expr::PagedAttention` to `@cartan_rt_paged_attention`.
  - Lower `Expr::Lazy` by evaluating inner expression.

### 2.4 Exception Handling (`[ISSUE-224]`)
- **Parser (`src/cartanc/parser.car`)**:
  - In `statement(self_ptr)`, match token 30.0 (`TokenType::Throw`).
  - Parse thrown expression, consume semicolon, return `Stmt::Throw(expr)`.
- **Type Checker (`src/cartanc/type_checker.car`)**:
  - Handle `disc == 21.0` (`Stmt::Throw`) in `tc_visit_stmt`.
- **LLVM Codegen (`src/cartanc/llvm_codegen.car`)**:
  - In `Stmt::Throw`, print error message and jump to catch block if enclosing try-catch is active, or trigger runtime exit.

---

## 3. Verification Criteria & Definition of Done
- Target 63 (`test/compiler_suite/test_loops_and_primitives.car`) passes all gates empirically.
- Stage 1 self-hosting compiler compilation succeeds via `cartanc.exe`.
- All 63 regression suite targets pass with 0 failures (Exit Code 0).
- `ISSUES.md` updated with issues 221-224 resolved.
- `CHANGELOG.md` updated to `[8.411.0]`.
- Walkthrough archived to `docs/archive/sprint_453_walkthrough.md`.
