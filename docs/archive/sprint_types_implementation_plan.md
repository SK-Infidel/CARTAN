# Comprehensive Sprint Plan: Cartan Types & Semantic Type Checker Implementation

This sprint elevates Cartan's native self-hosted type system in `src/cartanc/` to **100% full alignment** with the **Cartan Language Reference (`docs/LANGUAGE_REFERENCE.md`)** and **Language Specification (`docs/spec.md`)**.

---

## Language Reference Audit & Type System Gap Analysis

Comparing [docs/LANGUAGE_REFERENCE.md](file:///c:/Users/rich-/source/repos/CARTAN/docs/LANGUAGE_REFERENCE.md) and [docs/spec.md](file:///c:/Users/rich-/source/repos/CARTAN/docs/spec.md) against `src/cartanc/types.ch` and `src/cartanc/type_checker.car`, we identified all missing/unimplemented type primitives and type checking capabilities:

| Type Specifier | Category | Status in `types.ch` / `type_checker.car` | Planned Implementation |
| :--- | :--- | :--- | :--- |
| `&T` | Immutable Borrow | ❌ Missing | `CartanType::Borrow(CartanType)` |
| `&mut T` | Mutable Borrow | ❌ Missing | `CartanType::MutBorrow(CartanType)` |
| `tool` | First-class LLM Tool | ❌ Missing | `CartanType::Tool(string)` |
| `fuzzy` | Zadeh Continuum Logic | ❌ Missing | `CartanType::Fuzzy` |
| `complex` / `Complex32` | Photonic Hardware Complex | ❌ Missing | `CartanType::Complex` |
| `under fp16/int8` | Fluid Precision Modifiers | ❌ Missing | Precision attribute on `Tensor` & `Parameter` |
| `obj.field` | Struct Property Resolution | ❌ Returns `Unknown` | Record field types on `StructDecl` & resolve |
| `A @ B` | Matrix Shape Validation | ❌ Blind `left_type` | Verify $M \times K \cdot K \times N \rightarrow M \times N$ |

---

## Proposed Changes

### 1. Type Definitions (`src/cartanc/types.ch`)

#### [MODIFY] [types.ch](file:///c:/Users/rich-/source/repos/CARTAN/src/cartanc/types.ch)
- Add missing enum variants to `CartanType`:
  * `Borrow(CartanType)` for `&T`
  * `MutBorrow(CartanType)` for `&mut T`
  * `Tool(string)` for first-class JSON schema `tool` types
  * `Fuzzy` for Zadeh continuum logic `[0.0, 1.0]`
  * `Complex` for complex numbers (`Complex32`)
  * `Precision` metadata attribute on `Tensor` and `Parameter` (`fp32`, `fp16`, `bf16`, `int8`, `rgb8`).

---

### 2. Type Parser & Checker (`src/cartanc/type_checker.car`)

#### [MODIFY] [type_checker.car](file:///c:/Users/rich-/source/repos/CARTAN/src/cartanc/type_checker.car)
- Clean up stray closing braces on lines 46-48.
- Extend `parse_type_annotation` to parse `&mut T`, `&T`, `tool`, `fuzzy`, `complex`, `dataframe`.
- Implement `struct_fields` registry: store field names and field types when visiting `StructDecl` (`disc == 5.0`).
- Update `visit_expr` for PropertyAccess (`disc == 20.0`) to resolve struct field types dynamically from the struct field registry.
- Update `visit_expr` for BinaryOp `@` (`disc == 16.0`) to verify shape matching for $M \times K$ and $K \times N$ matrices and emit errors if dimensions clash.

---

### 3. Issues Tracking (`ISSUES.md`)

#### [MODIFY] [ISSUES.md](file:///c:/Users/rich-/source/repos/CARTAN/ISSUES.md)
- Marked legacy Geomind issues `[ISSUE-001]`, `[ISSUE-002]`, `[ISSUE-003]` as `[ARCHIVED]`.
- Added `[ISSUE-006]` (Struct Field Type Resolution) and `[ISSUE-007]` (Unimplemented Types from Language Reference).

---

## Verification Plan

### Automated Tests
- Create `scratch/test_types_sprint.car` to test type checking for:
  1. Immutable and Mutable Borrows (`&tensor`, `&mut tensor`)
  2. First-class `tool`, `fuzzy`, `complex`, and `dataframe` primitive annotations
  3. Struct property field type resolution (`obj.field`)
  4. Matrix multiplication shape checking ($2 \times 4 @ 4 \times 8 \rightarrow 2 \times 8$)
- Recompile the Cartan compiler using `release/llvm_codegen.exe src/cartanc/main.car out.ll` to verify self-hosting integrity.

### Manual Verification
- Verify E2E build of `test/` suite.
