# Sprint 290 Implementation Plan: Mathematics & Autotuning Engine Hardening

## Goal
Eliminate strict zero-mock violations in the mathematics and model fusion libraries by implementing genuine 2D tiled GEMM matrix multiplication (`[ISSUE-039]`), authentic Bernoulli pseudo-random dropout sampling in DARE weight fusion (`[ISSUE-042]`), unified tensor allocation and reductions in core runtime, and polymorphic tree/vector compatibility.

## Target Changes
1. **`[ISSUE-039]` Authentic 2D Tiled GEMM Matrix Multiplication (`src/std/autotune.cl`)**:
   - Replace 4-element dummy mock `[0.5, 0.2, 0.8, 0.1]` in `autotune_matmul_tiled` with authentic 3D-loop tiled GEMM ($i_0, j_0, k_0$ tile blocks over inner $i, k, j$ compute loops).
   - Accumulate genuine mathematical dot products $C_{i, j} = \sum_k A_{i, k} B_{k, j}$.
   - Pre-allocate output $C$ with exact $M \times N$ dimensions via `cartan_tensor_alloc`.
2. **`[ISSUE-042]` Authentic Bernoulli Dropout Sampling in DARE (`src/std/fusion.cl`)**:
   - Replace fixed modulo 2 drop heuristic (`math_mod_val(i, 2.0) == 0.0`) in `fusion_dare_rescale` with standard POSIX Linear Congruential Generator (LCG) Bernoulli trial sampling parameterized by `drop_p`.
   - Scale retained weights by $\frac{1}{1 - drop\_p}$ and zero dropped weights.
3. **Core Runtime Tensor Allocator & Reductions (`src/cartanc/core_runtime.car`)**:
   - Update `cartan_tensor_alloc(size)` to pre-allocate $size$ elements using `calloc`, initializing `v[0] = size` and `v[1] = size`.
   - Add polymorphic tree/vector support to `cartan_vec_len`, `cartan_vec_get_f32`, and `cartan_vec_set_f32`.
   - Implement `cartan_tensor_sum`, `cartan_tensor_mean`, `cartan_tensor_max`, `cartan_tensor_min`, and `cartan_tensor_sigmoid`.
4. **LLVM Tree Length Fallback (`src/cartanc/llvm_codegen.car`)**:
   - Update `@cartan_c_tree_len_f` to inspect `v[0]` when `%magic != 212167239`, enabling seamless length querying on both trees and vectors.
5. **Autotune & Tensor Verification Test (`test/compiler_suite/test_autotune.car`)**:
   - Update `test_autotune.car` to perform genuine $4 \times 4$ GEMM multiplication ($A=2.0$, $B=3.0$, tile block 2.0) and verify exact theoretical result $C_{i, j} = 24.0$.
   - Fix `test_tensor_opt.car` and verify passing compilation.

## Verification Steps
1. Re-bootstrap compiler through 3 stages (`stage1` -> `stage2` -> `stage3`) and verify bit-for-bit parity via `fc.exe`.
2. Promote Stage 3 compiler to `cartanc.exe`.
3. Compile and execute `test/compiler_suite/test_autotune.car` with exit code 0.
4. Compile and execute `test/compiler_suite/test_tensor_opt.car` with exit code 0.
5. Execute full 47-target regression test suite (`test/compiler_suite/run_tests.car`).
6. Update `ISSUES.md`, `CHANGELOG.md`, and retrospective.
