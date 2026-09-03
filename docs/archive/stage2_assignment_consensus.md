# Compiler Core Squad Consensus: Stage-2 Assignment & WhileStmt Fix

## 1. Problem Statement
During Stage-2 self-compilation (`cartanc.exe build src/cartanc/main.car -o cartanc_stage2.exe`), the compiler generated `cartanc_stage2.ll` (1390 lines of LLVM IR), but Zig rejected it with:
```text
cartanc_stage2.ll:141:25: error: '%25' defined with type '' but expected ''
  141 |   %26 = fadd float 0.0, %25
  142 |   br label %while_cond_1, !llvm.loop !ptosi float
```

## 2. Root Cause Analysis
1. **`Expr::Assignment` vs `Expr::UnaryOp` Discriminant Clash**:
   - In [`src/cartanc/ast.ch:79,86`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/ast.ch#L79):
     - Variant 15 is `UnaryOp(string, ptr)`.
     - Variant 22 is `Assignment(ptr, ptr)`.
   - In [`src/cartanc/llvm_codegen.car:1986`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L1986):
     `if (disc == 22.0)` was wrongly mapped to `UnaryOp` and emitted `fadd float 0.0, rhs`.
   - Because `Expr::Assignment` is variant 22, assignments like `i = i + 1.0;` were compiled as unary operations, outputting `%26 = fadd float 0.0, %25` instead of `store double %25, ptr %ptr_reg`, and leaving loop variables un-updated.
   - `UnaryOp` was also emitting single-precision `float` instead of `double`.

2. **`WhileStmt` Out-of-Bounds SIMD Loop Metadata**:
   - In [`src/cartanc/ast.ch:135`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/ast.ch#L135), `WhileStmt(ptr, ptr)` has only 2 fields (condition at 1.0, body at 2.0).
   - In [`src/cartanc/llvm_codegen.car:1093`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L1093), `let is_simd = cartan_tree_get_f32(stmt, 3.0);` read unallocated heap memory past the enum variant payload.
   - This evaluated to non-zero, causing every loop to append corrupt loop metadata (`!llvm.loop !ptosi float`).

## 3. Proposed Fix
1. In [`src/cartanc/llvm_codegen.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car):
   - Change `UnaryOp` to `if (disc == 15.0)` and emit `fsub double 0.0, as_float(...)` / `fadd double 0.0, as_float(...)`.
   - Implement `if (disc == 22.0)` for `Expr::Assignment`: evaluate value, extract target identifier/property, and emit `store ptr` / `store double` to the target address.
   - In `WhileStmt` (lines 1093, 1128-1136), remove `is_simd` and emit clean `br label %cond_label`.
