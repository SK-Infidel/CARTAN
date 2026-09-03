# Sprint Retrospective: Self-Hosting Compiler Fixpoint Parity & Stage 3 Bootstrap

## Executive Summary
This sprint resolved all remaining memory clobbering, operator parsing, and scope leakage issues in the self-hosting compiler pipeline, achieving **bit-for-bit SHA-256 fixed-point parity** between Stage 2 (`cartanc_stage2.exe`) and Stage 3 (`cartanc_stage3.exe`).

## Root-Cause Discoveries & Resolutions

### 1. 64-Bit Alignment & Struct Memory Clobbering
- **Defect**: Struct fields and enum variants in `src/cartanc/llvm_codegen.car` were emitted as 32-bit `float` instead of 64-bit IEEE `double`.
- **Impact**: `store double` operations wrote 8 bytes into 4-byte slots, corrupting adjacent struct fields (e.g. `Lexer.length` was smashed to `0.0` upon `Lexer.current` initialization, causing premature EOF).
- **Fix**: Standardized LLVM type generation for `%Lexer`, `%Span`, `%Parser`, `%Token` to emit `double`.

### 2. The Empty Operator `&&` Defect
- **Defect**: In `src/cartanc/parser.car:1444`, `fn logical_and` was initializing `let op = "";` instead of `let op = "&&";`.
- **Impact**: In `llvm_codegen.car`, unknown operators fell through to `fadd double` (+). As a consequence, `a && b` was evaluated as floating-point addition (`a + b != 0.0`), rendering `is_alpha` and `is_digit` true for spaces, newlines, and null bytes, triggering an infinite lexer loop.
- **Fix**: Corrected line 1444 to `let op = "&&";`, generating sound LLVM IR `and i1` boolean operations.

### 3. Cross-Function Symbol & Type Cross-Contamination
- **Defect**: `self_ptr.symbols` and `self_ptr.var_types` in `LLVMGenerator` were shared across all functions without isolation. When earlier passes defined variables (such as `var disc: ptr`), `"disc"` remained typed as `"ptr"` in `var_types`. When `llvm_visit_stmt` later declared `let disc = stmt[0]` (a `double`), `cartan_dict_get` looked up `"disc"` and retrieved `"ptr"`, causing `disc` to be loaded as a pointer, cast via `ptrtoint` and `sitofp` to a garbage double (`4.627e18`), failing all discriminant branches.
- **Fix**:
  - Implemented `cartan_dict_clone(dict)` in `src/cartanc/type_checker.car`.
  - Cloned `global_symbols` and freshly initialized `self_ptr.var_types = cartan_tree_create()` at the beginning of each function pass.
  - Explicitly registered `cartan_dict_set(self_ptr.var_types, name, "double")` in the float branch of `VarDecl`.

## Empirical Verification

| Test Target | Compiler | Output | Status |
| :--- | :--- | :--- | :--- |
| `test/test_add.car` | `cartanc_stage2.exe` | `Result: 42.000000` | Verified |
| `test/test_add.car` | `cartanc_stage3.exe` | `Result: 42.000000` | Verified |
| `src/cartanc/main.car` | `cartanc_stage2.exe` -> `cartanc_stage3.exe` | SHA-256 Identical | Verified |
| `test/compiler_suite/test_primitives.car` | `cartanc.exe` (promoted) | `Test Primitives Result: 42.000000` | Verified |
| `test/compiler_suite/test_enums.car` | `cartanc.exe` (promoted) | `Enum variant Fn initialized cleanly.` | Verified |
| `test/compiler_suite/test_optimizer.car` | `cartanc.exe` (promoted) | `Sprint 15 AST Constant Folding & Optimizer Pass verified cleanly!` | Verified |
| `test/compiler_suite/test_static_assert.car` | `cartanc.exe` (promoted) | `[cartanc] Exported C-ABI headers to build/cartan_export.h` | Verified |
