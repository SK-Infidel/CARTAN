# Sprint 276 Implementation Plan: Pure Native CLI Argument Lowering & Tree Vector Runtime Module

## Mission & Scope
Continue the systematic elimination of `c_runtime.c` / `core_runtime.c` by:
1. **Lowering `sys_get_arg` and `sys_get_arg_count` to Direct Native LLVM IR**:
   - In [`src/cartanc/llvm_codegen.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car#L818-L827), eliminate calls to `@c_sys_get_arg` and `@c_sys_get_arg_count`.
   - Read directly from `@global_argc` and `@global_argv` using native LLVM GEP and loads.
   - Remove `declare @c_sys_get_arg` and `declare @c_sys_get_arg_count`.
2. **Implementing Pure CARTAN `cartan_tree_` Vector Module in `src/std/collections.cl`**:
   - Provide binary-compatible pure CARTAN implementations of `cartan_tree_create`, `cartan_tree_push`, `cartan_tree_get_f32`, `cartan_tree_len_f`, `cartan_tree_set`, `cartan_tree_remove`.
   - Ensure 32-byte layout compatibility (`[magic/ref_count, size, capacity, data]`) using direct libc `malloc` and `realloc`.
3. **Validating Self-Hosting Fixed-Point Parity**:
   - Build `cartanc_stage2.exe` and `cartanc_stage3.exe`.
   - Verify 100% bit-for-bit SHA-256 identical fixed-point IR hashes.
4. **Validating Test Suite & AI Model Engine**:
   - Run full 47-target regression test suite (`.\bin\run_tests.exe`).
   - Run `.\bin\geomind_native.exe` benchmarks.

## Architecture & Dependency Analysis

```
┌────────────────────────────────────────────────────────┐
│                      main()                            │
│  Emits @global_argc (i32) and @global_argv (ptr)       │
└──────────────────────────┬─────────────────────────────┘
                           │
       ┌───────────────────┴───────────────────┐
       ▼                                       ▼
┌─────────────────────────────┐ ┌─────────────────────────────┐
│ @sys_get_arg(double %index) │ │    @sys_get_arg_count()     │
│ - fptosi double to i32      │ │ - load i32 @global_argc     │
│ - load ptr @global_argv     │ │ - sitofp i32 to double      │
│ - GEP ptr @global_argv, %i  │ │ - ret double                │
│ - load ptr from argv[%i]    │ └─────────────────────────────┘
│ - ret ptr                   │
└─────────────────────────────┘
```

## Definition of Done (DoD)
- [ ] `@sys_get_arg` and `@sys_get_arg_count` lowered to pure native LLVM IR in `llvm_codegen.car`.
- [ ] External dependencies on `c_sys_get_arg` and `c_sys_get_arg_count` removed from `llvm_codegen.car`.
- [ ] Bit-for-bit SHA-256 fixed point verified (`cartanc_stage2.ll` == `cartanc_stage3.ll`).
- [ ] All 47 compiler snapshot tests pass.
- [ ] `CHANGELOG.md` updated and retrospective saved to `docs/archive/`.
