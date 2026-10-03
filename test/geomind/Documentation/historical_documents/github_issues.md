# GeoMind Architectural & Mathematical Bug Reports (GitHub Issues)

This document contains a set of itemized, highly descriptive bug reports formatted as GitHub issues. They detail the exact code locations, mathematical breakdowns, and resolution steps for the plateaus encountered during causal pretraining.

---

## Issue 1: Broken Temporal Gradient Flow in `E8LatticeWaveSSM` and `SpectralMemory`

### **Category/Component**
`csrc/modules.cpp` (SSM / Recurrent Topology Layers)

### **Description**
During the forward pass of the recurrent modules `E8LatticeWaveSSM` and `SpectralMemory`, sequence state is accumulated across time using `geomath::cumsum_inplace(*tensor, 1)`. However, the backward pass of both modules completely bypasses this operation, acting as if the cumulative sum were a simple identity mapping. 

Because `cumsum` is a recurrent dependency across the sequence length ($L$), gradient flow must propagate backward chronologically (from the last token to the first). Skipping this step means gradients from later tokens are never propagated back to earlier tokens. Consequently, the network behaves like a bag-of-words model and is completely unable to learn grammar, sequence context, or the spacing rules of English.

### **Code Reference**
In [csrc/modules.cpp:L357-366](file:///c:/Users/rich-/source/repos/GeoMind/csrc/modules.cpp#L357-L366):
```cpp
std::unique_ptr<Tensor> E8LatticeWaveSSM::backward(const Tensor& grad_output, const Tensor& cached_x, const Tensor* g_metric) {
    auto grad_h = norm_->backward(grad_output, *cached_h_states_, g_metric);
    auto grad_div = w_out_->backward(*grad_h);
    // BUG: grad_div is passed directly to w_x_ and w_y_ backward passes,
    // completely skipping the backward pass of cumsum_inplace!
    auto grad_u = tensor_multiply(*grad_div, *cached_proj_y_);
    auto grad_v = tensor_multiply(*grad_div, *cached_proj_x_);
    ...
}
```

In [csrc/modules.cpp:L384-390](file:///c:/Users/rich-/source/repos/GeoMind/csrc/modules.cpp#L384-L390):
```cpp
std::unique_ptr<Tensor> SpectralMemory::backward(const Tensor& grad_output, const Tensor& cached_x, const Tensor* g_metric) {
    auto grad_mem = out_proj_->backward(grad_output);
    auto gx1 = tensor_multiply(*grad_mem, *cached_filter_);
    // BUG: grad_f is the gradient post-cumsum, but is fed directly 
    // into filter_proj_ backward without backpropagating through cumsum!
    auto grad_f = tensor_multiply(*grad_mem, *cached_x_);
    auto gx2 = filter_proj_->backward(*grad_f);
    return tensor_add(*gx1, *gx2);
}
```

### **Mathematical Root Cause**
Given a forward state $y_t = \sum_{j=1}^t x_j$, the gradient of the loss $L$ with respect to the input elements $x_i$ is defined by:
$$\frac{\partial L}{\partial x_i} = \sum_{t=i}^T \frac{\partial L}{\partial y_t}$$
This mathematically corresponds to a **reverse cumulative sum** (accumulating from index $T-1$ down to $0$). Bypassing this sequence-dimension operation drops the sequence Jacobian, resulting in zero sequence-context parameter updates.

### **Proposed Resolution**
1. Append a new OpenCL kernel to `csrc/kernels.cl.h` called `cumsum_backward_inplace` that performs a reverse cumulative sum along the sequence dimension:
   ```cl
   __kernel void cumsum_backward_inplace(__global float* grad, int B_batch, int seq_len, int dim) {
       int b = get_global_id(0);
       int d = get_global_id(1);
       if (b < B_batch && d < dim) {
           float running_sum = 0.0f;
           for (int s = seq_len - 1; s >= 0; --s) {
               int offset = b * seq_len * dim + s * dim + d;
               running_sum += grad[offset];
               grad[offset] = running_sum;
           }
       }
   }
   ```
2. Bind `cumsum_backward_inplace` inside `csrc/math_primitives.cpp` (and declare it in `csrc/math_primitives.h`) as `void cumsum_backward_inplace(Tensor& grad)`.
3. In `csrc/modules.cpp`, execute this reverse cumsum on the gradient tensors (`grad_div` and `grad_f`) before passing them down to the projections.

---

## Issue 2: Optimizer String Match Bug Disables Finsler/Randers Updates

### **Category/Component**
`csrc/optimizer.cpp` (Finsler Gauge Optimizer)

### **Description**
The `FinslerOptimizer` is designed to apply the Inverse Randers Metric (background drift field updates) to streams 1–6 while keeping stream 0 (the flat backbone) running on standard Euclidean updates. It attempts to detect non-backbone streams using string matching on parameter names:
```cpp
if (key.find("stream_0") == std::string::npos && key.find("stream_") != std::string::npos)
```

However, the layers in the engine are registered with prefixes like `stream0_attn_q`, `stream1_attn_q` (where the stream index is immediately followed by an underscore, without a preceding underscore!). Because there is no underscore between `stream` and the digit, `key.find("stream_")` always returns `npos` (not found). As a result, the optimizer never detects the stream layers, `use_beta` is forced to `0` for all updates, and the entire Finsler/Randers velocity space geometry is disabled.

### **Code Reference**
In [csrc/optimizer.cpp:L93-102](file:///c:/Users/rich-/source/repos/GeoMind/csrc/optimizer.cpp#L93-L102):
```cpp
// BUG: Looking for "stream_0" and "stream_" which do not match "stream0_" or "stream1_"
if (key.find("stream_0") == std::string::npos && key.find("stream_") != std::string::npos) {
    std::string b_key = key;
    if (key.substr(key.length() - 2) == "_w") {
        b_key = key.substr(0, key.length() - 2) + "_b";
    }
    if (params_.count(b_key) > 0) {
        beta_tensor = params_[b_key];
        use_beta = 1; // NEVER REACHED!
    }
}
```

### **Mathematical Root Cause**
In Finsler-Randers space, parameter updates are guided by the metric tensor $g_{ij}(w, y) = a_{ij}(w) + b_i(w) y_j$, representing a dynamic drift field. By defaulting to `use_beta = 0` due to the naming mismatch, the optimizer falls back to standard Riemannian Adam on the $E_8$ hypersphere. While stable, this prevents the model from mapping directionally asymmetric semantic context ($A \to B \neq B \to A$) and restricts training convergence.

### **Proposed Resolution**
Modify the string check in `csrc/optimizer.cpp` to correctly find the `stream` pattern without the separating underscore:
```cpp
if (key.find("stream0") == std::string::npos && key.find("stream") != std::string::npos)
```
This correctly isolates parameters belonging to `stream1_` through `stream6_` and unlocks Finsler geodesic adjustments for those streams.

---

## Issue 3: Euclidean Placeholders for Non-Euclidean Attention Topologies

### **Category/Component**
`csrc/modules.cpp` (Attention Mechanics)

### **Description**
Four of the seven subgroup attention topologies in `csrc/modules.cpp` (`HyperbolicAttention`, `TopologicalHomologyAttention`, `GeodesicRayTracingAttention`, and `HeatKernelDiffusionAttention`) are implemented as simple Euclidean MLP placeholders consisting of a linear projection, a flat `tanh` activation, and a linear output projection. They do not reference the manifold's metric tensor, nor do they calculate geodesic paths. 

### **Code Reference**
In [csrc/modules.cpp:L393-460](file:///c:/Users/rich-/source/repos/GeoMind/csrc/modules.cpp#L393-L460):
```cpp
std::unique_ptr<Tensor> HyperbolicAttention::forward(const Tensor& x, const Tensor* g_metric) {
    auto u = in_proj_->forward(x);
    geomath::tanh_inplace(*u); // Flat Euclidean activation
    auto out = out_proj_->forward(*u);
    return out;
}
// TopologicalHomologyAttention, GeodesicRayTracingAttention, 
// and HeatKernelDiffusionAttention have identical placeholder logic.
```

### **Proposed Resolution**
Upgrade the placeholder MLPs to native OpenCL kernels that compute their respective non-Euclidean metric properties:
1. **Hyperbolic Attention**: Project coordinates into the Poincaré Ball ($D^n$) and calculate attention metrics using the Poincaré distance function:
   $$d(u,v) = \text{arcosh}\left(1 + 2\frac{\|u-v\|^2}{(1-\|u\|^2)(1-\|v\|^2)}\right)$$
2. **Heat Kernel Diffusion Attention**: Replace query-key projections with a 1D Graph Laplacian solver ($H_t = \exp(-tL)$) to smooth sequence states based on topological metric density.
3. **Geodesic Ray-Tracing Attention**: Implement an approximation of Eikonal path integrals over the metric tensor space to represent spatial sequence gravity.

---

## Issue 4: Missing Virtual Parameters & Multi-Matrix Ingestion

### **Category/Component**
`csrc/engine.cpp` & `csrc/modules.cpp` (Scaling & Capacity Constraints)

### **Description**
In the original design blueprint (MHTML file), the E8 architecture is conceptualized to scale its capacity via **virtual parameters** using:
1. **Multi-Matrix Input**: Synchronized matrices for Context ($M_{\text{context}}$), Gauge ($M_{\text{gauge}}$), and Coupling ($M_{\text{coupling}}$) combined via a Kronecker product layer ($Y = A \otimes B$).
2. **Weyl Group Reflections**: Applying discrete reflections across the 240 roots of $E_8$ (order $696,729,600$) to project small base weights into a massive virtual parameter space.

The current implementation instead uses standard explicit dense parameter allocations on the GPU. Because the model is physically restricted to a single-layer configuration to stay within TDR constraints, storing only explicit weights limits the representation capacity of the network, contributing directly to the pretraining loss stalling at `~8.8`.

### **Proposed Resolution**
1. **Multi-Matrix Ingestion**: Refactor the embedding and engine pipelines to accept synchronized Cartan subalgebra gauge representations and root interaction coordinates, executing a register-level Kronecker tensor product forward pass.
2. **Weyl Reflection Kernel**: Write an OpenCL weight reflection kernel that dynamically rotates and mirrors base projection tensors using Weyl reflections on-the-fly inside the GPU registers. This shifts the scaling bottleneck from GPU VRAM bandwidth to active ALU computation.
