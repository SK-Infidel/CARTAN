# Sprint 5 Implementation Plan

## Goal
Execute Sprint 5 in 4 ordered phases:
1. **Phase 1: Memory Safety & Pointer Audit (`c_runtime.c`)**
2. **Phase 2: Snapshot Harness (`BACKLOG-QA-02`)**
3. **Phase 3: DWARF Debugging Metadata (`BACKLOG-005-B`)**
4. **Phase 4: Slice Indexing & Tuple Pattern Matching (`BACKLOG-002`)**

---

## Phase Breakdown

### Phase 1: Memory Safety & Pointer Audit (`c_runtime.c`)
- **Target File**: `src/cartanc/c_runtime.c` & `C:\Users\rich-\.cartan\c_runtime.c`
- **Actions**:
  - Replace unsafe `strstr` fallback in `cartan_tree_has()` with proper container type validation.
  - Implement memory recycling for `cartan_string_concat` during compiler AST expansion.
  - Add NULL guards to pointer lookups.

### Phase 2: Snapshot Harness (`BACKLOG-QA-02`)
- **Target File**: `test/compiler_suite/run_tests.car` & test targets
- **Actions**:
  - Add `// run-pass` and `// compile-fail` directive parsing in `run_tests.car`.
  - Execute generated binaries and verify non-zero exit status for compilation failures.
  - Create negative test targets (`test_fail_typecheck.car`).

### Phase 3: DWARF Debugging Metadata (`BACKLOG-005-B`)
- **Target Files**: `src/cartanc/llvm_codegen.car`, `src/cartanc/parser.car`
- **Actions**:
  - Emit DWARF header metadata (`!llvm.dbg.cu`, `!DIFile`, `!DISubprogram`) at top of generated IR.
  - Attach `!dbg !<loc_id>` attributes to IR statements based on AST `Span` line numbers.

### Phase 4: Slice Indexing & Tuple Pattern Matching (`BACKLOG-002`)
- **Target Files**: `src/cartanc/parser.car`, `src/cartanc/type_checker.car`, `src/cartanc/llvm_codegen.car`, `src/cartanc/c_runtime.c`
- **Actions**:
  - Add range expression parsing `arr[start..end]` and lowering in `c_runtime.c`.
  - Add tuple type parsing `(T1, T2)` and tuple deconstruction assignment `let (a, b) = expr`.
