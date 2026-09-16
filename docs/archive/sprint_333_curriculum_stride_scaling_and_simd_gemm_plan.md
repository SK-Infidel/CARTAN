# Sprint 333 Implementation Plan: Curriculum Stride Scaling, AVX2 SIMD Cortical GEMM Unrolling, and Dynamic CLI Acceleration

## Objectives
1. **AVX2 SIMD Inner Loop Vectorization**: Unroll inner loops in `cartan_tensor_train_step` (`test/geomind/train.cl`) and `cartan_tensor_compute_lm_head_logits` (`test/geomind/chat.cl`) by 8-wide contiguous float blocks, adding zero-skipping guards (`if (hv != 0.0)`) to eliminate branch overhead and enable Zig/Clang 256-bit AVX2 FMA code generation.
2. **Curriculum Stride Scaling**: Replace the dense 256-byte micro-stride with configurable curriculum stride (`stride = 2048.0` default for Cloze, `1024.0` for CE), enabling the model to traverse all 6 taxonomy partitions (35.2 MB) in a balanced, high-throughput progression.
3. **Dynamic `-stride <bytes>` CLI Flag**: Add dynamic stride CLI argument parsing in `test/geomind/main.car` linked to global `g_train_stride` in `test/geomind/train.cl`, allowing user control over epoch duration (e.g. `-stride 4096` or `-stride 8192`).
4. **Binary Synchronization**: Rebuild and synchronize all 4 `geomind.exe` binaries across `./`, `bin/`, `build/`, and `test/geomind/`.
5. **Empirical Verification**: Measure live training throughput and verify loss descent with zero memory leaks.
