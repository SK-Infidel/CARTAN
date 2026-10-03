# Sprint 507 Task List: Real-Time Fluid Streaming & AVX2 Acceleration

- [x] **Phase 1: Pre-Sprint Alignment & Squad Sign-Off**
  - [x] Convene Pre-Sprint Scrum with Squad Leads (`cartan_runtime_engineer`, `cartan_compiler_engineer`, `cartan_architect`, `cartan_qa_tester`).
  - [x] Gather architectural and hardware evaluations for Gates 1–4.

- [x] **Phase 2: Gate 1 — Vectorized RMSNorm Acceleration**
  - [x] In `src/std/transformer.cl`, replace scalar `sum_sq` loops with `cartan_simd_dot_f32` across `cartan_manifold_layer_forward_native` (Pre-Attn, Q-Norm, K-Norm, V-Norm, Post-Attn, Pre-FFN, Post-FFN, PLE).
  - [x] In `cartan_manifold_layer_forward_batch`, replace scalar `sum_sq` loops with `cartan_simd_dot_f32`.

- [x] **Phase 3: Gate 2 — 4-Way Row Unrolling in Batched Thread Pool Ops**
  - [x] In `src/std/transformer.cl` (`cartan_trans_pool_worker_main`), unroll `op == 3.0`, `op == 4.0`, and `op == 5.0` by 4 rows.
  - [x] In `cartan_trans_pool_dispatch_batch`, unroll thread 0 row loops by 4 rows.

- [x] **Phase 4: Gate 3 — Fluid Sub-Token Character-Stream Rendering**
  - [x] In `test/geomind/chat.cl`, implement `geomind_print_token_fluid(tok_id)`.
  - [x] Render subword string characters with immediate `cartan_flush(0.0)`.

- [x] **Phase 5: Gate 4 — Compilation & Empirical Verification**
  - [x] Rebuild `bin/geomind.exe` with `cartanc.exe`.
  - [x] Execute live benchmark: `.\bin\geomind.exe -prompt "What is the capital of France?" -tokens 20 -ephemeral`.
  - [x] Measure prefill latency, decode step latency, and character streaming fluidity.
  - [x] Run full 88-target compiler regression suite (`tools/run_affected_tests.ps1 -All`).

- [x] **Phase 6: Sprint Review, CHANGELOG & Retrospective**
  - [x] Create `docs/archive/sprint_507_walkthrough.md`.
  - [x] Update `CHANGELOG.md` and `ISSUES.md`.
