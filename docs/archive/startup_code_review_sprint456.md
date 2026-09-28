# Comprehensive Pre-Sprint Code Review & Dependency Graph: Sprint 456

**Reviewer:** CARTAN Architecture & Engineering Squad  
**Date:** 2026-09-28  
**Archive:** `docs/archive/startup_code_review_sprint456.md`

---

## 1. Executive Codebase Audit Findings

Following the successful completion of Sprint 455 (authentic GEMM, tensor transposition, dynamic graph hot-swap, and pointer ops), a systemic audit of the CARTAN compiler frontend, AST enum space, type checker, LLVM codegen, and runtime kernel was conducted. Four critical issues were uncovered:

### Finding 1: Unhandled `Expr::LexAndEmbed`, `Expr::AlignGeodesics`, `Expr::GeometricBridge` in Type Checker & LLVM Codegen (`[ISSUE-233]`)
- **Location**: `src/cartanc/parser.car:1705-1718`, `src/cartanc/type_checker.car:459-469`, `src/cartanc/llvm_codegen.car:3504`, `src/cartanc/core_runtime.car`
- **Defect**: `Cartan.lex_and_embed(text)`, `Cartan.align_geodesics(w, b)`, and `Cartan.GeometricBridge(w, b)` are parsed into `Expr::LexAndEmbed`, `Expr::AlignGeodesics`, and `Expr::GeometricBridge`. However:
  1. `type_checker.car:459-469` only checks legacy discriminants (`34.0`, `35.0`, `36.0`) and returns `CartanType::Unknown`, missing dual discriminants (`98.0`, `99.0`, `100.0`).
  2. `llvm_codegen.car` completely lacks lowering blocks for all three expressions, falling through to `return "0.0";`.
  3. `core_runtime.car` lacks all three runtime implementations.
- **Impact**: Any invocation of foundational geometric operations fails type checking or silently returns `"0.0"`.

### Finding 2: Discriminant Collision for `PropertyAccess` & `IndexAccess` in LLVM Codegen (`[ISSUE-234]`)
- **Location**: `src/cartanc/llvm_codegen.car:2344, 2545, 2598, 3128, 3186`
- **Defect**: 
  1. Lines 2545 and 3128 check `disc == 20.0 || disc == 34.0` for `PropertyAccess`. But `34.0` is the enum index of `Expr::LexAndEmbed`! In `ast.ch`, `PropertyAccess` is at line 84.
  2. Lines 2598 and 3186 check `disc == 21.0 || disc == 36.0` for `IndexAccess`. But `36.0` is the enum index of `Expr::GeometricBridge`! In `ast.ch`, `IndexAccess` is at line 85.
  3. Line 2344 pushes synthetic property access node with `34.0` instead of `20.0`.
- **Impact**: When `LexAndEmbed` (34.0) or `GeometricBridge` (36.0) is evaluated, codegen misidentifies them as `PropertyAccess` or `IndexAccess`, causing corrupt LLVM IR emission or compiler crashes.

### Finding 3: Missing `Expr::ReflectRepo` in AST Definition & Type System (`[ISSUE-235]`)
- **Location**: `src/cartanc/parser.car:1730-1734`, `src/cartanc/ast.ch`, `src/cartanc/type_checker.car`, `src/cartanc/llvm_codegen.car`, `src/cartanc/core_runtime.car`
- **Defect**: `Cartan.reflect_repo()` is parsed into `Expr::ReflectRepo;` at line 1732 of `parser.car`, but `ReflectRepo` does not exist in `ast.ch:Expr`. It is also missing from `type_checker.car` and `llvm_codegen.car`.
- **Impact**: Invoking `Cartan.reflect_repo()` breaks AST construction or causes undefined behavior.

### Finding 4: Parameter Arity Mismatches for `LexAndEmbed` and `Attention` (`[ISSUE-236]`)
- **Location**: `src/cartanc/ast.ch:91, 98`, `src/cartanc/parser.car:1580, 1707`
- **Defect**: 
  1. `ast.ch:98` defines `LexAndEmbed(ptr, ptr)` (2 arguments), but `parser.car:1707` constructs `Expr::LexAndEmbed(cartan_tree_get_f32(args, 0.0))` (1 argument).
  2. `ast.ch:91` defines `Attention(ptr, ptr, ptr, ptr)` (4 arguments), but `parser.car:1580` constructs `Expr::Attention(target, routing_val)` (2 arguments).
- **Impact**: Unaligned AST variant memory layouts risk out-of-bounds container accesses when inspecting AST nodes.

---

## 2. Logical Dependency Tree

```
┌────────────────────────────────────────────────────────┐
│                   CARTAN Compiler Core                 │
│  src/cartanc/ast.ch (Enum variant layouts & arities)    │
│  src/cartanc/lexer.car (Tokenization & keywords)        │
│  src/cartanc/parser.car (Grammar & AST node creation)   │
│  src/cartanc/type_checker.car (Type bounds & deduction) │
│  src/cartanc/llvm_codegen.car (LLVM IR lowering)       │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│              Freestanding Core Runtime Kernel          │
│  src/cartanc/core_runtime.car                          │
│   - cartan_lex_and_embed (Manifold text projection)    │
│   - cartan_align_geodesics (Exponential metric align)  │
│   - cartan_geometric_bridge (Riemannian chord bridge)  │
│   - cartan_reflect_repo (Active graph root container)  │
│   - cartan_tensor_matmul_gemm & transpose (from 455)   │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│                  Cartan Standard Library               │
│  src/std/math.cl, tensor.cl, dynamic_graph.cl          │
│  src/std/geom.cl, transformer.cl, fusion.cl            │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│                  Verified Regression Suite             │
│  test/compiler_suite/run_tests.car (Targets 1..65)     │
│  Target 66: test_geometric_bridge_and_reflection.car   │
└────────────────────────────────────────────────────────┘
```

---

## 3. Predicted Effects & Cascade Prevention

1. **Codegen Collision Rectification**:
   - Changing `PropertyAccess` check from `20.0 || 34.0` to `20.0 || 84.0` (and updating line 2344 to emit `20.0`) unblocks `disc == 34.0` exclusively for `LexAndEmbed`.
   - Changing `IndexAccess` check from `21.0 || 36.0` to `21.0 || 85.0` unblocks `disc == 36.0` exclusively for `GeometricBridge`.
   - Prediction: All existing 65 regression targets will continue to pass without regression because `PropertyAccess` and `IndexAccess` will match their correct canonical and line-based discriminants.

2. **AST Arity Alignment**:
   - Aligning `LexAndEmbed(ptr)` to 1 argument matches `parser.car:1707`.
   - Aligning `Attention(ptr, ptr)` to 2 arguments matches `parser.car:1580`.
   - Adding `ReflectRepo` as variant 50 (line 114.0) maintains contiguous discriminant numbering.

3. **Zero-Mock Compliance**:
   - All runtime implementations in `core_runtime.car` will perform genuine mathematical operations: real character-to-vector projections for `lex_and_embed`, authentic Riemannian geodesic combinations for `align_geodesics`, authentic chord embeddings for `geometric_bridge`, and authentic heap containers for `reflect_repo`.
