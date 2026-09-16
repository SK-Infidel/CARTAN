# Sprint 330: Pure Direct Pointer Vectorization & High-Throughput Manifold Training Engine

## 1. Objectives & Scope
- **Goal**: Accelerate GeoMind Stage 1 Cloze training throughput from ~640 B/s to >15,000 B/s (20x-50x speedup).
- **Core Architecture**:
  1. Eliminate 1.31M scalar function call frames per token in `cartan_tensor_train_step` using direct pointer indexing (`ptr[2.0 + idx]`).
  2. Invert forward dot-product loop order ($r$ outer, $c$ inner) to achieve stride-1 sequential L1 cache hits and enable LLVM/Clang SIMD vectorization.
  3. Precompute error delta vector $\Delta[c]$ and update cortical weights row-wise with stride-1 contiguous stores.
  4. Direct pointer indexing across `e8_attention_forward_step_with_momentum`, `cartan_tensor_rmsnorm`, `cartan_tensor_update_autoregressive_state`, and `geomind_sasaki_stream_routing`.
  5. Decouple disk checkpointing cadence to every 2,500 chunks (~10-15 minutes) while keeping manifest checkpointing at 500 chunks.

## 2. Dependency Graph & Affected Components
- `test/geomind/train.cl`:
  - `cartan_tensor_train_step`: Direct pointer forward and backward updates.
  - `geomind_train_streaming_steady_state`: Direct zeroing of `cur_h` and decoupled checkpointing cadence.
- `test/geomind/e8_attention_engine.cl`:
  - `e8_attention_forward_step_with_momentum`: Direct pointer indexing on `h_cur` for 16-layer FFN cascade.
  - `cartan_tensor_rmsnorm`: Direct pointer reads and stores.
- `test/geomind/chat.cl`:
  - `cartan_tensor_update_autoregressive_state`: Direct pointer reads and stores on `h`.
- `test/geomind/moe.cl`:
  - `geomind_sasaki_stream_routing`: Direct pointer indexing on `position` and `momentum`.

## 3. Definition of Done (DoD)
- [ ] Clean compilation of `cartanc.exe` and `geomind.exe`.
- [ ] All 47 compiler snapshot regression tests passing.
- [ ] Empirical throughput benchmark demonstrating >15x speedup without loss divergence.
- [ ] Resume training cleanly from manifest offset 204800.0 without memory leaks or crashes.
- [ ] Documentation updated in `CHANGELOG.md`, `ISSUES.md`, and `docs/archive/`.
