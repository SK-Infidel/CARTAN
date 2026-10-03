# Sprint 506 Task List: Prefill Latency Elimination & Real-Time Fluid Decode Acceleration

- [ ] **Task 1: Pre-Sprint Scrum Alignment**
  - [ ] Answer Rick's direct question and align squad leads on Sprint 506 strategy.
  - [ ] Review blocking issues and discoveries.

- [ ] **Task 2: Gate 1 — Startup Memory Pre-Warming (`geomind_warm_all_layer_buffers`)**
  - [ ] In `test/geomind/chat.cl`, implement `geomind_warm_all_layer_buffers()`.
  - [ ] Call `geomind_warm_all_layer_buffers()` inside `geomind_chat_init_environment()` / `geomind_load_ple_assets_if_needed()`.

- [ ] **Task 3: Gate 2 — Zero-Allocation Pinned Scratch Buffers in Batched Prefill**
  - [ ] In `src/std/transformer.cl`, define persistent static batch scratch buffers (`g_trans_b_norm_h1`, `g_trans_b_q`, `g_trans_b_k`, `g_trans_b_v`, `g_trans_b_attn_out`, `g_trans_b_h1`, `g_trans_b_norm_h2`, `g_trans_b_act`, `g_trans_b_ffn`, `g_trans_b_ple_act`, `g_trans_b_ple_proj`).
  - [ ] Allocate them once in `cartan_init_transformer_scratch_buffers()`.
  - [ ] In `cartan_manifold_layer_forward_batch`, replace per-layer `malloc` and `free` with persistent scratch buffers.

- [ ] **Task 4: Gate 3 — Vectorized & Thresholded Prefill Attention Accumulation**
  - [ ] In `cartan_manifold_layer_forward_batch` Step 4, add `if (p_t > 0.000000001)` check.
  - [ ] Unroll `hd` loop by 4 (0, 1, 2, 3) over contiguous `v_ht` memory.

- [ ] **Task 5: Gate 4 — Thread Pool Spin Yield Optimization**
  - [ ] In `src/std/transformer.cl`, update `cartan_trans_pool_dispatch`, `cartan_trans_pool_dispatch_batch`, `cartan_trans_pool_dispatch_lm_head`, and `cartan_trans_pool_worker_main`.
  - [ ] Increase spin threshold from 200 to 5,000 before yielding.

- [ ] **Task 6: Gate 5 — 4-Way ILP in `@cartan_simd_dot_f32`**
  - [ ] In `src/cartanc/llvm_codegen.car:1178`, update `@cartan_simd_dot_f32` to unroll the vector loop by 4 (`%vacc0`, `%vacc1`, `%vacc2`, `%vacc3`).
  - [ ] Rebuild compiler `cartanc.exe` and verify 3-stage bootstrap convergence.

- [ ] **Task 7: Empirical Verification & Telemetry**
  - [ ] Recompile `bin/geomind.exe` with updated `cartanc.exe`.
  - [ ] Run benchmark with `bin/geomind.exe -prompt "What is the capital of France?" -tokens 20`.
  - [ ] Measure prefill latency and decode tokens/sec.
  - [ ] Run full 88-target regression test suite: `tools/run_affected_tests.ps1 -All`.

- [ ] **Task 8: Retrospective & Documentation**
  - [ ] Save walkthrough to `docs/archive/sprint_506_walkthrough.md`.
  - [ ] Update `CHANGELOG.md` and mark resolved items in `ISSUES.md`.
