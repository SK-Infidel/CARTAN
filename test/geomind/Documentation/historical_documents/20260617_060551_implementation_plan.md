# InfoNCE Contrastive Loss Implementation

This plan outlines the steps to replace the standard Spherical Cosine Loss in the C++ engine with a Contrastive Loss (InfoNCE). This will solve the "Centroid Collapse" phenomenon where the model predicts the average of related words instead of sharp sequence transitions.

## User Review Required
> [!IMPORTANT]
> The engine will now use **in-batch negatives**. For every token prediction, it will push the predicted coordinate toward the correct next coordinate, and **actively repel** it away from all other coordinates in the current sequence batch.
> This requires an additional Temperature parameter (`tau`). I propose a default `tau = 10.0f`, which is standard for metric learning in geometric spaces like CLIP.

## Open Questions
- Does `tau = 10.0f` seem reasonable to you, or would you prefer it exposed to the python layer so you can tune it dynamically in `causal_pretrain.py`? (I will hardcode it in C++ for now to get it working fast, but we can expose it later).

## Proposed Changes

### `csrc/kernels.cl.h`
#### [MODIFY] kernels.cl.h
- Create a new `__kernel void info_nce_loss_and_grad(...)` that mimics the signature of the old loss function.
- **Pass 1:** Iterate over all `j` in `batch * seq_len` to calculate the `cos_sim(pred[i], target[j])` and find the `max_sim` for numerical stability.
- **Pass 2:** Iterate again to compute `sum_exp = sum(exp(tau * cos_sim - max_sim))`.
- **Pass 3:** Iterate a final time to accumulate the gradient: `grad += (P[j] - delta_ij) * grad_cos_ij`.
- Scale the final gradient by the target's `shannon_weight` (Information Content) to preserve your explicit conceptual mass mechanics.

### `csrc/engine.cpp`
#### [MODIFY] engine.cpp
- In `GeoMindHybridEngine::compute_loss_and_backward`, switch the kernel invocation from `spherical_cosine_loss_and_grad` to `info_nce_loss_and_grad`.
- Pass the new `tau` parameter (`10.0f`) to the kernel.

## Verification Plan

### Automated Tests
1. Recompile the C++ engine using `python setup.py build_ext --inplace`.
2. Ensure it compiles without OpenCL syntax errors.

### Manual Verification
1. We will monitor the first few epochs of `causal_pretrain.py` to ensure the loss successfully descends and does not output `NaN`s (a common issue if the `sum_exp` normalization isn't stable).
