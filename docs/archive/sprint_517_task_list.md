# Sprint 517 Task List: High-Throughput Batched Sequence Prefill & WebGPU Forward Acceleration

- [ ] **Task 1: Log Technical Debt Issues**
  - Add `[ISSUE-371]` (Un-vectorized token-by-token fallback loop in INT8 batched sequence prefill) to `ISSUES.md`.
  - Add `[ISSUE-372]` (Synchronous map-async staging barrier in WebGPU GeGLU forward pass) to `ISSUES.md`.

- [ ] **Task 2: Implement Row-Outer INT8 Thread Pool Opcodes in `src/std/transformer.cl`**
  - Implement Op 9.0: Batched INT8 Single GEMV (Q, O, Down, PLE Gate, PLE Proj) across $N$ tokens in `cartan_trans_pool_worker_main`.
  - Implement Op 10.0: Batched INT8 Dual GEMV (K and V projections) across $N$ tokens in `cartan_trans_pool_worker_main`.
  - Implement Op 11.0: Batched INT8 GeGLU (Gate and Up projections fused with GELU) across $N$ tokens in `cartan_trans_pool_worker_main`.
  - Implement `cartan_trans_pool_dispatch_batch_int8()` coordinating 8 worker threads and executing thread 0.

- [ ] **Task 3: Refactor `cartan_manifold_layer_forward_batch` for INT8 in `src/std/transformer.cl`**
  - Compute INT8 weight and scale buffer pointers when `is_int8 == 1.0`.
  - Replace lines 2868–2878 fallback loop with unified row-outer batched INT8 pipeline.
  - Implement batched Q/K/V dispatch, per-head Q-Norm/RoPE, causal attention, batched $W_o$, batched GeGLU/Down, and batched PLE.

- [ ] **Task 4: Pre-Sprint Scrum with Subagent Squads**
  - Dispatch pre-sprint scrum messages to `cartan_architect`, `cartan_runtime_engineer`, `cartan_qa_tester`, and `cartan_compiler_engineer`.

- [ ] **Task 5: Empirical QA & Benchmark Verification**
  - Run regression test suite via `tools/run_affected_tests.ps1 -Auto`.
  - Build `test/geomind/main.car` into `geomind.exe` with `cartanc.exe`.
  - Benchmark prefill latency on prompt test and verify drop from 49.3s to < 500 ms.

- [ ] **Task 6: Sprint Review, Roadmap, and Changelog**
  - Update `ISSUES.md` with resolved status.
  - Update `CHANGELOG.md` with concise entry.
  - Update `docs/ROADMAP.md` Phase 24.
  - Save `docs/archive/sprint_517_walkthrough.md`.
