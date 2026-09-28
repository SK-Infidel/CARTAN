# Sprint 456 Implementation Plan: Geometric Alignment, Bridge, Manifold Embedding, & Repository Reflection

## Executive Summary
Sprint 456 resolves `[ISSUE-233]`, `[ISSUE-234]`, `[ISSUE-235]`, and `[ISSUE-236]`. We will rectify the discriminant collisions for `PropertyAccess` and `IndexAccess` in `llvm_codegen.car`, align AST definitions and constructor arities for `LexAndEmbed` and `Attention`, add `ReflectRepo` to `ast.ch:Expr`, implement authentic runtime operations in `core_runtime.car`, type check all four expressions in `type_checker.car`, and lower them into clean LLVM IR in `llvm_codegen.car`. We will empirically verify the implementation with regression Target 66 (`test/compiler_suite/test_geometric_bridge_and_reflection.car`).

---

## Architecture & Work Breakdown

### Task 1: Resolve Codegen Discriminant Collisions (`[ISSUE-234]`)
- In `src/cartanc/llvm_codegen.car`:
  - Line 2344: change `cartan_tree_push(prop_node, 34.0)` to `cartan_tree_push(prop_node, 20.0)`.
  - Line 2545 & 3128: change `target_disc == 20.0 || target_disc == 34.0` to `20.0 || 84.0`.
  - Line 2598 & 3186: change `target_disc == 21.0 || target_disc == 36.0` to `21.0 || 85.0`.
  - This completely unblocks `34.0` for `LexAndEmbed` and `36.0` for `GeometricBridge`.

### Task 2: AST Arity Alignment & `ReflectRepo` (`[ISSUE-235]`, `[ISSUE-236]`)
- In `src/cartanc/ast.ch`:
  - Line 91: update `Attention(ptr, ptr, ptr, ptr)` to `Attention(ptr, ptr)`.
  - Line 98: update `LexAndEmbed(ptr, ptr)` to `LexAndEmbed(ptr)`.
  - Line 114: add `ReflectRepo` to `enum Expr` (index 50.0, line 114.0).

### Task 3: Core Runtime Primitives (`[ISSUE-233]`, `[ISSUE-235]`)
- In `src/cartanc/core_runtime.car`:
  - Implement `cartan_lex_and_embed(text: string) -> ptr`: Authentic character-level manifold projection into continuous embedding vector.
  - Implement `cartan_align_geodesics(w: ptr, b: ptr) -> ptr`: Authentic Riemannian exponential geodesic combination.
  - Implement `cartan_geometric_bridge(src: ptr, tgt: ptr) -> ptr`: Authentic geometric bridge chord interpolation.
  - Implement `cartan_reflect_repo() -> ptr`: Heap-allocated reflection metadata container with active graph root pointer.
  - Expose export wrappers: `cartan_lex_embed`, `cartan_geodesics_align`, `cartan_geom_bridge`, `cartan_repo_reflect`.

### Task 4: Type Checker Integration (`[ISSUE-233]`, `[ISSUE-235]`)
- In `src/cartanc/type_checker.car:tc_visit_expr`:
  - Update `LexAndEmbed` (`34.0 || 98.0`) to return `CartanType::Tensor(d, 0.0, 0.0)`.
  - Update `AlignGeodesics` (`35.0 || 99.0`) to return `CartanType::Tensor(d, 0.0, 0.0)`.
  - Update `GeometricBridge` (`36.0 || 100.0`) to return `CartanType::Tensor(d, 0.0, 0.0)`.
  - Add `ReflectRepo` (`50.0 || 114.0`) to return `CartanType::Ptr`.

### Task 5: LLVM Codegen Lowering (`[ISSUE-233]`, `[ISSUE-235]`)
- In `src/cartanc/llvm_codegen.car`:
  - Register function return types (`CartanType::Ptr`) and extern prototypes for `@cartan_lex_and_embed`, `@cartan_align_geodesics`, `@cartan_geometric_bridge`, `@cartan_reflect_repo`.
  - Lower `LexAndEmbed` (`34.0 || 98.0`), `AlignGeodesics` (`35.0 || 99.0`), `GeometricBridge` (`36.0 || 100.0`), and `ReflectRepo` (`50.0 || 114.0`).

### Task 6: Author Regression Target 66 & Verify Full Suite
- Author `test/compiler_suite/test_geometric_bridge_and_reflection.car`:
  - Gate 1: `Cartan.lex_and_embed("hello")` produces real, non-zero embedding coordinates.
  - Gate 2: `Cartan.align_geodesics(w, b)` computes accurate geodesic alignment.
  - Gate 3: `Cartan.GeometricBridge(src, tgt)` computes authentic bridge values.
  - Gate 4: `Cartan.reflect_repo()` produces valid non-null reflection container and hot-swaps cleanly.
- Register Target 66 in `test/compiler_suite/run_tests.car` and update `.gitignore`.
- Rebuild self-hosted `cartanc.exe` and execute all 66 test targets.
