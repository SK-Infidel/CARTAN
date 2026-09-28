# Startup Code Review: Sprint 472 (Native Compiler SIMD Tensor Math & 3-Stage Bootstrap Parity)

## 1. Executive Summary & Strategic Focus
- **Sprint Goal**: Upgrade CARTAN core runtime (`src/cartanc/core_runtime.car`) with transpose-tiled contiguous cacheline GEMM, 4-way unrolled SIMD accumulators, exact-size flat tensor allocations for elementwise operations, and multi-accumulator reductions; author Target 82 regression & benchmark suite; and execute a rigorous 3-stage self-hosting bootstrap proving bit-for-bit LLVM IR parity between Stage 2 and Stage 3 before promoting the new compiler to production root `cartanc.exe`.
- **Target Component**: [`src/cartanc/core_runtime.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/core_runtime.car), [`src/cartanc/llvm_codegen.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car), [`src/cartanc/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/main.car), [`test/compiler_suite/`](file:///C:/Users/rich-/source/repos/CARTAN/test/compiler_suite/).

---

## 2. Code Review Findings & Technical Debt Analysis

### A. Severe Cacheline Thrashing in Matrix Multiplication (`cartan_tensor_matmul`, `cartan_tensor_matmul_gemm`)
- **Location**: `src/cartanc/core_runtime.car:1102-1184`
- **Issue**:
  - In `cartan_tensor_matmul_gemm`, the inner loop iterates over $k$ accessing `B[k * N + j]`. This strides through memory by $N \times 8$ bytes for every single MAC (multiply-accumulate) operation. When $N \ge 64$, every iteration evicts cachelines and triggers RAM memory-controller pipeline stalls.
  - In `cartan_tensor_matmul` for 2D trees, the code invokes `cartan_tree_get_f32(B, k)` inside the innermost loop, incurring $M \times N \times K$ dynamic function calls and tree node lookups.
- **Solution**:
  - Pre-transpose $B$ ($K \times N \to N \times K$) into a contiguous row-major buffer before the GEMM calculation.
  - Both row $i$ of $A$ and row $j$ of $B^T$ stream through cachelines contiguously: $C_{i, j} = \text{dot}(A_{i, :}, B^T_{j, :})$.
  - Unroll the inner dot product 4-wide (`sum0..sum3`) to enable hardware FMA vectorization and superscalar execution, followed by a scalar cleanup loop for non-multiples of 4.

### B. Dynamic Allocation Overhead in Elementwise Tensor Math (`cartan_tensor_add`, `sub`, `mul`, `div`)
- **Location**: `src/cartanc/core_runtime.car:477-548`
- **Issue**:
  - `cartan_tensor_add`, `cartan_tensor_sub`, `cartan_tensor_mul`, and `cartan_tensor_div` initialize results with `cartan_vec_create()` and repeatedly call `cartan_vec_push_f32(res, ...)`, triggering repeated capacity checks, boundary validation, and potential reallocations in hot loops.
- **Solution**:
  - Pre-allocate exact flat buffers via `cartan_tensor_alloc(len)`.
  - Stream calculations using 4-way unrolled vector loops directly accessing flat array offsets (`2.0 + i`), bypassing function call overhead.

### C. Serial Accumulator Bottlenecks in Reductions and 1D Dot Products
- **Location**: `src/cartanc/core_runtime.car:558-572` and `core_runtime.car:1185-1198`
- **Issue**:
  - `cartan_tensor_sum` and 1D vector dot product iterate a single accumulator variable (`s = s + arr[i]`), serializing execution to CPU floating-point addition latency (typically 4 cycles per add).
- **Solution**:
  - Implement 4 independent accumulators (`s0`, `s1`, `s2`, `s3`), allowing the CPU's out-of-order execution engine to issue 4 simultaneous additions per cycle, achieving up to 4x throughput.

### D. Self-Hosting Bootstrap Parity Gap
- **Issue**:
  - The self-hosted compiler `src/cartanc/main.car` has evolved with dozens of standard library additions, but bit-for-bit LLVM IR equivalence between subsequent compilation generations ($\text{Stage 2} \equiv \text{Stage 3}$) has not been empirically verified since Sprint 304.
- **Solution**:
  - Execute a 3-stage bootstrap:
    1. Root `cartanc.exe` builds Stage 1 (`build/cartanc_stage1.exe`).
    2. Stage 1 builds Stage 2 (`build/cartanc_stage2.exe`).
    3. Stage 2 builds Stage 3 (`build/cartanc_stage3.exe`).
  - Prove bit-for-bit hash or diff identity between `build/cartanc_stage2.ll` and `build/cartanc_stage3.ll`.
  - Promote `cartanc_stage2.exe` to root `cartanc.exe`.

---

## 3. Logical Dependency Tree

```
CARTAN Language Core Architecture
│
├── Compiler Front-End (src/cartanc/)
│   ├── lexer.car ──────► Token Stream
│   ├── parser.car ─────► Abstract Syntax Tree (AST) [ast.ch, types.ch]
│   ├── type_checker.car► Symbol Table, Type Inference, Borrow Checking
│   └── optimizer.car ──► Constant Folding, Identity Elimination, Fused Ops
│
├── Compiler Back-End (src/cartanc/)
│   ├── llvm_codegen.car ──► Pure Textual LLVM IR (.ll) Emission
│   │   ├── Intrinsics & C-ABI Declarations
│   │   └── Direct Vector / Tensor Math Function Dispatch
│   └── main.car ──────────► CLI Driver (build, run, repl, test)
│
├── Built-in Core Runtime (src/cartanc/core_runtime.car) [INJECTED AT COMPILE-TIME]
│   ├── Vector & Tree Memory: cartan_vec_create, cartan_tensor_alloc, cartan_tree_create
│   ├── [OPTIMIZED IN SPRINT 472]
│   │   ├── Elementwise Ops: cartan_tensor_add, sub, mul, div (4-way unrolled, exact alloc)
│   │   ├── Reductions: cartan_tensor_sum, mean (4-way parallel accumulators)
│   │   ├── 1D Dot Product: cartan_tensor_matmul (unrolled 4-way SIMD)
│   │   └── 2D GEMM: cartan_tensor_matmul_gemm, cartan_tensor_matmul (transpose-tiled, contiguous)
│   └── Memory Management: calloc, malloc, free, zero-copy buffer slicing
│
├── Standard Library (src/std/)
│   ├── Math, Geometry & Calculus: math.cl, geom.cl, calculus.cl
│   ├── Neuro-Symbolic Cognitive Stack (Domains 0..18)
│   │   ├── cargraph.cl, nses_pipeline.cl, veto_gate.cl
│   │   ├── domain_lexicon.cl, burroughs.cl, dynamic_gamma.cl
│   │   └── cargraph_consolidate.cl, sqlite_vec.cl, prompt_scaffold.cl
│   └── Neural & Associative Substrates: resonator.cl, transformer.cl, hub.cl
│
└── Test & Regression Verification (test/)
    ├── Compiler Regression Suite: test/compiler_suite/ (Targets 1..81)
    ├── [NEW IN SPRINT 472] Target 82: test_compiler_simd_tensor_math.car
    └── Test Runner: test/compiler_suite/run_tests.car (Validates all 82 targets)
```

---

## 4. Git Issues & Defect Tracking
- **Tracked Issue**: [`[ISSUE-263]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md#L3583) (*Core Runtime SIMD Vector Math, Cacheline-Tiled Matrix Multiplication & 3-Stage Bootstrap Parity*).

---

## 5. Pre-Sprint Scrum Discussion & Read-Ahead Alignment
1. **Memory Safety of Pre-Transposing $B$**:
   - Transposing matrix $B$ ($K \times N$) requires allocating a temporary buffer of size $N \times K$.
   - In `cartan_tensor_matmul_gemm`, we allocate $B^T = \text{cartan\_tensor\_alloc}(N \times K)$, fill it with contiguous columns, execute the contiguous inner dot products, and free $B^T$ via `free(B_T)` before returning $C$.
   - For 2D trees, each row of the transposed tree is a `cartan_vec` of length $K$. Once GEMM completes, the temporary transposed tree is cleanly freed, preserving zero-leak invariant.
2. **Numerical Exactness & Floating-Point Commutativity**:
   - Unrolling accumulators can alter IEEE 754 floating point addition order by an infinitesimal epsilon ($\sim 10^{-7}$).
   - Target 82 will assert exact analytical values and tolerance checks ($|C_{\text{opt}} - C_{\text{baseline}}| < 10^{-5}$) across multiple matrix shapes.
3. **Bit-for-Bit Self-Hosting Parity Criteria**:
   - Stage 1 compiles Stage 2; Stage 2 compiles Stage 3.
   - Stage 2 executable and Stage 3 executable are produced from identical LLVM IR; comparing `build/cartanc_stage2.ll` and `build/cartanc_stage3.ll` must yield 0 diff lines (bit-for-bit parity).
