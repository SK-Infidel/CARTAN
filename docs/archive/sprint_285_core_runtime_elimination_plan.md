# Sprint 285 Implementation Plan: Eliminating core_runtime.c & Porting Compiler Primitives to Pure CARTAN

## Objectives
1. **Startup Code Review & Dependency Tree Mapping**:
   - Complete architectural audit of all dependencies between compiler pipeline, test harness, and `core_runtime.c`.
   - Document the 17 compiler primitives required for self-hosting without C runtime.
   - Register `ISSUE-021` in `ISSUES.md`.

2. **Fix IndexAccess Pointer & String Byte Semantics in `llvm_codegen.car`**:
   - For `IndexAccess` (`disc == 21.0 || 36.0`):
     - When `self_ptr.current_return_type == "ptr"`, load `ptr` directly instead of truncating through `double`.
     - When indexing a `string` (`cartan_string_starts_with(obj, "string:")`), load `i8` byte directly and cast to `double` for ASCII character value.
   - In Pass 1 extern declarations, check `user_defined_names` to prevent duplicate `declare` for functions with native CARTAN definitions.

3. **Port Core Compiler Primitives to Pure CARTAN**:
   - Strings: `cartan_string_concat`, `cartan_string_eq`, `cartan_string_substring`, `cartan_string_replace`, `cartan_int_to_string`, `cartan_float_to_string`, `cartan_strip_prefix`, `cartan_llvm_format_string_literal`.
   - Collections: `cartan_tree_create`, `cartan_tree_push`, `cartan_tree_len_f`, `cartan_tree_get_f32`, `cartan_tree_set`, `cartan_tree_remove`, `cartan_tree_write_file`.
   - System: `cartan_assert`, `cartan_read_line`, `cartan_flush`.
   - Math folding: `cartan_tensor_add`, `cartan_tensor_sub`, `cartan_tensor_mul`, `cartan_tensor_div`.

4. **Eliminate `core_runtime.c` & Deprecation Rename**:
   - Update `src/cartanc/c_runtime.c` to remove `#include "core_runtime.c"`.
   - Rename `src/cartanc/core_runtime.c` to `src/cartanc/core_runtime.c.deprecated`.

5. **Empirical Bootstrap & Regression Verification**:
   - 3-Stage self-hosting compiler bootstrap:
     - `cartanc.exe` builds `cartanc_stage2.exe`
     - `cartanc_stage2.exe` builds `cartanc_stage3.exe`
     - Verify bit-for-bit parity: `cartanc_stage2.ll` == `cartanc_stage3.ll`.
   - Execute all 47 compiler regression tests in `test/compiler_suite/run_tests.car`.
   - Update `CHANGELOG.md` and retrospective artifact.
