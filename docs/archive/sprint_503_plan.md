# Sprint 503 Plan: Ultra-Low-Latency Manifold Generation & PCIe Bottleneck Elimination

## 1. Context & Motivation
Rick tested `geomind.exe` in interactive mode and observed that while it mounts the physical NVIDIA RTX 2000 Ada GPU, "it takes forever between prompt and response, and response generation is one... word... at... a... time....".
Empirical profiling (`scratch/bench_timing.car`) revealed:
1. Autoregressive decode transfers 314.57 MB of weights over PCIe 42 times per token = **13.21 GB/token**, taking **2,797 ms (~2.8 seconds) per token**.
2. Sequence prefill across 350 prompt tokens creates and destroys 14,700 WebGPU staging buffers, causing 20-30 seconds of prefill latency.
3. In-RAM AVX2 SIMD GEMV via `cartan_simd_dot_f32` takes **<1 ms** per layer on host CPU without any PCIe traffic.

## 2. Sprint Goal
Eliminate the 13.2 GB/token PCIe weight upload bottleneck and dynamic buffer allocation thrashing to deliver instantaneous interactive chat generation (>10-15 tokens/sec) and sub-second prompt-to-response latency in `geomind.exe`.

## 3. User Stories
- **Story 1 (Persistent Staging Buffers)**: In `src/std/wgpu.cl`, introduce persistent pinned staging readback buffers to eliminate dynamic buffer creation and destruction in `cartan_wgpu_read_buffer`.
- **Story 2 (High-Speed Single-Token Decode Path)**: In `src/std/transformer.cl`, route single-token decode ($T=1$) to zero-copy in-RAM AVX2 SIMD FFN (`cartan_simd_dot_f32`), preserving GPU GeGLU for sequence prefill where weights are reused across tokens.
- **Story 3 (Direct Logits Sampling Pipeline)**: In `test/geomind/chat.cl`, optimize LM head logits readback and sampling to eliminate the 262,144 scalar vector set loop.
- **Story 4 (Empirical Verification & Full Regression)**: Validate interactive chat in `bin/geomind.exe` measuring tokens/sec and ensure zero regressions across all 88 test suite targets.
