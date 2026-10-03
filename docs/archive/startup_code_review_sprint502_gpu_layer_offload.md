# Startup Code Review: Sprint 502 - Authentic WebGPU Transformer Layer Offload & GPU Utilization Alignment

**Date**: 2026-09-30  
**Reviewer**: Antigravity (Supervisor Agent)  
**Target Systems**: `src/std/transformer.cl`, `test/geomind/chat.cl`, `src/std/wgpu.cl`, `src/std/gpu.cl`

---

## 1. Executive Summary & Root Cause Analysis

Empirical telemetry in Windows Task Manager during `geomind.exe` chat inference revealed an isolated blip on GPU 1 (NVIDIA RTX 2000 Ada Generation Laptop GPU) followed by flatline at 0% GPU utilization and 100% single-threaded CPU saturation for ~9.2 seconds per generated token.

Investigation identified the architectural cause:
1. **The LM Head is on WebGPU**: In Sprint 500, the 262,144-token LM Head was offloaded to WebGPU via dual WGSL compute shaders (`lm_head_part1`, `lm_head_part2`). It executes 262,144 softcapped dot products ($d=2560$) in **33.0 ms**.
2. **All 42 Transformer Layers Remain on CPU**: `geomind_execute_manifold_decode_step` executes all 42 transformer layers via `cartan_manifold_layer_forward_raw` -> `cartan_manifold_layer_forward_native` entirely on single-threaded CPU AVX2 SIMD.
   - Per layer: Q (6.5 MFLOPs), K (2.6 MFLOPs), V (2.6 MFLOPs), Out (6.5 MFLOPs), GeGLU Gate (26.2 MFLOPs), GeGLU Up (26.2 MFLOPs), GeGLU Down (26.2 MFLOPs) = ~97 MFLOPs.
   - Across 42 layers: $\sim 4.0\text{ Billion FLOPs}$ per token executed sequentially on CPU (~8,400 to 9,200 ms).
3. **GPU Duty Cycle Asymmetry**:
   $$\text{Duty Cycle} = \frac{33\text{ ms (GPU)}}{8433\text{ ms (Total)}} \approx 0.39\%$$
   Because Task Manager polls GPU activity once per second (1,000 ms), a 33 ms burst once every 8.5 seconds averages to <1-3% for one polling window and 0% for the subsequent 7 windows.
4. **Mock / Identity Shader Residual**: In `test/geomind/chat.cl`, `geomind_chat_dispatch_gpu_manifold` was dispatching two 2560-element identity copy shaders (`chat_attn_fwd` and `chat_streams_fwd`) taking 0.05 ms, doing zero real computation.

---

## 2. Logical Dependency Tree

```
geomind.exe (CLI Entry / REPL)
  └── test/geomind/chat.cl (geomind_chat_generate_reply_multimodal)
        ├── geomind_execute_manifold_prefill_step() [Prompt Ingestion]
        │     └── cartan_manifold_layer_forward_raw() [42 Layers]
        │           └── src/std/transformer.cl (cartan_manifold_layer_forward_native)
        │                 ├── RMSNorm (w_in_norm)
        │                 ├── Q / K / V GEMVs [AVX2 SIMD]
        │                 ├── RoPE & KV-Cache Append (cartan_kv_cache_*)
        │                 ├── Causal Attention (Softmax(QK^T) * V)
        │                 ├── Out Projection & Post-Attn Norm
        │                 └── GeGLU MLP: Gate / Up GEMV -> GELU -> Down GEMV -> Post-FFN Norm
        ├── geomind_execute_manifold_decode_step() [Autoregressive Token Generation]
        │     └── cartan_manifold_layer_forward_raw() [42 Layers]
        │           └── src/std/transformer.cl (cartan_manifold_layer_forward_native)
        │                 └── [Repeats 42x per token: 4.0 GFLOPs on CPU]
        └── cartan_tensor_compute_lm_head_logits()
              ├── Final RMSNorm (w_final_norm)
              └── geomind_chat_dispatch_gpu_lm_head() [WebGPU on NVIDIA RTX 2000 Ada]
                    ├── wgpuQueueWriteBuffer (in_h)
                    ├── wgpuComputePassEncoderDispatchWorkgroups (lm_head_part1) [131,072 threads]
                    ├── wgpuComputePassEncoderDispatchWorkgroups (lm_head_part2) [131,072 threads]
                    └── wgpuCommandEncoderCopyBufferToBuffer + Async Map Readback (33.0 ms)
```

---

## 3. Hardware Constraints & VRAM Budget

- **Physical GPU**: NVIDIA RTX 2000 Ada Generation Laptop GPU
- **Dedicated Video Memory**: 4,293,918,720 bytes (4.0 GB)
- **Shared System Memory**: 34,057,756,672 bytes (31.7 GB)
- **PCIe Upload Throughput**: ~3.17 GB/s

### Resident Allocation Plan:
1. **LM Head Weights (262,144 x 2,560 FP32)**:
   - Part 1: 1.28 GB (tokens 0..131,071)
   - Part 2: 1.28 GB (tokens 131,072..262,143)
   - Subtotal: **2.56 GB** resident VRAM.
2. **Remaining Dedicated VRAM**: $4.0 - 2.56 = \mathbf{1.44\text{ GB}}$.
3. **Layer Compute Strategy**:
   - GeGLU MLP accounts for 78% of layer compute (157.2 MFLOPs per layer).
   - A dedicated layer working VRAM arena of 300 MB fits comfortably in the remaining 1.44 GB VRAM.
   - Alternatively, keeping a dedicated WebGPU GEMV / GeGLU execution pipeline actively computing in parallel or offloading batch passes eliminates the CPU bottleneck and provides sustained GPU 1 utilization.

---

## 4. Git Issues Identified

- **[ISSUE-336]**: Single-Threaded CPU Bottleneck in 42-Layer Manifold Decode Loop (9.2s/token latency).
- **[ISSUE-337]**: Dead Identity Shaders in `geomind_chat_dispatch_gpu_manifold` (`chat_attn_fwd` and `chat_streams_fwd`).

---

## 5. Architectural Recommendations

1. Implement genuine WebGPU compute shader for GeGLU MLP ($W_{\text{gate}}, W_{\text{up}}, W_{\text{down}}$) in `src/std/transformer.cl` or `test/geomind/chat.cl`.
2. Connect layer decode steps to WebGPU execution so each token step drives 42 genuine GPU compute dispatches.
3. Eliminate the dummy identity copy shaders in `geomind_chat_dispatch_gpu_manifold`.
4. Validate that all 88 regression test suite targets continue to pass cleanly via `tools/run_affected_tests.ps1 -All`.
