# Startup Code Review - Sprint 460
**Date:** 2026-09-28  
**Scope:** AST Arity & Type Harmonization, Trait/Impl Discriminant Normalization & Method Lowering (`[ISSUE-249]` through `[ISSUE-251]`)

---

## 1. Executive Summary & Findings
A systematic audit of `src/cartanc/ast.ch`, `src/cartanc/parser.car`, `src/cartanc/type_checker.car`, and `src/cartanc/llvm_codegen.car` identified critical AST node constructor mismatches, a field index inversion in `ImplDecl` type checking, and missing LLVM IR lowering for `ImplDecl` method bodies.

### Major Deficiencies Identified:
1. **AST Constructor Inconsistencies (`src/cartanc/ast.ch:enum Stmt`)**:
   - `LayerDecl`: `ast.ch` declared `(string, string, tree<ptr>, ptr)` but `parser.car` constructs `Stmt::LayerDecl(name, layer_type, dim, activation)` with signature `(string, string, ptr, string)`.
   - `StreamDecl`: `ast.ch` declared `(string, tree<ptr>)` but `parser.car` constructs `Stmt::StreamDecl(id_expr, manifold_name)` with signature `(ptr, string)`.
   - `TopologyDecl`: `ast.ch` declared `(string, tree<ptr>)` but `parser.car` constructs `Stmt::TopologyDecl(name, body)` with signature `(string, ptr)` where body is a `BlockStmt` pointer.
   - `MeshBlock`: `ast.ch` declared `(string, tree<ptr>)` (arity 2) but `parser.car` constructs `Stmt::MeshBlock(name, strategy, body)` (arity 3) with signature `(string, string, ptr)`.
   - `TreeDecl`: `ast.ch` declared `(string, string, tree<ptr>)` (arity 3) but `parser.car` constructs `Stmt::TreeDecl(name, element_type)` (arity 2) with signature `(string, string)`.
   - `FluidPrecisionBlock`: `ast.ch` declared `(ptr)` (arity 1) but `parser.car` constructs `Stmt::FluidPrecisionBlock(primary, fallback, body)` (arity 3) with signature `(string, string, ptr)`.
   - `SparsityBlock`: `ast.ch` declared `(ptr)` (arity 1) but `parser.car` constructs `Stmt::SparsityBlock(block_size, density, body)` (arity 3) with signature `(ptr, ptr, ptr)`.
2. **Type Checker Scope & Inverted Target Resolution (`src/cartanc/type_checker.car:tc_visit_stmt`)**:
   - `ImplDecl`: Only checked discriminant `34.0`, missing line discriminant `157.0`.
   - Target name lookup in `ImplDecl` read index `1.0` (which is `trait_name`), rather than index `2.0` (`target_name`).
   - `TraitDecl`: Only checked discriminant `33.0`, missing line discriminant `156.0`.
3. **Missing LLVM IR Codegen Lowering for `ImplDecl` (`src/cartanc/llvm_codegen.car:llvm_visit_stmt`)**:
   - `ImplDecl` (`34.0 || 157.0`) had no lowering branch in `llvm_visit_stmt`, causing methods defined inside `impl Struct { ... }` blocks to be silently omitted from the generated LLVM IR module.

---

## 2. Logical Dependency Tree
```
  ┌─────────────────────────────────────────────────────────────┐
  │ src/cartanc/ast.ch:enum Stmt                                │
  │ - Align LayerDecl, StreamDecl, TopologyDecl, MeshBlock,     │
  │   TreeDecl, FluidPrecisionBlock, SparsityBlock ([ISSUE-249])│
  └──────────────────────────────┬──────────────────────────────┘
                                 │
                                 ▼
  ┌─────────────────────────────────────────────────────────────┐
  │ src/cartanc/type_checker.car:tc_visit_stmt                  │
  │ - Dual discriminants for ImplDecl (34/157) and TraitDecl    │
  │   (33/156)                                                  │
  │ - Fix target_name resolution (index 2.0) ([ISSUE-250])      │
  └──────────────────────────────┬──────────────────────────────┘
                                 │
                                 ▼
  ┌─────────────────────────────────────────────────────────────┐
  │ src/cartanc/llvm_codegen.car:llvm_visit_stmt                │
  │ - Implement ImplDecl method compilation and registration    │
  │   ([ISSUE-251])                                             │
  └──────────────────────────────┬──────────────────────────────┘
                                 │
                                 ▼
  ┌─────────────────────────────────────────────────────────────┐
  │ test/compiler_suite/test_impl_trait_methods.car (Target 70)│
  │ - Verify struct impl block methods, self parameter dispatch │
  │   and authentic numeric computations                        │
  └──────────────────────────────┬──────────────────────────────┘
                                 │
                                 ▼
  ┌─────────────────────────────────────────────────────────────┐
  │ test/compiler_suite/run_tests.car (70 Targets)              │
  │ - Rebuild runner and verify 100% clean passes (0 failures)  │
  └─────────────────────────────────────────────────────────────┘
```

---

## 3. Registered Issues
- `[ISSUE-249]`: AST Arity & Signature Mismatch for LayerDecl, StreamDecl, TopologyDecl, MeshBlock, TreeDecl, FluidPrecisionBlock, and SparsityBlock.
- `[ISSUE-250]`: Type Checker Field Inversion & Dual Discriminant Gap for ImplDecl and TraitDecl.
- `[ISSUE-251]`: Missing LLVM IR Lowering for ImplDecl Methods in `llvm_codegen.car`.
