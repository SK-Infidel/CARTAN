# Startup Code Review: Sprint 503 — Ultra-Low-Latency Manifold Generation & PCIe Bottleneck Elimination

## 1. Executive Summary & Problem Diagnosis
- **Reported by Rick**: Prompt-to-response latency is excessively high ("takes forever between prompt and response"), and token generation is sluggish ("one... word... at... a... time....").
- **Empirical Diagnostics (`scratch/bench_timing.car`)**:
  - 1 Layer GPU with 300 MB PCIe weight upload: **66.61 ms**
  - 42 Layers with PCIe uploads: **2,797.52 ms (~2.8 seconds) per token**!
  - 1 Layer GPU Resident in VRAM: **5.32 ms**
  - 42 Layers GPU Resident: **223.44 ms per token** (4.5 tokens/sec).
  - 1 Layer CPU SIMD AVX2 in RAM: **<1 ms**.

## 2. Root Cause Breakdown
1. **The 13.2 GB/Token PCIe Transfer Throttling (`cartan_transformer_dispatch_gpu_geglu`)**:
   - `g_transformer_gpu_cached_w_gate` only caches weights for the most recently called layer.
   - During autoregressive decode, the token step cycles through all 42 layers sequentially (0 to 41).
   - Because `w_gate` changes every layer, 314.57 MB ($W_{\text{gate}}, W_{\text{up}}, W_{\text{down}}$) is uploaded via `wgpuQueueWriteBuffer` 42 times per token: **13.21 GB transferred over PCIe every single token**!
   - On PCIe 4.0 x8 (~8-10 GB/s), this introduces an unavoidable ~1.5 - 2.8 second delay per token.
2. **Dynamic Staging Buffer Thrashing in WebGPU Readback (`cartan_wgpu_read_buffer`)**:
   - In `src/std/wgpu.cl`, every call to `cartan_wgpu_read_buffer` creates a new staging buffer via `wgpuDeviceCreateBuffer` and destroys it via `wgpuBufferDestroy`.
   - During sequence prefill (350 tokens across 42 layers), this triggers $42 \times 350 = \mathbf{14,700}$ dynamic GPU buffer allocations and synchronous device map polls, causing a 20-30 second delay before the first token appears.
3. **262k Element Vector Elementwise Unpack (`geomind_chat_dispatch_gpu_lm_head`)**:
   - Logits read back from GPU are unpacked element-by-element via 262,144 scalar `cartan_vec_set_f32` calls in interpreted CARTAN, adding 20-40 ms of unnecessary host CPU latency per token.

## 3. Logical Dependency Tree
```
test/geomind/main.car (Interactive REPL Entrypoint)
  └── test/geomind/chat.cl (Prefill, Decode Step, LM Head Dispatch)
        ├── src/std/transformer.cl (Layer Forward, GeGLU Dispatch, Cache Management)
        │     ├── src/std/wgpu.cl (WebGPU Instance, Buffers, Pipelines, Readback)
        │     ├── src/std/gpu.cl (Unified GPU abstraction)
        │     ├── src/std/math.cl (Fast GELU Tanh, Vector Math)
        │     └── src/cartanc/llvm_codegen.car (@cartan_simd_dot_f32 AVX2 FMA)
        ├── src/std/hub.cl (BPE Tokenizer, Safetensors Loader)
        ├── src/std/sqlite_vec.cl (Cognitive Memory)
        └── src/std/nses.cl (Symbolic Pre-Priming & Veto Guard)
```

## 4. Architectural Solution Strategy
1. **Persistent Zero-Allocation Staging Buffers in `src/std/wgpu.cl`**:
   - Allocate fixed reusable staging buffers for reading output vectors (`staging_out_10k`) and LM head logits (`staging_logits_512k`).
   - Eliminate all dynamic `wgpuDeviceCreateBuffer` and `wgpuBufferDestroy` in the critical path.
2. **Decode Execution Path: Ultra-Fast AVX2 SIMD In-RAM FFN for Single-Token Decode**:
   - For single-token autoregressive decoding ($T=1$), all 15.6 GB of weights are already memory-mapped in DDR5 host RAM.
   - Executing the $T=1$ GeGLU GEMV on CPU using native AVX2 8-way FMA (`cartan_simd_dot_f32`) bypasses the 13.2 GB PCIe bus entirely, executing 42 layers in **under 100 ms**!
   - Sequence prefill ($T > 1$) can utilize GPU or batching without per-token PCIe churn.
3. **Zero-Copy LM Head Logits Buffer**:
   - Use raw pinned float buffers for logits passing directly from GPU readback into top-p/top-k sampling, eliminating the 262,144 `cartan_vec_set_f32` loop.
4. **VRAM Resident Multi-Layer Caching**:
   - In `cartan_transformer_mount_gpu_geglu`, allocate dedicated resident slots in the remaining 4.8 GB free VRAM for high-frequency layers.

## 5. Discovered Issues & Technical Debt
- **[ISSUE-339]**: Autoregressive decode PCIe bus thrashing: uploading 13.2 GB of weights per token in `cartan_transformer_dispatch_gpu_geglu`.
- **[ISSUE-340]**: WebGPU readback staging buffer thrashing: creating and destroying staging buffers on every `gpu_read` call.
- **[ISSUE-341]**: LM Head 262,144-element scalar vector unpack latency in `geomind_chat_dispatch_gpu_lm_head`.
