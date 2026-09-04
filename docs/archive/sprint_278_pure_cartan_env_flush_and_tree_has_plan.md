# Sprint 278 Implementation Plan: Pure CARTAN Env, Flush, Quote, and Tree Search Module

## Mission & Scope
Continue eliminating C runtime primitives from `core_runtime.c` by porting key runtime functions to pure native CARTAN:
1. **Eliminate `cartan_get_quote` in `src/cartanc/llvm_codegen.car`**:
   - Replace `let q = cartan_get_quote();` with native escaped quote literal `let q = "\"";`.
   - Remove `extern fn cartan_get_quote`.
2. **Implement Pure CARTAN `cartan_get_env` in `src/cartanc/main.car` and `src/std/fs.cl`**:
   - Implement `cartan_get_env` via standard libc `getenv` with null-safety checks.
   - Remove external dependency on `cartan_get_env` in `core_runtime.c`.
3. **Implement Pure CARTAN `cartan_flush` in `src/cartanc/main.car`**:
   - Implement `cartan_flush` via standard libc `fflush(0.0)`.
   - Remove external dependency on `cartan_flush` in `core_runtime.c`.
4. **Implement Pure CARTAN `cartan_tree_has` in `src/cartanc/llvm_codegen.car`**:
   - Implement native linear tree scanner using `cartan_tree_len_f`, `cartan_tree_get_f32`, and `cartan_string_eq`.
   - Remove unused extern declaration in `src/cartanc/main.car`.
5. **Prune Unused Externs**:
   - Remove unused `cartan_arena_alloc` in `src/cartanc/lexer.car`.
6. **Verify Self-Hosting Parity & Test Suite**:
   - Rebuild `cartanc_stage2.exe` and `cartanc_stage3.exe`.
   - Prove 100% bit-for-bit SHA-256 fixed-point parity.
   - Run all 47 regression test targets via `.\bin\run_tests.exe`.

## Definition of Done (DoD)
- [ ] `cartan_get_quote`, `cartan_get_env`, `cartan_flush`, `cartan_tree_has` ported to pure CARTAN.
- [ ] Zero undefined references or build warnings.
- [ ] Bit-for-bit SHA-256 fixed-point parity proven (`cartanc_stage2.ll` == `cartanc_stage3.ll`).
- [ ] All 47 compiler snapshot tests pass.
- [ ] `CHANGELOG.md` updated and sprint retrospective archived.
