# Sprint 386 Walkthrough: Non-Euclidean Cortical Stream Stability & Metric Decoupling

## Overview
Remediated 6 critical non-Euclidean mathematical instabilities, gradient attenuation defects, scale distortions, and uncalibrated threshold braking mechanisms across GeoMind cortical streams, WGSL shaders, OpenCL kernels, and CPU fallbacks.

## Key Changes Implemented

### 1. Stream 4 (F4 $\times$ G2 Homology) Contractive Saturation
- **Before**: Unbounded cubic polynomial $0.10 v^3$ caused super-exponential activation explosion ($v > 2 \to \infty$).
- **After**: Contractive hyperbolic saturation:
  $$v_{\text{out}} = 0.90 v + 0.25 \tanh(0.02 v^3 kw) + 0.10 \sin(2v)$$
  Activations strictly bounded in $[-0.90|v| - 0.35, 0.90|v| + 0.35]$.
- **Files Modified**: [`test/geomind/streams.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/streams.cl), [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl) (WGSL, OpenCL `geomind_autoregressive_step`).

### 2. Stream 5 (SO(10) $\times$ SU(4) Eikonal) Contractive Wavefront Step
- **Before**: $1.265 |v| + 0.20 v$ had eigenvalue $\lambda = 1.465 > 1$, forcing positive feedback runaway and destroying negative coordinates.
- **After**: Contractive, orientation-preserving geodesic travel:
  $$v_{\text{out}} = 0.70 v + 0.25 \tanh\left(\sqrt{v^2 kw + 0.01}\right) \text{sgn}(v)$$
  Guaranteed contractive ($\lambda = 0.70 < 1$).
- **Files Modified**: [`test/geomind/streams.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/streams.cl), [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl).

### 3. Stream 2 (E6 $\times$ SU(3) Spectral Fourier) Positive Spectral Envelope
- **Before**: $\sin(\dots) \times 0.7071 + 0.5 \in [-0.207, 1.207]$ flipped signs randomly.
- **After**: Positive envelope: $\cos((i + 1) \cdot 0.1 kw) \times 0.25 + 0.75 \in [0.50, 1.00]$.
- **Files Modified**: [`test/geomind/streams.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/streams.cl), [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl).

### 4. Scale-Invariant Riemannian RMSNorm
- **Before**: $\sum v_i^2 g_i$ divided only by $\text{dim}$, giving an unnormalized $\bar{g} = 2.625$ factor that artificially shrank states by $38\%$ every step ($1 / \sqrt{2.625} \approx 0.617$).
- **After**: Normalized by mean metric trace: $\text{total\_sq} / (\text{dim} \times 2.625)$, ensuring scale invariance in both forward `geomind_rmsnorm` and backward `geomind_rmsnorm_backward`.
- **Files Modified**: [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl).

### 5. Vocabulary Column Metric Decoupling & Normalized Metric Backward Scaling
- **Before**:
  - `geomind_sgd_backward` and CPU fallback evaluated `drift[col]` and `metric[col]` along vocabulary token IDs ($0 \dots 2559$), distorting token gradients based on arbitrary WordNet indices.
  - `geomind_backward_head_gemv` divided by $g_r$, starving Stream 4 ($g_r = 5.0$) of $80\%$ of its gradient feedback.
- **After**:
  - Restored exact cross-entropy delta $\delta_{\text{col}}$ without column distortion.
  - Normalized metric scaling $inv\_g = 2.625 / g_r$ preserves balanced backward gradient propagation.
- **Files Modified**: [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl).

### 6. Recalibrated Training Control Thresholds
- **Before**: Static gap threshold $0.03\text{ nats}$ ($\Delta PPL \approx 1$) triggered false-positive braking on natural train/validation holds, pinning LR to $0.0006$.
- **After**: Static gap set to $0.38\text{ nats}$ ($\Delta PPL > 45$), with dynamic braking governed by actual rising validation loss velocity ($\Delta AVL > 0.002$).
- **Files Modified**: [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl).

### 7. Secondary Code Review & Secondary Stream Parity
- **Findings**:
  - `test/geomind/chat.cl` (`cartan_tensor_update_autoregressive_state`): Contained the un-bounded Stream 4 cubic term and expansive Stream 5 square root travel. Remediated to match bounded contractive formulations.
  - `src/std/gpu.cl` (`lie_streams_fwd` OpenCL driver entry point): Contained legacy Stream 2 sign-flipping harmonic and Stream 5 square root travel. Remediated with contractive and non-negative formulations.
- **Files Modified**: [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl), [`src/std/gpu.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/gpu.cl).

## Verification Results
1. **Compilation**: Clean compilation via `cartanc.exe build test/geomind/main.car -o test/geomind/geomind.exe`.
2. **SHA-256 Binary Parity**:
   `26ED65191AE8832971B7685BD612B83BC6D77AF193B8D1CB775846647443B576` verified identical across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
3. **Semantic Analogy Benchmarks (`--eval-analogy`)**:
   - King - man + woman = queen (Rank 1, Cosine Sim 0.4215, Margin +0.10842)
   - he - him + her = she (Rank 1, Cosine Sim 0.4935, Margin +0.11928)
   - father - man + woman = mother (Rank 1, Cosine Sim 0.4711, Margin +0.09663)
   - boy - man + woman = girl (Rank 1, Cosine Sim 0.5809, Margin +0.26524)
   - **Overall**: 4/4 PASS.
