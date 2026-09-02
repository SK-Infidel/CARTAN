# Implementation Plan: 42-Layer Full Manifold Backpropagation Engine

## 1. Context & Motivation
The GeoMind causal cross-entropy training plateaued at ~4.43 validation loss because `k_opencl_backward_sgd` was previously only updating the final LM head projection ($2560 \times 2560$, 6.5M params) while the underlying 42 MoE layers (270M params) remained frozen in `CL_MEM_READ_ONLY` buffers.

## 2. Technical Architecture
1. **Buffer Reconfiguration**:
   - Upgrade `d_cl_all_42_layers`, `d_cl_all_42_norms`, and `d_cl_all_42_routers` from `CL_MEM_READ_ONLY` to `CL_MEM_READ_WRITE`.
   - Allocate `d_cl_saved_norm_x`, `d_cl_saved_inv_rms`, `d_cl_saved_x_cur` ($42 \times B \times 2560$), `d_cl_batch_dx` ($B \times 2560$), and `d_cl_batch_dz` ($B \times 2560$).
2. **Forward Activation Stashing**:
   - `k_opencl_42layer_forward_lie_manifold` stashes per-layer $s_{norm\_x}$, $inv\_rms$, and $s_{cur}$ for exact gradient reconstruction.
3. **Full 42-Layer Reverse-Mode Automatic Differentiation**:
   - Head backward: computes $dW_{head}$ and backpropagates through final RMSNorm into $dx_{42}$.
   - Layer backward loop ($l = 41 \to 0$):
     - `k_opencl_layer_backward_dz_and_dx`: computes $dz_l[b, d]$ from $dgelu$, backpropagates $d\tilde{x}_l = dz_l \cdot W_l$, applies RMSNorm backward, and adds residual to compute $dx_l$.
     - `k_opencl_layer_backward_update_w`: computes $dW_l[r, c] = \frac{1}{B} \sum_b dz_l[b, r] \tilde{x}_l[b, c]$, projects via Sherman-Morrison Finsler-Randers metric, applies AGC clipping, Continuous Hopfield Ising Spin Energy relaxation ($\tanh(\beta v)/\beta$), and retracts $W_l$ via $\text{Exp}_{W_l}(v)$.
     - Updates layer norm weights $norm_l$.
4. **Checkpoint Synchronization**:
   - `cartan_sync_42layers_from_gpu()` reads all 42 updated layer tensors, norms, routers, and head weights into host memory before exporting signed checkpoints.
