# Sprint 508 Plan: Host-RAM INT8 AVX2 SIMD Engine & Manifold Quantization

## Objectives
1. **Gate 1**: Implement `@cartan_simd_dot_i8_f32` in compiler core (`src/cartanc/llvm_codegen.car`) with 4-way ILP unrolling and verify via 3-stage bootstrap fixpoint.
2. **Gate 2**: Build offline/fast-startup quantizer utility (`tools/quantize_manifold_int8.car`) to convert 42 FP32 checkpoints (16.1 GB) into compact INT8 checkpoints (3.95 GB) with per-row FP32 scaling.
3. **Gate 3**: Implement `cartan_manifold_layer_forward_int8` and thread pool dispatch ops in `src/std/transformer.cl`.
4. **Gate 4**: Benchmark single layer decode (~2.0 ms) and full 42-layer decode (~85 ms) on `bench_single_decode_step.exe`; verify live interactive chat in `geomind.exe` reaching 7–9+ tok/s with zero regressions on 88 compiler test suite targets.

## Squad Assignments
- **Compiler Core Squad (`cartan_compiler_engineer`)**: Codegen design and LLVM IR emission for `@cartan_simd_dot_i8_f32`, bootstrap convergence, target 82 validation.
- **Runtime & Hardware Squad (`cartan_runtime_engineer`)**: `cartan_manifold_layer_forward_int8`, thread pool worker ops for INT8 GEMV, memory-mapped streaming.
- **Architecture & Geometry Squad (`cartan_architect`)**: Quantization dynamic range and numerical fidelity analysis, ensuring zero mock and bit-accurate attention states.
- **QA & Benchmark Squad (`cartan_qa_tester`)**: Empirical decode latency benchmarks, prompt verification, full 88-target regression testing.
