# Sprint 422 Task List: Saliency Attractor Selection

- [x] **Task 1: Saliency Attractor Selector Module (`src/std/saliency_attractor.cl`)**
  - [x] Implement `saliency_select_domain_attractor_indices(cg, target_domain, max_attractors) -> ptr`.
  - [x] Implement `saliency_format_attractor_buffer(cg, rule_indices, out_buf, dim, max_attractors) -> float`.
  - [x] Implement `saliency_select_resonant_attractors(bank, query_vec, dim, max_attractors) -> ptr`.

- [x] **Task 2: Fast Salient Hopfield Relaxation (`src/std/resonator.cl`)**
  - [x] Implement `resonator_salient_hopfield_relax(bank, state_vec, dim, beta, steps, top_k) -> float`.

- [x] **Task 3: Streaming Training Loop Integration (`test/geomind/train.cl`)**
  - [x] Add `g_synced_gpu_domain` tracker and zero-latency caching.
  - [x] Implement `train_sync_salient_attractors_to_gpu(active_domain, cg) -> float`.
  - [x] Hook into pre-step domain dispatch prior to `geomind_train_chunk_gpu_launch_pass`.
  - [x] Hook cache invalidation on post-sleep consolidation.

- [x] **Task 4: Empirical Verification & Regression Testing**
  - [x] Create and run `test/geomind/nses/test_sprint9_saliency_attractors.car` (4/4 gates passed).
  - [x] Rebuild `geomind.exe` with Zig `-O3 LTO Vectorized Pass Pipeline`.
  - [x] Verify `geomind.exe --verify`.
  - [x] Verify `geomind.exe --sleep`.
  - [x] Run live streaming training `geomind.exe --train-ce` verifying dynamic domain attractor switching.
