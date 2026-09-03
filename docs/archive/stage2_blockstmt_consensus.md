# Compiler Core Squad Consensus: Stage-2 Self-Compilation Crash Fix

## 1. Root Cause Analysis
During Stage-2 self-compilation (`cartanc.exe build src/cartanc/main.car -o cartanc_stage2.exe`), the compiler encountered `0xC000001D` (`STATUS_ILLEGAL_INSTRUCTION`) at `cartan_is_tree_obj`:

1. **`BlockStmt` Field Index Mismatch**:
   In [`src/cartanc/ast.ch:208`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/ast.ch#L208), `struct BlockStmt { statements: tree<ptr>; }` has exactly one field, located at offset 0 (`0.0`).
   [`src/cartanc/type_checker.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/type_checker.car#L334) correctly accesses it via `cartan_tree_get_f32(then_block, 0.0)`.
   However, in [`src/cartanc/llvm_codegen.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L1069), eleven block unwrapping sites used index `1.0`:
   - Line 1069 (`IfStmt` then branch)
   - Line 1080 (`IfStmt` else branch)
   - Line 1115 (`WhileStmt` body)
   - Line 1326 (`ForStmt` body)
   - Line 1565 (`TryCatch` try block)
   - Lines 1576, 1601, 1618, 1651, 1686, 1701 (`Block` variants)
   Accessing index `1.0` reads past the single-word allocation of `BlockStmt`, producing a wild/out-of-bounds pointer for the statement lists.

2. **Runtime Trap on Wild Pointer**:
   In [`src/cartanc/c_runtime.c:1009`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/c_runtime.c#L1009), `cartan_tree_len_f` contained:
   ```c
   int kind = cartan_is_tree_obj(t);
   if (kind == 1) return (double)((CartanTree*)t)->size;
   if (kind == 2) return (double)((uint64_t*)t)[2];
   return (double)cartan_tree_len(t);
   ```
   When `kind == 0` (not a valid tree), falling back to `cartan_tree_len(t)` called the Rust symbol in `gpu_runtime.lib`, which emitted `ud2` (`0xC000001D` Illegal Instruction) when attempting to dereference an invalid pointer. If `kind == 0`, it must return `0.0`.

## 2. Proposed Consensus Actions
1. **[`src/cartanc/llvm_codegen.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car)**:
   Change all `cartan_tree_get_f32(block_var, 1.0)` calls on `BlockStmt` to `cartan_tree_get_f32(block_var, 0.0)`.
2. **[`src/cartanc/c_runtime.c:1009`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/c_runtime.c#L1009)**:
   Change `return (double)cartan_tree_len(t);` to `return 0.0;` in `cartan_tree_len_f` when `kind == 0`.
3. Sync `c_runtime.c` to `~/.cartan/c_runtime.c`, rebuild `cartanc.exe` with `cartanc_boot.exe`, and re-run Stage 2 self-compilation.
