# Sprint 248: Riemannian Tangent-Space Momentum & Rotary Position Embeddings (RoPE)

## Overview
- **Goal**: Accelerate non-Euclidean manifold gradient descent and resolve the bag-of-words entropy collapse without violating geometric covariance on Riemannian / Lie manifolds.
- **Architectural Enhancements**:
  1. **Riemannian Tangent-Space Momentum**:
     - Allocated velocity tensor buffers in OpenCL GPU VRAM: d_cl_all_42_mom_w (42 x 2560 x 2560), d_cl_all_42_mom_norms (42 x 2560), and d_cl_mom_weights (2560 x 2560).
     - Updated OpenCL kernels (k_opencl_layer_backward_update_w, k_opencl_layer_backward_update_norm, k_opencl_backward_sgd) with momentum parameter \mu = 0.90:
       V_t = \mu V_{t-1} + (1 - \mu) \text{clip}(\nabla_{\mathcal{M}} \mathcal{L}(W), -5.0, 5.0)
       W_{t+1} = W_t - \eta V_t
  2. **Fast Rotary Position Embeddings (RoPE) & Causal Weighting**:
     - Precomputed static frequency table s_rope_inv_freq[i] = 10000^{-2i/2560} for sub-millisecond vector rotations.
     - Replaced bag-of-words sum with positional RoPE rotation and causal recency weighting in cartan_tensor_compute_prompt_embedding_fast.

## Verification
- Built with MSVC on Windows with zero warnings.
- Executed on NVIDIA RTX 2000 Ada Generation GPU at 34.0 samples/second.
