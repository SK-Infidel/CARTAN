# Sprint 336: GPU Saturation, Fused In-VRAM Kernels, and Zero-Bubble Pipelining

## Objective
Increase physical GPU compute utilization from 30–40% to 80–95%+ on the NVIDIA RTX 2000 Ada Generation Laptop GPU during GeoMind neural training by eliminating 107,000+ per-epoch synchronous CPU-GPU stalls, intermediate PCIe roundtrips, and CPU-bound autoregressive FFN cascades.

## Root Cause Analysis (Sprint 335 Baseline)
1. **Per-Token Synchronization Stalls**: Each token calls `gpu_sync()` twice (after GEMV and after SGD), freezing execution 107,724 times per epoch.
2. **Intermediate PCIe Roundtrips**: Each token transfers 10 KB logits to CPU and 10 KB deltas back to GPU (1.1 GB of uncoalesced PCIe transfers).
3. **CPU-Bound Autoregressive & FFN Cascade**: Between tokens, the CPU sequentially computes 2,560 sinusoids, Sasaki phase routing, 8-stream manifold projections, and 16 layers of FFN (40,960 transcendental GELU/tanh evaluations), idling the GPU for 60–70% of wall-clock time.

## Architecture & Pipelining Flow
```
┌────────────────────────────────────────────────────────┐
│  src/std/gpu.cl                                        │
│  - Added cartan_gpu_launch_local() for explicit workgroups│
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│  test/geomind/train.cl (Fused GPU Kernels)             │
│  - geomind_gemv_forward (2560 threads)                 │
│  - geomind_softmax_loss_delta (256 threads, 1 workgroup)│
│  - geomind_sgd_backward (2560 threads)                 │
│  - geomind_autoregressive_step (2560 threads)          │
│  - geomind_rmsnorm (256 threads, 1 workgroup)          │
│  - geomind_ffn_cascade (2560 threads)                  │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│  test/geomind/train.cl (Chunk Pipelining Engine)       │
│  - In-VRAM persistent cur_h across all tokens in chunk │
│  - Back-to-back in-order queue dispatch (zero stalls)  │
│  - Single DMA read of scalar loss array at chunk end   │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│  Synchronized Deployment & Hardware Validation         │
│  - Recompile bin/geomind.exe via cartanc.exe           │
│  - Synchronize all 4 binaries (./, bin/, build/, test/) │
│  - Validate >80% GPU compute utilization via nvidia-smi │
└────────────────────────────────────────────────────────┘
```

## Work Items
1. [ ] Extend `src/std/gpu.cl` with `cartan_gpu_launch_local()` for explicit local workgroup dispatch.
2. [ ] Implement fused `geomind_softmax_loss_delta` OpenCL kernel in `test/geomind/train.cl`.
3. [ ] Implement `geomind_autoregressive_step`, `geomind_rmsnorm`, and `geomind_ffn_cascade` OpenCL kernels in `test/geomind/train.cl`.
4. [ ] Pipeline chunk execution in `geomind_train_streaming_steady_state` with resident VRAM hidden state and single chunk-end loss sync.
5. [ ] Recompile `bin/geomind.exe` with `cartanc.exe` and synchronize all 4 binaries.
6. [ ] Empirically verify >80% GPU compute saturation on NVIDIA RTX 2000 Ada Generation Laptop GPU via `nvidia-smi`.
7. [ ] Update `ISSUES.md`, `CHANGELOG.md`, and generate archive walkthrough.
