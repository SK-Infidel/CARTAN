# Sprint 300 Implementation Plan: 8 Lie Subgroup Cortical Streams Integration

## Sprint Goal
Deliver Phase 59 Item 2: Wire the 8 Lie Subgroup Cortical Streams (`streams.cl`: Cosformer, SSM, Spectral, Poincare, Homology, Eikonal, Heat Kernel, Triality) directly into the 42-layer manifold forward pass (`e8_attention_forward_step`), partitioning the 2560-dimensional representation into 8 320-dimensional cortical submanifolds.

---

## Pre-Sprint Scrum & Code Review Findings
- **Audit Discovery (`[ISSUE-050]`)**:
  - In `src/cartanc/geomind_runtime.c`: `e8_attention_forward_step` (lines 2751-2862) executed block-diagonal rotations and GeGLU activations, but never applied the 8 Lie Subgroup Cortical Streams.
  - In `test/geomind/streams.cl`: The 8 streams operated as scalar 1D vector operators without a full 2560-D partitioned manifold transformation (`geomind_streams_manifold_forward`).
- **Mathematical Structure**:
  - $2560 = 8 \times 320$:
    - Stream 0: $SO(16)$ Cosformer Linear Attention ($0..319$)
    - Stream 1: $E_7 \times SU(2)$ Selective State-Space Recurrence ($320..639$)
    - Stream 2: $E_6 \times SU(3)$ Spectral Fourier Harmonic Filter ($640..959$)
    - Stream 3: $SU(9)$ Poincare Conformal Metric ($960..1279$)
    - Stream 4: $F_4 \times G_2$ Simplicial Homology Density ($1280..1599$)
    - Stream 5: $SO(10) \times SU(4)$ Visual Eikonal Geodesic Ray-Tracing ($1600..1919$)
    - Stream 6: $SU(5) \times SU(5)$ Heat Kernel Laplacian Diffusion ($1920..2239$)
    - Stream 7: $SU(3)^3$ Triality Symplectic Cyclic Rotation ($2240..2559$)

---

## Tasks & Execution Steps

### 1. Extend Pure CARTAN Streams Library (`test/geomind/streams.cl`)
- Implement `geomind_streams_manifold_forward(h: ptr, mix: float) -> ptr`: partitions a 2560-dimensional vector into 8 320-D submanifolds, transforms each chunk through its corresponding Lie stream, and blends with residual state.
- Implement `geomind_streams_layer_step(h: ptr, layer_idx: float) -> ptr`: dynamically emphasizes the stream corresponding to $l \pmod 8$.

### 2. Implement C Runtime Lie Cortical Streams Engine (`src/cartanc/geomind_runtime.c`)
- Declare and implement `cartan_apply_8_lie_streams(float* h, size_t dim, float stream_mix)`.
- Declare and implement `cartan_apply_8_lie_streams_vec(void* hidden_ptr, double stream_mix) -> double`.
- Integrate `cartan_apply_8_lie_streams` into the 42-layer physical Gemma cascade and the 16-layer Freudenthal fallback in `e8_attention_forward_step`.

### 3. Create Target 52 Regression Test (`test/compiler_suite/test_lie_streams.car`)
- Authentically verify:
  1. All 8 individual Lie stream submanifolds with mathematical correctness.
  2. 2560-D partitioned manifold transformation (`geomind_streams_manifold_forward`).
  3. C runtime integration (`cartan_apply_8_lie_streams_vec`).
  4. Layer-dependent stream modulation and energy preservation.

### 4. Wire Target 52 into Test Runner & Execute Empirical Verification
- Update `test/compiler_suite/run_tests.car` with Target 52.
- Rebuild `geomind.exe` and test `--chat`.
- Run `scratch/run_tests.exe` and ensure 52/52 tests pass 100%.
- Update `ROADMAP.md`, `ISSUES.md`, and `CHANGELOG.md`.
