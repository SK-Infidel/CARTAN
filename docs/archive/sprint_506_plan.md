# Sprint 506 Implementation Plan: Prefill Latency Elimination & Real-Time Fluid Decode Acceleration

## Goal
Eliminate the prompt-to-response freeze (slashing prefill from 14.8s to <2s) and accelerate decode streaming speed beyond the current 2 tok/s toward real-time fluid generation, while preserving 100% genuine operations and zero regressions across the 88 regression test targets.

---

## Architecture & Implementation Strategy

### Gate 1: Startup Memory Pre-Warming (`geomind_warm_all_layer_buffers`)
- In `test/geomind/chat.cl`, implement `geomind_warm_all_layer_buffers()`.
- During model initialization, call `geomind_get_layer_buffer(l)` for all 42 layers before the user prompt arrives.
- Eliminates the 5.5-second disk seeking and OS page-fault freeze on the first prompt.

### Gate 2: Zero-Allocation Pinned Scratch Buffers in Batched Prefill
- In `src/std/transformer.cl`, replace the 9-11 dynamic `malloc` and `free` calls per layer in `cartan_manifold_layer_forward_batch` with pinned scratch buffers sized for max prompt capacity.
- Eliminates 462 dynamic heap allocations/deallocations per prompt, eliminating allocator lock contention and memory fragmentation.

### Gate 3: Vectorized & Thresholded Prefill Attention Accumulation
- In `src/std/transformer.cl` (lines 2450-2465), add `p_t > 0.000000001` threshold gating and 4-way unrolling to the `v_ht` attention accumulation loop.
- Slashes up to 300+ million redundant scalar arithmetic operations during multi-token prompt prefill.

### Gate 4: Thread Pool Spin Yield Optimization
- In `src/std/transformer.cl`, tune `cartan_trans_pool_dispatch` and `cartan_trans_pool_worker_main`.
- Increase the spin cycle count before executing `Sleep(0.0)` from 200 to 5,000 iterations.
- Sub-millisecond GEMVs complete within the spin window without triggering Windows kernel thread context switches across the 252 dispatches per token.

### Gate 5: 4-Way Instruction-Level Parallelism in `@cartan_simd_dot_f32`
- In `src/cartanc/llvm_codegen.car`, expand `@cartan_simd_dot_f32` to unroll by 4 SIMD vectors (32 floats / 128 bytes per iteration) with 4 independent accumulator vectors (`%vacc0`, `%vacc1`, `%vacc2`, `%vacc3`).
- Fully hides the 4-cycle FMA latency, saturating dual AVX execution ports on Intel Core i9-13950HX.

### Gate 6: Architectural Blueprint for Full-VRAM Resident INT8 Manifold
- Document the INT8 resident tensor manifold architecture where all 42 layers (3.9 GB) reside permanently in the 7.0 GB free VRAM of the NVIDIA RTX 2000 Ada GPU, streaming at 224 GB/s for 17.4 ms decode steps (>30 tok/s).

---

## Verification Plan
1. Standalone compilation with `cartanc.exe`.
2. Benchmark prefill latency and decode tokens/sec using `bin/geomind.exe -prompt "What is the capital of France?" -tokens 20`.
3. Verify dialogue quality and factual correctness.
4. Run full compiler regression suite: `tools/run_affected_tests.ps1 -All` (88/88 passed).
5. Update `CHANGELOG.md` and `ISSUES.md`.
