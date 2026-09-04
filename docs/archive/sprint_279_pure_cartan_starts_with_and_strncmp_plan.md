# Sprint 279 Implementation Plan: Pure CARTAN `starts_with` via Direct Libc `strncmp` ABI Lowering

## Scope & Architectural Strategy
Continuing the systematic elimination of `core_runtime.c` C dependencies:
1. **Direct Libc ABI Lowering for `strncmp` (`src/cartanc/llvm_codegen.car`)**:
   - Extend the libc ABI bridge in `llvm_codegen.car` to support `strncmp`:
     - Argument 0: `ptr` (`s1`)
     - Argument 1: `ptr` (`s2`)
     - Argument 2: `i64` (`fptoui double %arg2 to i64`)
     - Return: `sitofp i32 %res to double`
2. **Pure CARTAN `cartan_string_starts_with` (`src/std/string.cl`)**:
   - Implement `cartan_string_starts_with(s, prefix)` in 100% pure CARTAN utilizing direct libc `strlen` and `strncmp`.
   - Safely guards null checks and boundary checks (`slen >= plen`).
3. **Dead Declaration Pruning (`src/cartanc/llvm_codegen.car`)**:
   - Remove unused static prologue declarations:
     - `declare void @cartan_debug_break`
     - `declare ptr @cartan_hash_dict_get`
     - `declare void @cartan_hash_dict_set`
4. **Self-Hosting Fixed-Point Parity Proof & Verification**:
   - Build Stage 2 and Stage 3 compilers.
   - Prove 100% bit-for-bit SHA-256 fixed-point parity (`cartanc_stage2.ll` == `cartanc_stage3.ll`).
   - Run all 47 regression test targets via `.\bin\run_tests.exe`.

## Definition of Done (DoD)
- [ ] `strncmp` lowered with exact C ABI calling convention.
- [ ] `cartan_string_starts_with` running in pure CARTAN.
- [ ] Dead extern declarations pruned from `llvm_codegen.car`.
- [ ] Bit-for-bit SHA-256 fixed-point parity proven.
- [ ] All 47 compiler snapshot tests pass.
- [ ] `CHANGELOG.md` updated and sprint retrospective archived.
