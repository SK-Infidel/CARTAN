# Startup Code Review: Sprint 505 — Real-Time Multithreaded Decode & Interactive Acceleration

**Review Date**: 2026-10-01  
**Author**: Antigravity  
**Lead Evaluator**: Rick (Big Daddy)  
**Sprint Focus**: Interactive Generation Responsiveness, Multithreaded CPU Execution, Cache-Aligned Attention  

---

## 1. Executive Summary & Rick's Feedback
Rick observed: *"It seems to have MAAAAYBe sped up a tiny bit, but not much."*  
This feedback is completely accurate. While Sprint 504 successfully reduced prompt prefill from 93.1s down to 15.1s (a 6.14x speedup), **autoregressive decoding** remains stuck at **1.3–1.4 tokens/second** (~740 ms per token across 42 layers).  
Generating even a modest 20-token conversational reply takes 15s of prefill + 15s of token generation = 30 seconds total. To an interactive user, this cadence feels sluggish.

---

## 2. Empirical Profiling & Root Causes

### A. The 740 ms/Token Decode Bottleneck
Benchmarked via `scratch/bench_single_decode_step.car`:
```
Single Layer Native Decode Time: 17.63 ms
Full 42 Layers Native Decode Time: 740.42 ms (1.4 tok/s)
```
Across 42 layers, single-token decode performs:
- **Attention GEMV**: Q ($4096 \times 2560$), K ($2048 \times 2560$), V ($2048 \times 2560$), $W_o$ ($2560 \times 4096$).
- **FFN GEMV**: Gate ($10240 \times 2560$), Up ($10240 \times 2560$), Down ($2560 \times 10240$).
- **Total Weights Read Per Layer**: $\approx 440\text{ MB}$ (18.5 GB across 42 layers).
- **Compute Volume**: $\approx 220\text{ MFLOPs}$ per layer (9.2 GFLOPs across 42 layers).

### B. Hardware Asymmetry & Idleness
- **Host CPU**: 13th Gen Intel Core i9-13950HX — **24 Physical Cores / 32 Logical Processors**.
- **Host GPU**: NVIDIA RTX 2000 Ada Generation Laptop GPU — 8,188 MiB VRAM (7,415 MiB currently free).
- **The Bottleneck**: Currently, CARTAN single-token decode runs on **1 single CPU core out of 32**, leaving 31 cores completely idle. A single CPU core's line fill buffers saturate at ~25–30 GB/s on DDR5, forcing the 18.5 GB memory read to take $\ge 616$ ms.

### C. Cache-Hostile Attention Loop
In `cartan_manifold_layer_forward_native` (lines 1400–1416):
```cartan
let out_h = cartan_f32_ptr_add(g_trans_attn_out, qh * head_dim);
var hd = 0.0;
while (hd < head_dim) {
    var weighted = 0.0;
    if (v_cache != 0.0) {
        t = 0.0;
        while (t < max_seq) {
            let p_t = cartan_f32_at(g_trans_scores, t) * inv_sum;
            let v_ht = cartan_f32_ptr_add(v_cache, t * kv_dim + kvh * head_dim);
            weighted = weighted + p_t * cartan_f32_at(v_ht, hd);
            t = t + 1.0;
        }
    }
    cartan_set_f32(out_h, hd, weighted);
    hd = hd + 1.0;
}
```
For every head and dimension ($16 \times 256 = 4,096$ iterations per layer), the inner loop strides across `v_cache` with an 8 KB jump (`t * kv_dim`), triggering $17.2\text{ million}$ non-contiguous memory accesses and cache line evictions per token.

---

## 3. Logical Dependency Tree
```
geomind.exe (Interactive Chat CLI)
└── geomind_execute_manifold_decode_step [test/geomind/chat.cl]
    ├── cartan_manifold_layer_forward_native [src/std/transformer.cl] (42 sequential passes)
    │   ├── Pre-Attention RMSNorm (AVX2 SIMD)
    │   ├── Q, K, V Projections (AVX2 dot products via cartan_simd_dot_f32)
    │   ├── Rotary Position Embeddings (RoPE)
    │   ├── KV Cache Contiguous Update (cartan_c_memcpy)
    │   ├── GQA Causal Attention Dot Products & Softmax
    │   ├── Value Weight Accumulation (currently cache-hostile)
    │   ├── Output Projection W_o (AVX2 4-way unrolled)
    │   ├── Post-Attention RMSNorm + Residual
    │   ├── Pre-FFN RMSNorm
    │   ├── Gate & Up Projections (AVX2 4-way unrolled) + Fast GeGLU
    │   ├── Down Projection (AVX2 4-way unrolled)
    │   ├── Post-FFN RMSNorm + Residual
    │   └── Per-Layer Embedding (PLE) Projections
    └── geomind_chat_dispatch_gpu_lm_head [test/geomind/chat.cl]
        ├── WebGPU WGSL lm_head_fwd dispatch on NVIDIA RTX 2000 Ada GPU
        ├── cartan_wgpu_read_buffer (persistent staging buffer)
        └── geomind_bulk_f32_to_tensor (8-way unrolled)
```

---

## 4. Technical Debt & Git Issues
1. **[ISSUE-345] Single-Core CPU Underutilization in Model Decoding**:
   - Single-token decode runs strictly sequentially on core 0, bottlenecking DDR5 memory bus and compute.
2. **[ISSUE-346] Cache-Hostile Strided Access in GQA Attention Accumulation**:
   - `cartan_manifold_layer_forward_native` loops over sequence `t` inside dimension `hd`, incurring 17M strided cache misses.

---

## 5. Architectural Strategy for Sprint 505
1. **Invert Attention Value Loop in `cartan_manifold_layer_forward_native`**:
   - Zero `out_h` first; loop `t = 0 .. max_seq` outer, with `hd = 0 .. head_dim` contiguous inner accumulation.
2. **Implement Native Multithreaded GEMV Partitioning**:
   - Partition row ranges across available worker threads using native Win32 `CreateThread` / synchronization.
   - Run Gate/Up (20,480 rows) and Q/Down projections in parallel chunks across CPU cores.
3. **Verify Zero Regressions & Authentic Calculations**:
   - Zero mocking; full 88-target regression test suite verification.
