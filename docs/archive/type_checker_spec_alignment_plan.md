# Phase 3: Refactoring `type_checker.car` & Language Spec Alignment

## Goal
To complete the porting of `src/cartanc/type_checker.car` by resolving the final compilation hurdles caused by legacy compiler architecture constraints. In addition to fixing the tree indexing bug, we will fully align the `type_checker.car` and `types.ch` with the **Cartan Language Specification (v0.3.0)** and **Language Reference**, ensuring that all native AI paradigms (cognitive blocks, multidimensional streams, actor concurrency) are natively recognized and type-checked.

## Completed Work
- Replaced Rust `HashMap` logic with `cartan_dict_set` and `cartan_dict_get`.
- Removed all `match` and `if let` blocks, translating them into proper Cartan `if (disc == X.0)` discriminant checks.
- Refactored all Rust string methods to use `cartan_string_substring`, `cartan_string_starts_with`, etc.
- Fixed the legacy compiler (`llvm_codegen.rs`) so that `cartan_string_substring` correctly tags its returned values as `ptr`.

## User Review Required
> [!IMPORTANT]
> **Language Spec Alignment**
> After auditing `ast.ch`, `types.ch`, and `type_checker.car` against the Language Reference and Spec, it is clear that several primitives and AST blocks are missing or incomplete in the type checker. Cartan is not just another language; it is a native tensor, multi-modal, and agent-oriented OS language. We must treat these advanced blocks (e.g., `vmap`, `doubt`, `chain`, `spawn`, `receive`, `dataframe`, etc.) as first-class citizens. I will add type-checking logic for all missing AST discriminants.

## Proposed Changes

---

### `src/cartanc/`

#### [MODIFY] [types.ch](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/types.ch)
- Add `Dataframe` to the `CartanType` enum to support database-like structures.
- Ensure all primitives from Section 1 of the Language Reference are properly mapped to float discriminants.

#### [MODIFY] [type_checker.car](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/type_checker.car)

**1. Refactoring AST Node Access (The Indexing Fix)**
- Run a Python mass-replace script to convert all instances of `array[INDEX]` to `tree_get(array, INDEX)`.
  - For example, `stmt[0]` becomes `tree_get(stmt, 0.0)`.
  - This ensures that all AST inspection strictly uses the `gpu_runtime` dynamic tree logic, completely sidestepping the legacy compiler's stack-array assumptions.

**2. Implementing Missing AST Types**
- Add discriminant handlers `if (disc == X.0)` in `visit_stmt` and `visit_expr` for all remaining `ast.ch` AST nodes that are currently ignored. This includes:
  - **Cognitive & Execution Blocks:** `VmapBlock`, `DoubtBlock`, `ChainBlock`, `RouteBlock`, `GrokBlock`, `OverrideBlock`, `Satisfy`, `Backtrack`.
  - **Concurrency & Streams:** `StreamDecl`, `MultimodalBlock`, `Spawn`, `ReceiveDecl`.
  - **Data Types & Topologies:** `DataframeDecl`, `TopologyDecl`, `LatticeDecl`, `FluidPrecisionBlock`, `SparsityBlock`.
  - **AI Ops:** `PruneGraph`, `EmitSpike`, `ProjectVocab`.
- For block-level statements, the type checker will correctly `push_scope`, recursively type-check the block's `statements` tree, and pop the scope, ensuring safety across agentic memory boundaries.

## Verification Plan

### Automated Tests
- Run `cartanc build src/cartanc/type_checker.car` to verify the refactored Cartan type checker compiles flawlessly through the LLVM generation phase.
- Ensure the newly added AST nodes do not cause discriminant collisions or runtime faults during compilation.
