# Phase 3 Transition: 1736D Multi-Decomposition Engine (C++ OpenCL)

## Goal Description
Following the successful continuous pretraining on the E8 manifold (hitting the theoretical 0.71 plateau), we are transitioning to **Phase 3: The 1736D Multi-Decomposition Engine**. The current pure C++ OpenCL engine (`engine.cpp`) processes a single 248D representation. We must expand the native backend to simultaneously process the 7 Maximal Subgroups of the $E_8$ manifold, expanding the network's geometric capacity to 1736 dimensions.

The 7 parallel processing streams map to:
1. $SO(16)$
2. $E_7 \times SU(2)$
3. $E_6 \times SU(3)$
4. $SU(9)$
5. $F_4 \times G_2$
6. $SU(5) \times SU(5)$
7. $SO(10) \times SU(4)$

## User Review Required
> [!WARNING]
> Implementing 7 parallel 248D streams in OpenCL will increase VRAM utilization by 7x. With `batch_size=8` and `seq_len=256`, we must ensure this doesn't exceed the RTX 2000 Ada constraints or trigger Windows TDR timeouts. 
> We will implement stream-level concurrency so the GPU calculates the 7 subgroups asynchronously.

## Proposed Changes

### 1. Configuration & Engine Initialization
#### [MODIFY] [config.py](file:///c:/Users/rich-/source/repos/GeoMind/config.py)
- Change `NUM_DECOMP_STREAMS = 1` back to `7`.

#### [MODIFY] [csrc/modules.cpp](file:///c:/Users/rich-/source/repos/GeoMind/csrc/modules.cpp)
- **E8MultiStreamEngine**: Wrap the existing `E8CosformerAttention` and `E8MoE` into a `vector<unique_ptr<E8Stream>> streams(7)`.
- Initialize 7 independent sets of weights.
- Implement the **Sasaki Router**: A gating mechanism that weights the 7 streams before combining them back into the residual stream.

### 2. OpenCL Kernel Parallelization
#### [MODIFY] [csrc/kernels.cl.h](file:///c:/Users/rich-/source/repos/GeoMind/csrc/kernels.cl.h)
- Modify the forward pass kernels to accept a `stream_idx` or run in a 3D grid layout (`batch, seq_len, stream`).
- Implement the **Weyl Group Mixers**: A cross-stream interaction kernel that allows the 7 maximal subgroups to mathematically entangle their coordinate representations.

### 3. C++ API Interface
#### [MODIFY] [csrc/engine.cpp](file:///c:/Users/rich-/source/repos/GeoMind/csrc/engine.cpp)
- Update the PyBind11 interface to handle the multi-stream state.
- Expose the Sasaki metric tracking variables to Python for logging.

## Verification Plan
### Automated Tests
- Run `python scratch/test.py` to ensure the C++ extension compiles successfully with 7 streams.
- Ensure `NUM_DECOMP_STREAMS = 7` does not throw an Out of Memory (OOM) error or trigger a TDR crash.

### Manual Verification
- Launch `run_visible_now.bat` and verify that the initial loss resumes correctly and that the 7 streams begin dynamically separating (which proves gradient symmetry is broken).
