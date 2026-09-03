# Compiler Core Squad Consensus: `Stmt::ExternFunctionDecl` Discriminant & ABI

## 1. Discovery
Following the `Token.lexeme` resolution in `parser.car`, `cartanc.exe` compiled through lines 1–1095 of `cartanc_stage2.ll` without any type or syntax errors. At line 1096, Zig reported:
```text
cartanc_stage2.ll:1096:22: error: use of undefined value '@cartan_copy_file'
 1096 |   %634 = call double @cartan_copy_file(ptr @.str.72, ptr %633)
      |                      ^
```

## 2. Root Cause Analysis
1. In [`src/cartanc/ast.ch:132`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/ast.ch#L132):
   - `enum Stmt` defines `ExternFunctionDecl(string, tree<ptr>, string)` as **variant 15.0**.
   - In [`src/cartanc/parser.car:1111`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/parser.car#L1111), `extern fn` creates `Stmt::ExternFunctionDecl` (discriminant `15.0`).
2. In [`src/cartanc/llvm_codegen.car:572`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L572):
   - Pass 1 checks `else if (disc == 48.0)` for extern function declarations!
   - Because `disc == 15.0`, user/module-level `extern fn` declarations were completely skipped, leaving functions like `cartan_copy_file`, `cartan_read_line`, etc. undeclared in the generated LLVM module.
3. ABI Type Precision:
   - CARTAN expressions treat numeric types as `double` (64-bit IEEE-754).
   - In [`src/cartanc/llvm_codegen.car:586, 601`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L586), extern parameters and return types were formatted with `"float"` (32-bit) instead of `"double"`. The call sites in `cartanc_stage2.ll` emit `call double @fn(...)`.

## 3. Proposed Fix
In [`src/cartanc/llvm_codegen.car:572-605`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L572):
1. Change `disc == 48.0` to `disc == 15.0` so Pass 1 processes `Stmt::ExternFunctionDecl`.
2. Map `float` and `int` parameter/return types to `"double"`:
   - Parameters: `if (p_type_name == "float" || p_type_name == "int") { p_type = "double"; }`
   - Return: `if (rt == "float" || rt == "int") { logical_ret = "double"; }`
   - ABI: `if (logical_ret == "double" || logical_ret == "void") { abi_ret = logical_ret; } else { abi_ret = "ptr"; }`
