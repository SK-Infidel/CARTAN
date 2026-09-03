# Implementation Plan: Finalizing Native Self-Hosting Parity (`cartanc.exe`)

## Root Cause Analysis
1. **Nesting Mismatches (Resolved)**:
   - Nested brace leaks in `llvm_visit_stmt` and `llvm_visit_expr` previously bypassed statement and expression code generation. With braces leveled, `@add` compiles cleanly to valid vectorized LLVM IR.
2. **SSA Register Inversion in `printf` Lowering**:
   - In `src/cartanc/llvm_codegen.car:2104-2110`, `res_reg` is allocated (`next_reg`, e.g. `%8`) before `i32_reg` (`next_reg`, e.g. `%9`).
   - The emitted IR places `%9 = call i32 @printf` before `%8 = sitofp i32 %9`, violating LLVM's monotonic SSA numbering rule.
3. **User Function Emission Order & Return Value**:
   - Non-intrinsic calls in `user_main` must emit `call double @add(...)` with the properly sequenced register result.

---

## Proposed Changes

### [`src/cartanc/llvm_codegen.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car)
1. **Fix SSA Allocation Order in `printf` Lowering (lines 2104–2111)**:
   - Allocate `i32_reg` first, then allocate `res_reg`, ensuring monotonically increasing LLVM SSA numbers:
     ```cartan
     if (cartan_string_eq(name, "printf") != 0.0) {
         let i32_reg = next_reg(self_ptr);
         let res_reg = next_reg(self_ptr);
         cartan_tree_push(self_ptr.output, cartan_string_concat(cartan_string_concat(cartan_string_concat(cartan_string_concat("  ", i32_reg), " = call i32 (ptr, ...) @printf("), arg_str), ")\n"));
         cartan_tree_push(self_ptr.output, cartan_string_concat(cartan_string_concat(cartan_string_concat(cartan_string_concat("  ", res_reg), " = sitofp i32 "), i32_reg), " to double\n"));
         return res_reg;
     }
     ```
2. **Verify User-Defined Call Lowering (lines 2113–2150)**:
   - For all non-printf calls (e.g. `add(...)`), ensure `next_reg(self_ptr)` is allocated immediately before the call line and returned directly.

---

## Verification Plan
1. Recompile `cartanc.exe` via `cartanc_boot.exe`:
   ```powershell
   .\cartanc_boot.exe build src/cartanc/main.car -o cartanc.exe
   ```
2. Compile `test/test_add.car` using native `cartanc.exe`:
   ```powershell
   .\cartanc.exe build test/test_add.car -o bin/test_add.exe
   ```
3. Run `.\bin\test_add.exe` and verify output:
   `Result: 42.000000`
