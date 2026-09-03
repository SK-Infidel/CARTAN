# Compiler Core Squad Consensus: BinaryOp Pointer Comparisons & Register Prefix Stripping

## 1. Discovery
Following the previous fixes (which resolved the WhileStmt and Assignment errors), `cartanc.exe` successfully ran and generated `cartanc_stage2.ll`.
During Zig compilation of `cartanc_stage2.ll`, Zig rejected line 178:
```text
cartanc_stage2.ll:178:21: error: expected value token
  178 |   %43 = fadd double struct:Stmt:%42, 0.0
```

## 2. Root Cause Analysis
1. **Pointer vs Null Comparison in `BinaryOp`**:
   - In [`src/cartanc/main.car:71`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/main.car#L71), the code tests `if (stmt != 0.0)`.
   - `stmt` is an AST node pointer (`struct:Stmt:%42`), while `0.0` represents null.
   - In [`src/cartanc/llvm_codegen.car:2011-2070`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L2011), `BinaryOp` only implements arithmetic (`+`, `-`, `*`, `/`, `@`). It has **no** implementation for comparison operators (`==`, `!=`, `<`, `>`, `<=`, `>=`).
   - Consequently, `stmt != 0.0` fell through into floating-point addition, emitting `%43 = fadd double struct:Stmt:%42, 0.0`.
   - In [`src/archive/llvm_codegen.rs:1980-2070`](file:///C:/Users/rich-/source/repos/CARTAN/src/archive/llvm_codegen.rs#L1980), when `op == "=="` or `op == "!="` and one or both operands are pointers, it emits:
     ```llvm
     %cond = icmp eq/ne ptr %clean_l, %clean_r (or null)
     %res = uitofp i1 %cond to double
     ```
     And for double comparisons, it emits `fcmp oeq/one/olt/ole/ogt/oge double` followed by `uitofp i1 to double`.

2. **Prefix Stripping (`struct:Name:%reg`)**:
   - In [`src/cartanc/llvm_codegen.car:1958`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L1958), struct loads return `struct:TypeName:%reg`.
   - Existing code stripped only `"struct:"`, leaving `TypeName:%reg` (e.g. `Stmt:%42`), which led to invalid LLVM IR like `ptr Stmt:%49` and `fadd double struct:Stmt:%42, 0.0`.
   - Extracting the string after the last colon (`:`) cleanly yields the true LLVM register (`%42`).

## 3. Proposed Fix
1. **Add `cartan_strip_prefix(str)` to [`src/cartanc/c_runtime.c`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/c_runtime.c)**:
   ```c
   CARTAN_WEAK char* cartan_strip_prefix(const char* str) {
       if (!str) return "";
       const char* last_colon = strrchr(str, ':');
       if (last_colon) return (char*)(last_colon + 1);
       return (char*)str;
   }
   ```
   Synchronize `src/cartanc/c_runtime.c` to `~/.cartan/c_runtime.c`.

2. **Update [`src/cartanc/llvm_codegen.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car)**:
   - Add `clean_reg(s)` helper that calls `cartan_strip_prefix(s)`.
   - Replace manual 4-way `cartan_string_replace` calls across codegen with `clean_reg`.
   - In `BinaryOp` (`disc == 16.0`):
     - For `==` and `!=` involving pointers: emit `icmp eq/ne ptr` with `null` fallback, converting result with `uitofp i1 to double`.
     - For numeric comparisons (`==`, `!=`, `<`, `<=`, `>`, `>=`): emit `fcmp` with `uitofp i1 to double`.
     - Retain arithmetic operations (`+`, `-`, `*`, `/`, `@`, `%`) for tensors and doubles.
