# Compiler Core Squad Consensus: `sys_get_arg` Duplicate Declaration Resolution

## 1. Discovery
Following the `ExternFunctionDecl` discriminant and ABI fix, Zig successfully parsed almost the entirety of `cartanc_stage2.ll`, stopping at line 1429 (the end of the LLVM IR module):
```text
cartanc_stage2.ll:1429:13: error: invalid redefinition of function 'sys_get_arg'
 1429 | declare ptr @sys_get_arg(double)
      |             ^
```

## 2. Root Cause Analysis
1. In [`src/cartanc/llvm_codegen.car:818-827`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L818), CARTAN defines native wrappers for CLI argument access directly in the LLVM module:
   ```llvm
   define ptr @sys_get_arg(double %index) {
     %res = call ptr @c_sys_get_arg(double %index)
     ret ptr %res
   }
   define double @sys_get_arg_count() {
     %res = call double @c_sys_get_arg_count()
     ret double %res
   }
   ```
2. In [`src/cartanc/main.car:40-41`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/main.car#L40), CARTAN source code declares:
   ```cartan
   extern fn sys_get_arg(idx: float) -> string;
   extern fn sys_get_arg_count() -> float;
   ```
3. In [`src/cartanc/llvm_codegen.car:241-347`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L241), `self_ptr.declared_externs` tracks functions that are already declared or defined by the compiler to prevent emitting duplicate declarations.
   While `c_sys_get_arg` and `c_sys_get_arg_count` are present in `declared_externs`, `sys_get_arg` and `sys_get_arg_count` were missing.
   Consequently, Pass 1 encountered the `extern fn` in `main.car` and emitted `declare ptr @sys_get_arg(double)` and `declare double @sys_get_arg_count()`, conflicting with their earlier definitions.

## 3. Proposed Fix
In [`src/cartanc/llvm_codegen.car:243-245`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L243), add `sys_get_arg` and `sys_get_arg_count` to `declared_externs`:
```cartan
cartan_tree_push(declared_externs, "sys_get_arg");
cartan_tree_push(declared_externs, "sys_get_arg_count");
```
This informs Pass 1 that these symbols are already defined by the compiler runtime, suppressing redundant `declare` statements.
