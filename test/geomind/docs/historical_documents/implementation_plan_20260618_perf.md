# [Optimization of NCE Kernel & Sparse Embeddings]

The goal of this implementation is to restore the 5x training speed lost during the transition to Causal Pretraining with the InfoNCE loss and integer token IDs.

## User Review Required

The contrastive InfoNCE loss was originally added to solve centroid collapse. I will drastically optimize it but **keep the mathematical logic exactly the same**. 

## Proposed Changes

### 1. Optimize `hybrid_geodesic_nce_loss_and_grad` (Contrastive Loss)
The current OpenCL kernel computes the Euclidean norm of every target vector `j` repeatedly for every prediction vector `i` in the inner-most loop, doing billions of redundant global memory reads and `sqrt` operations.
- **Change**: Pre-compute `t_norm` for all targets in a separate buffer `target_norms` before the $O(N^2)$ loops. 
- **Change**: Pass `target_norms` to `hybrid_geodesic_nce_loss_and_grad`. 
- **Effect**: This will remove 248 memory reads and 1 `sqrt` per iteration, cutting the operations inside the $O(N^2)$ loops by over 60%, and allowing the GPU L2 cache to seamlessly handle the remaining dot products.

### 2. Implement Sparse Embedding Updates in `FinslerOptimizer`
Because the model now uses `ContinuousEmbedding`, the 65-million parameter embedding matrix is fully dense-updated every step, even though only ~2048 tokens are active in a batch. 
- **Change**: Modify `core/e8_engine.py` to extract `np.unique(token_ids)` and pass them to the C++ engine as `active_indices`.
- **Change**: Add `finsler_geodesic_update_sparse` in `kernels.cl.h` which accepts an array of active row indices.
- **Change**: Update `FinslerOptimizer::step()` to use the sparse kernel for `"embedding_weight"`, reducing the updated rows from 262,144 to ~2000.

### 3. Remove Dead Code
- **Change**: Delete `bcen_bce_mse_loss_backward` and `info_nce_loss_and_grad` (the old unused versions) from `kernels.cl.h`.

## Verification Plan

### Manual Verification
1. I will rebuild the C++ extension (`python setup.py build_ext --inplace`).
2. You can then run `python .\launch.py` to verify the `tok/s` returns to the 4000-5000 range.
