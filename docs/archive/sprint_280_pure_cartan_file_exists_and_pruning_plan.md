# Sprint 280 Implementation Plan: Pure CARTAN `file_exists` and Dead Symbol Pruning

## Goals & Technical Strategy
1. **Prune Unused Externs**:
   - Remove `extern fn cartan_read_config` from [`src/cartanc/ast.ch`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/ast.ch#L212).
   - Remove `cartan_string_to_lowercase` declaration and registered extern from [`src/cartanc/llvm_codegen.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L284,L410).
2. **Pure CARTAN `cartan_file_exists`**:
   - Implement pure CARTAN [`cartan_file_exists`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/main.car) in `src/cartanc/main.car` and `src/std/fs.cl` using libc `fopen` and `fclose`.
   - Remove `extern fn cartan_file_exists` from `src/cartanc/main.car`.
3. **Mark `cartan_read_line` as `CARTAN_WEAK`**:
   - Annotate `cartan_read_line` with `CARTAN_WEAK` in [`src/cartanc/core_runtime.c`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/core_runtime.c#L1967).
4. **Empirical Verification**:
   - Verify 100% bit-for-bit Stage 2 == Stage 3 fixed-point bootstrap parity (`cartanc_stage2.ll` == `cartanc_stage3.ll`).
   - Run all 47 compiler snapshot tests via `.\bin\run_tests.exe`.
   - Update `CHANGELOG.md` and archive sprint retrospective.
