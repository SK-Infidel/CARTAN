# Sprint 258: Asynchronous PCIe Streaming & Scaled Micro-Batch Execution

## Objectives
1. Convert host-to-device transfers to asynchronous non-blocking DMA writes (`CL_FALSE`).
2. Scale micro-batch execution to $mbs=224$ to halve VRAM bandwidth during 42-layer weight backpropagation.
3. Replace duplicate synchronous checkpoint writes with single write + `CopyFileA`.

## Implementation Details
1. **Non-Blocking DMA Transfers (`src/cartanc/c_runtime.c`)**:
   - `clEnqueueWriteBuffer` calls for batch activations, targets, and IC weights updated to `CL_FALSE`, preventing CPU halts during GPU dispatch.
2. **Scaled Micro-Batch Size ($mbs=224$) (`test/geomind/geomind_driver.c`)**:
   - 448-sample slices now process in 2 sub-batches of 224 samples, cutting 42-layer reverse-mode weight matrix writes from $4\times \to 2\times$ per slice ($4.4\text{ GB}$ bandwidth savings per slice).
3. **Optimized Checkpoint Snapshotting (`test/geomind/geomind_driver.c`)**:
   - Replaced duplicate `save_signed_checkpoint` calls with a single save to `best_path` followed by Windows `CopyFileA(best_path, ckpt_path, FALSE)`.

## Empirical Verification
- Recompiled `bin/geomind.exe` with `zig cc`.
- Verified clean GPU execution and monotonic loss reduction on the NVIDIA RTX 2000 Ada GPU.
