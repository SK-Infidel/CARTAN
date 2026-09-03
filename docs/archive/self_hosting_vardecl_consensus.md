# Compiler Core Squad Consensus: Self-Hosting AST Lowering Fix

## Root Cause Identified
In [`src/cartanc/ast.ch:120`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/ast.ch#L120), `Stmt::VarDecl` is declared as:
```cartan
VarDecl(string, float, ptr, string) // (1: name, 2: is_mut, 3: value, 4: type_hint)
```
All consumers ([`src/cartanc/llvm_codegen.car:1216`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L1216), [`src/cartanc/type_checker.car:309`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/type_checker.car#L309), [`src/cartanc/wgsl_codegen.car:169`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/wgsl_codegen.car#L169)) read field 3 as `value`.

However, [`src/cartanc/parser.car:1142`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/parser.car#L1142) constructed `VarDecl` with arguments 3 and 4 swapped:
```cartan
// Before (bug):
return Stmt::VarDecl( name, is_const, type_annotation, value );
```
For `let result = add(40.0, 2.0);`, `type_annotation` is `0.0`. Field 3 received `0.0`, causing `llvm_visit_expr` and `tc_visit_expr` to evaluate `0.0` instead of `add(40.0, 2.0)`.

## Secondary Fix
In [`src/cartanc/llvm_codegen.car:133,143`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L133):
`cartan_tree_len` returns `int` (RAX) while CARTAN reads `XMM0` (`float`), returning `0.0` and causing Pass 1 forward declarations to terminate after 0 iterations. Pass 1 must use `cartan_tree_len_f`.

## Proposed Consensus Edits
1. **[`src/cartanc/parser.car:1142`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/parser.car#L1142)**:
   Change `return Stmt::VarDecl( name, is_const, type_annotation, value );`
   to `return Stmt::VarDecl( name, is_const, value, type_annotation );`.
2. **[`src/cartanc/llvm_codegen.car:133,143`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L133)**:
   Replace `cartan_tree_len(ast)` with `cartan_tree_len_f(ast)` and `cartan_tree_len(fields)` with `cartan_tree_len_f(fields)`.
