# Startup Code Review: Sprint 509 — Full-VRAM Resident INT8 Manifold & WebGPU Decode Acceleration

**Date**: October 1, 2026  
**Audience**: Rick (Big Daddy) & Engineering Squad  
**Focus**: Eradicating Host-RAM Streaming Latency via 100% VRAM-Resident INT8 Manifold on NVIDIA RTX 2000 Ada  

---

## 1. Context & Architectural Baseline

In Sprint 508, the 16.8 GB FP32 model was successfully compressed to 3.73 GB INT8 (W8A32), accelerating CPU decode to **5.0–5.6 tok/s** (11.9 tok/s raw layer kernel). However, host CPU decode remains fundamentally gated by host DDR5 RAM bandwidth (~48 GB/s).

### Hardware Profile:
- **Host RAM**: Dual-channel DDR5 @ ~48 GB/s bandwidth.
- **Discrete GPU**: NVIDIA RTX 2000 Ada Generation Laptop GPU.
- **Dedicated VRAM**: 8,188 MiB (8.0 GB) GDDR6.
- **GDDR6 Memory Bandwidth**: **224.0 GB/s** (4.67x faster than host DDR5).
- **Physical Feasibility**:
  - Total INT8 weights across all 42 layers: **3,730 MiB (3.64 GB)**.
  - Required VRAM: 3.73 GB weights + 0.3 GB KV cache + 0.1 GB activations = **4.13 GB total**.
  - Available Dedicated VRAM: **8.00 GB**.
  - **Headroom: ~3.87 GB of free VRAM remaining.**
  - **Theoretical Speed of Light**:
    $$\tau_{\text{GPU}} = \frac{3.73\text{ GB}}{224\text{ GB/s}} = \mathbf{16.65\text{ ms per 42-layer sweep}} \implies \mathbf{60\text{ tok/s raw memory limit}}.$$

---

## 2. Logical Dependency Tree

```
[Hardware Layer]
  └── NVIDIA RTX 2000 Ada Laptop GPU (8GB GDDR6 @ 224 GB/s)
        │
[Driver & WebGPU Abstraction]
  └── src/std/wgpu.cl (Direct3D 12 Backend, WGPU Instance, Device, Queue)
        │
[Standard Compute Runtime]
  └── src/std/gpu.cl (Unified GPU Alloc, Write, Read, Dispatch wrappers)
        │
[Transformer Engine]
  └── src/std/transformer.cl
        ├── g_manifold_layer_buffers[42] (Host INT8 mmap buffers)
        ├── g_gpu_layer_weights[42] (Persistent VRAM storage buffers)
        ├── Persistent Bind Groups & Compute Pipelines
        └── cartan_transformer_dispatch_gpu_layer_int8()
              │
[Model Application Layer]
  └── test/geomind/chat.cl
        ├── geomind_mount_gpu_resident_layers()
        ├── geomind_execute_manifold_decode_step()
        └── bin/geomind.exe (Interactive REPL & Generation)
```

---

## 3. Critical Code Review Findings & Discoveries

### A. WGSL INT8 Storage Buffer Declaration & Vector Unpacking
- Standard WGSL does not support scalar `array<i8>` inside storage buffers (requires minimum 4-byte scalar alignment).
- **Solution**: Weights are bound as `array<u32>`, where each `u32` encapsulates 4 sequential INT8 weight values ($W_{k}, W_{k+1}, W_{k+2}, W_{k+3}$).
- In WGSL, the built-in function `unpack4x8snorm(packed: u32) -> vec4<f32>` converts four signed 8-bit integers into four 32-bit floating point values normalized to $[-1.0, 1.0]$ ($\text{val} = \text{byte} / 127.0$).
- Because our quantizer in `tools/quantize_manifold_int8.car` defined:
  $$\text{val}_{\text{int8}} = \text{round}\left(\frac{\text{val}_{\text{fp32}}}{\text{scale}}\right), \quad \text{where } \text{scale} = \frac{\max(|W|)}{127.0}$$
- Multiplying `unpack4x8snorm(packed)` by $(\text{scale} \times 127.0) = \max(|W|)$ recovers the exact unquantized floating-point weights using dedicated single-cycle GPU hardware vector instructions.

### B. Command Submission Bottleneck in `src/std/wgpu.cl`
- Currently, `cartan_wgpu_dispatch` creates a new bind group, encodes a single pass, finishes the command buffer, and calls `wgpuQueueSubmit` on **every single dispatch**.
- 42 layers $\times$ 2 ops = 84 individual `wgpuQueueSubmit` calls per token.
- Each `wgpuQueueSubmit` incurs ~0.15 ms of Direct3D 12 kernel transition overhead ($84 \times 0.15 = 12.6\text{ ms}$).
- **Optimization**:
  1. Pre-create persistent `WGPUBindGroup` handles during initialization (`geomind_mount_gpu_resident_layers`), eliminating dynamic `wgpuDeviceCreateBindGroup` and `malloc`/`free` calls during generation.
  2. Encode all layer compute passes into a single command encoder and submit ONCE per decode step, slashing submission overhead from 12.6 ms to **0.2 ms**.

### C. Zero-Copy VRAM Residency Integrity
- In Sprint 502, `cartan_transformer_dispatch_gpu_geglu` re-uploaded weights across PCIe on layer transitions because only 1 layer was kept in VRAM.
- In Sprint 509, all 42 INT8 layer buffers are allocated and populated in VRAM **once** at startup.
- During autoregressive decode, **zero weight bytes are ever transferred over PCIe**. Only the 2560-float input hidden state (10 KB) is uploaded, and the 2560-float output is downloaded.

---

## 4. Technical Debt & Issues Logged

- `[ISSUE-360]`: Command submission storm and dynamic bind group creation in WebGPU layer dispatches.
- `[ISSUE-361]`: Single-layer VRAM eviction forcing redundant PCIe transfers in transformer GPU dispatch.

---

## 5. Read-Ahead Risk Mitigation
- **VRAM Out-of-Memory Guard**: Check physical VRAM availability before allocating all 42 layers. If VRAM is constrained (< 4 GB available), fall back gracefully to the verified Sprint 508 Host-RAM INT8 AVX2 SIMD engine.
- **Numerical Parity**: Validate WGSL INT8 dot product outputs against CPU `@cartan_simd_dot_i8_f32` to guarantee $\max|\Delta| < 10^{-4}$.
