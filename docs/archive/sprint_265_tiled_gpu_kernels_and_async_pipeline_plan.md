# Sprint 265 Implementation Plan: 2D Tiled Shared-Memory GPU Kernels & Async Double Buffering

## 1. Goal & Objectives
- **Goal**: Accelerate GPU training throughput from $\sim 28\text{ samples/sec}$ to $>500\text{ samples/sec}$ without altering mathematical contracts, non-Euclidean Lie manifold geometry, or deterministic parameter updates.
- **Objectives**:
  1. **2D Tiled Shared-Memory GEMM for LM Head Backward SGD (`k_opencl_backward_sgd`)**: Replace scalar global DRAM reduction with cooperative $16 \times 16$ `__local` tiled GEMM ($\nabla W = X^T (P - Y)$), reducing memory bus bandwidth by $>400\times$.
  2. **Tiled Transposed 42-Layer Reverse-Mode Backpropagation (`k_opencl_layer_backward_dz_and_dx` & `k_opencl_layer_backward_update_w`)**: Eliminate 10.2 KB column strides and L1 cache line evictions by staging weights in local shared memory tiles.
  3. **Asynchronous Double-Buffered CPU Ingestion**: Overlap CPU tokenization and fast RoPE embedding of Slice $N+1$ with GPU 42-layer execution of Slice $N$.

## 2. Dependency Graph & Risk Analysis
- **Code Dependency**:
  - `src/cartanc/c_runtime.c` $\to$ `~/.cartan/c_runtime.c` $\to$ `test/geomind/main.car` $\to$ `bin/geomind_native.exe`
- **Invariants to Preserve**:
  - Exact preservation of GeLU curvature factor $\kappa_l$, parallel transport connection rotations, and Riemannian momentum $\mu = 0.90$.
  - Bit-exact gradient calculations and deterministic cross-entropy loss metrics.

## 3. Step-by-Step Task List
- [ ] Task 1: Refactor `k_opencl_forward_gemm` to use $16 \times 16$ `__local` tiled shared memory.
- [ ] Task 2: Refactor `k_opencl_backward_sgd` to $16 \times 16$ tiled shared memory GEMM.
- [ ] Task 3: Refactor `k_opencl_layer_backward_update_w` to $16 \times 16$ tiled shared memory GEMM.
- [ ] Task 4: Refactor `k_opencl_layer_backward_dz_and_dx` to coalesce reverse-pass weight matrix reads.
- [ ] Task 5: Implement OpenMP background thread double-buffering for streaming slice ingestion.
- [ ] Task 6: Synchronize to `~/.cartan/c_runtime.c`, compile `bin/geomind_native.exe` with `cartanc.exe`.
- [ ] Task 7: Empirical verification on GPU and benchmark throughput.
- [ ] Task 8: Update CHANGELOG.md, ISSUES.md, and archive walkthrough.
