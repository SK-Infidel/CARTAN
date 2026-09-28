# Sprint 472 Implementation Plan: Core Runtime SIMD Vector Math, Cacheline-Tiled Matrix Multiplication & 3-Stage Bootstrap Parity

## 1. Executive Summary & Objective
Sprint 472 focuses on fundamental execution speed, cacheline optimization, and self-hosting compiler integrity. We optimize the built-in core runtime tensor and matrix math routines in [`src/cartanc/core_runtime.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/core_runtime.car), author Target 82 regression & benchmark suite, and execute a 3-stage compiler bootstrap proving bit-for-bit self-compiling parity between Stage 2 and Stage 3 before promoting the newly optimized compiler to production root `cartanc.exe`.

---

## 2. Mathematical & Architectural Design

### A. Transpose-Tiled Contiguous GEMM (`cartan_tensor_matmul_gemm`, `cartan_tensor_matmul`)
- In standard naive matrix multiplication $C = A \cdot B$:
  $$C_{i, j} = \sum_{k=0}^{K-1} A_{i, k} \cdot B_{k, j}$$
  $B_{k, j}$ jumps $N \times 8$ bytes every step, causing severe cacheline thrashing.
- With pre-transposition $B^T_{j, k} = B_{k, j}$:
  $$C_{i, j} = \sum_{k=0}^{K-1} A_{i, k} \cdot B^T_{j, k}$$
  Both $A_{i, :}$ and $B^T_{j, :}$ are read sequentially in contiguous memory blocks.
- **4-Way Register Unrolling**:
  ```cartan
  var sum0 = 0.0; var sum1 = 0.0; var sum2 = 0.0; var sum3 = 0.0;
  var k = 0.0;
  let k_limit = K - 3.0;
  while (k < k_limit) {
      sum0 = sum0 + a_row[k] * b_row[k];
      sum1 = sum1 + a_row[k + 1.0] * b_row[k + 1.0];
      sum2 = sum2 + a_row[k + 2.0] * b_row[k + 2.0];
      sum3 = sum3 + a_row[k + 3.0] * b_row[k + 3.0];
      k = k + 4.0;
  }
  var sum = sum0 + sum1 + sum2 + sum3;
  while (k < K) {
      sum = sum + a_row[k] * b_row[k];
      k = k + 1.0;
  }
  ```
- Temporary buffer $B^T$ is allocated once and freed immediately after calculation.

### B. Elementwise Tensor Math & Exact Allocation (`cartan_tensor_add`, `sub`, `mul`, `div`)
- Replace dynamic vector expansion (`cartan_vec_create()` + `cartan_vec_push_f32`) with single zero-reallocation buffer `res = cartan_tensor_alloc(len)`.
- Stream arithmetic operations using 4-way unrolled loops directly over flat array elements (`res[2.0 + i] = va + vb`).

### C. Multi-Accumulator Vector Reductions (`cartan_tensor_sum`, `cartan_tensor_mean`)
- Accumulate across 4 parallel registers (`s0, s1, s2, s3`), breaking the single-cycle loop carry dependency chain and unlocking full CPU instruction-level parallelism (ILP).

### D. Target 82 Regression & Performance Benchmark Suite
- **Location**: `test/compiler_suite/test_compiler_simd_tensor_math.car`.
- **Phases**:
  1. Matrix-matrix GEMM correctness against analytical ground truth ($4 \times 4$, $16 \times 16$, $64 \times 64$, non-square $13 \times 29 \times 17$).
  2. Matrix-vector and 1D vector dot product mathematical invariance.
  3. Elementwise tensor operations (`add`, `sub`, `mul`, `div`) with boundary and divide-by-zero safety.
  4. Reductions (`sum`, `mean`, `max`, `min`) accuracy across small and large tensors.
  5. Speedup benchmark: execute 10,000 iterations of unrolled vector dot products and $64 \times 64$ GEMMs, asserting positive throughput acceleration.

### E. 3-Stage Self-Hosting Parity Verification
- **Protocol**:
  1. Root `cartanc.exe` builds `src/cartanc/main.car` $\to$ `build/cartanc_stage1.exe` + `build/cartanc_stage1.ll`.
  2. `build/cartanc_stage1.exe` builds `src/cartanc/main.car` $\to$ `build/cartanc_stage2.exe` + `build/cartanc_stage2.ll`.
  3. `build/cartanc_stage2.exe` builds `src/cartanc/main.car` $\to$ `build/cartanc_stage3.exe` + `build/cartanc_stage3.ll`.
  4. Compare `build/cartanc_stage2.ll` vs `build/cartanc_stage3.ll`: must produce 0 differences.
  5. Replace root `cartanc.exe` with `build/cartanc_stage2.exe`.

---

## 3. Step-by-Step Task Breakdown
1. **Task 1**: Upgrade `src/cartanc/core_runtime.car` with transpose-tiled GEMM, unrolled 1D dot product, exact tensor alloc for elementwise math, and 4-way reductions.
2. **Task 2**: Author Target 82 (`test/compiler_suite/test_compiler_simd_tensor_math.car`), whitelist in `.gitignore`, register in `test/compiler_suite/run_tests.car`, and compile/run individually.
3. **Task 3**: Execute 3-Stage Self-Hosting Bootstrap and verify bit-for-bit LLVM IR parity between Stage 2 and Stage 3.
4. **Task 4**: Promote `cartanc_stage2.exe` to root `cartanc.exe`, recompile `run_tests.exe`, and execute all 82 regression targets cleanly (0 failures).
5. **Task 5**: Documentation, close `[ISSUE-263]`, update `CHANGELOG.md` (`[8.430.0]`), `docs/ROADMAP.md`, save walkthrough, and commit/push.
