# Sprint 355 Implementation Plan: Lie Group Multi-Stream Architecture, Non-Euclidean Metrics & OOV De-aliasing

## 1. Problem Diagnosis & Mathematical Rationale
- **The 4.31 Training Loss Plateau**: The model reached a plateau at ~4.31 loss / 74.8 VPPL because the original 8-stream Lie group manifold and 16-expert Freudenthal Magic Square MoE architecture had been flattened into a single 2560x2560 linear matrix during the historical port from C++/Rust to CARTAN.
- **Out-of-Vocabulary Token Aliasing**: Over 39.65% of tokens in the training corpus were >= 2560. Because of `tok % 2560`, these tokens were wrapped around into unrelated token embedding rows, corrupting representations.
- **Gradient Attenuation**: Backprop scaled updates by 1/dim = 1/2560, making weight updates ~10^-8 and starving the network.
- **Euclidean Infiltration**: RMSNorm, SGD updates, Sasaki routing, and FFN cascades were using flat Euclidean distances instead of the authentic Killing-Cartan metric, Finsler-Randers drift, and Sasaki tangent bundle metrics.

## 2. Proposed Changes

### Phase A: Non-Euclidean Standard Library (`src/std/geom.cl`)
- Implement `geom_riemannian_dot(v1, v2, metric_diag, dim)`
- Implement `geom_riemannian_norm(v, metric_diag, dim)`
- Implement `geom_finsler_randers_distance(x, y, drift_b, metric_diag, dim)`
- Implement `geom_sasaki_phase_space_distance(pos1, mom1, pos2, mom2, metric_diag, dim)`
- Implement `geom_killing_form_dynkin_weight(submanifold_idx)` across the 8 Lie submanifolds.

### Phase B: GPU Compute Pipeline & Kernels (`test/geomind/train.cl`)
- Add `g_buf_drift_vector` and `g_buf_metric_diag` in GPU VRAM and host memory.
- Implement Finsler-Randers Sherman-Morrison geodesic update in `geomind_sgd_backward`: g' = g - (g . b) / (1 + ||b||^2) * b.
- Replace 1/dim with 1/sqrt(dim) = 0.0197642 for proper gradient scale.
- Map tokens >= 2560 to <unk> (token 3) in autoregressive and SGD kernels.
- Endow `geomind_rmsnorm` with metric tensor g_i.
- Wire 8 Lie cortical submanifolds in `geomind_autoregressive_step`.
- Wire 16 Freudenthal Magic Square experts across 4 algebraic quadrants in `geomind_ffn_cascade`.
- Update all argument bindings in `geomind_train_chunk_gpu_pipelined`.

### Phase C: CPU Engine & Routing Alignment (`test/geomind/chat.cl`, `test/geomind/moe.cl`, `test/geomind/e8_attention_engine.cl`)
- Replace modulo token aliasing with token 3 mapping in `chat.cl`.
- Align CPU `cartan_tensor_update_autoregressive_state` with 8 Lie submanifold evolutions.
- Apply Killing form weights in `moe.cl` (`geomind_sasaki_route` and `geomind_sasaki_stream_routing`).
- Apply Killing form weights in `e8_attention_engine.cl` (`cartan_tensor_rmsnorm`, FFN cascade, energy).

### Phase D: Compilation & Verification
- Compile `test/geomind/main.car` via `cartanc.exe`.
- Verify zero compilation errors and zero regression.
- Update `ISSUES.md` (`[ISSUE-106]`) and `CHANGELOG.md` (`[8.312.0]`).
