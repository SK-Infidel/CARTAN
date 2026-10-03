# Architectural Performance Research & High-Throughput Implementation Strategy

**Target**: Sovereign GeoMind Manifold (`geomind.exe`) & CARTAN Runtime  
**Audience**: Rick (Big Daddy) & Agile Engineering Squad  
**Date**: October 1, 2026  

---

## 1. Executive Summary & Root Cause Analysis

In Sprint 506, prompt prefill latency was successfully reduced from **159 seconds** (corrupted dialogue accumulation) / **74.1 seconds** (Sprint 504 baseline) down to **1.419 seconds** (a **52.2x speedup**), and LM Head projection latency dropped to **38 ms** (a **36.9x speedup**).

However, autoregressive token generation remains at **2.22 tokens/second** (~407 ms per token: 367 ms 42-layer manifold sweep + 39 ms LM head + 1 ms sampling).

### The Physical Memory Bandwidth Wall (The "Word-by-Word" Cause)
- In autoregressive single-token decode ($N = 1$), the compute intensity is low ($2 \times \text{weights} \approx 200\text{ MFLOPs/layer}$), but **every single parameter must be streamed from memory once per token**.
- In FP32 (4 bytes per parameter), 42 layers of Gemma-2/GeoMind 4B require reading **16.8 GB of weights per generated token**.
- Dual-channel DDR5 host RAM has a measured ceiling of **~48 GB/s**.
- Theoretical physical minimum time to stream 16.8 GB across DDR5:
  $$\tau_{\text{min}} = \frac{16.8\text{ GB}}{48\text{ GB/s}} = \mathbf{350\text{ ms}}.$$
- Our current multi-threaded AVX2 engine completes the 42-layer sweep in **367 ms**—operating at **95.4% of the theoretical physical bandwidth of the motherboard**.
- **Conclusion**: The CPU is not compute-bound; it has hit the physical speed of light of host DDR5 RAM. To reach fluid real-time streaming (15–30+ tokens/sec), we must break through the memory bandwidth wall.

---

## 2. Discoveries from Documentation & Research

A systematic audit of `test/geomind/Documentation/`, `docs/Research/`, and `docs/Vision/` identified three high-impact architectural levers:

### A. Full-VRAM Resident INT8 Manifold (`docs/Vision/potential_features.md:23`)
- **Documented Concept**: `quantize(INT8)` directive and layer fusion.
- **Hardware Profile**: The system possesses a dedicated **NVIDIA RTX 2000 Ada Generation Laptop GPU** with **8,188 MiB (8.0 GB) GDDR6 VRAM** operating at **224.0 GB/s** (nearly **5x faster** than DDR5 RAM).
- **Footprint**:
  - In FP32: 42 layers = 15.6 GB (exceeds 8 GB VRAM).
  - In INT8 (symmetric per-channel quantization): 42 layers = **3.905 GB**.
- **Bandwidth Equation**:
  $$\tau_{\text{GPU}} = \frac{3.905\text{ GB}}{224\text{ GB/s}} = \mathbf{17.4\text{ ms per token sweep}}.$$
- Combined with our 38 ms AVX2 CPU LM Head, per-token latency drops from 407 ms to **55 ms**, unlocking **18 to 22 tokens/second**!

### B. Inherent Biological Fast-Paths (`Unimplemented_ZeroDay_Ideas.txt`, `BIOLOGICAL_ARCHITECTURE_AND_INFERENCE_LEARNING.md`)
- **Continuous Hopfield Associative Memory**:
  - `ising_state_machine.cl` and `resonator.cl` feature an associative energy resonator with exponential capacity ($C \approx 2^{d/2}$).
  - Can be queried in $\mathcal{O}(1)$ step to formulate prompt conditioning vectors, reducing the effective prompt depth needed for standard context retrieval.
- **8-Stream Sasaki Brainstem Routing**:
  - Submanifold phase-space routing ($(x, \dot{x})$) allows activating only relevant specialist pathways instead of unconditioned dense transformations on every token.

### C. Fused RMSNorm-GEMV Kernels (`docs/Vision/potential_features.md:24`)
- Currently, Pre-Attention RMSNorm and Pre-FFN RMSNorm execute two passes over hidden state vectors (one for $\sum x_i^2$, one for scaling into buffer), followed by GEMV reading the buffer.
- Fusing RMSNorm scale directly into the inner product loop eliminates redundant vector scratch allocations and cache misses.

### D. Fluid Character Streaming & Paced Terminal Output
- Token-level printing emits chunks of 3–6 characters at once after each 400 ms step, creating a "chunky / staccato" word-by-word visual cadence.
- Decoupling token emission from terminal rendering via a smooth asynchronous character-ticker thread transforms output into an uninterrupted, fluid stream of text.

---

## 3. High-Throughput Implementation Strategy

We propose executing a structured 3-phase optimization plan:

```
┌─────────────────────────────────────────────────────────────┐
│ Phase 1: Smooth Character Ticker & Prefill Optimization     │
│ - Decouple token generation from character terminal pacing  │
│ - Fuse RMSNorm into GEMV inputs to cut prefill to < 800 ms  │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ Phase 2: Host-RAM INT8 AVX2 SIMD Engine (CPU Leap)         │
│ - Quantize 42 layers to INT8 (16.8 GB -> 3.9 GB in RAM)     │
│ - Stream 3.9 GB over DDR5: drops layer sweep to ~85 ms      │
│ - Total decode rate jumps to 7 - 9 tokens/second on CPU     │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ Phase 3: Full-VRAM Resident INT8 Manifold (WebGPU GDDR6)    │
│ - Pin all 3.9 GB INT8 layer weights resident in 8GB VRAM    │
│ - Dispatch 42 layers over 224 GB/s GDDR6 bus (17.4 ms)      │
│ - Total decode rate reaches 18 - 25+ tokens/second          │
└─────────────────────────────────────────────────────────────┘
```

### Sprint 507 Readiness
1. **Gate 1**: Implement sub-token fluid character-ticker rendering in `geomind_chat_generate_reply_multimodal` for immediate conversational fluidity.
2. **Gate 2**: Build offline INT8 weight packing utility (`tools/quantize_manifold_int8.car`).
3. **Gate 3**: Implement SIMD INT8 dot product (`@cartan_simd_dot_i8_f32` with `VNNI` / `_mm256_maddubs_epi16`) in `llvm_codegen.car`.
4. **Gate 4**: Benchmark live decode acceleration on `geomind.exe`.
