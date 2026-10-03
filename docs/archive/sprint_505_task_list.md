# Sprint 505 Task List: Real-Time Multithreaded Decode & Interactive Acceleration

- [x] **Gate 0: Squad Pre-Sprint Alignment & Code Review Scrum**
  - [x] Draft and archive Startup Code Review (`docs/archive/startup_code_review_sprint505_realtime_decode_multithreading.md`).
  - [x] Record [ISSUE-345] and [ISSUE-346] in `ISSUES.md`.
  - [x] Convene squad leads (`cartan_runtime_engineer`, `cartan_architect`, `cartan_qa_tester`) for Pre-Sprint Scrum.

- [x] **Gate 1: Invert GQA Attention Value Accumulation Loop**
  - [x] Refactor `cartan_manifold_layer_forward_native` in `src/std/transformer.cl` (lines 1400–1416).
  - [x] Make sequence `t` outer, dimension `hd` inner over contiguous floats.
  - [x] Benchmark per-layer decode time reduction via `scratch/bench_single_decode_step.car`.

- [x] **Gate 2: Multithreaded Parallel GEMV Engine**
  - [x] Implement worker task structure and multithreaded GEMV row partitioning.
  - [x] Deploy parallel worker threads for Gate/Up and Down GEMV passes.
  - [x] Benchmark thread scalability on 24-core Intel i9-13950HX.

- [x] **Gate 3: Empirical Verification & Interactive Responsiveness**
  - [x] Rebuild `bin/geomind.exe` with multithreaded decode engine.
  - [x] Test interactive generation under `.\bin\geomind.exe -prompt "What is 2+2?" -tokens 20`.
  - [x] Run full 88-target compiler regression suite (`tools/run_affected_tests.ps1 -All`).

- [x] **Gate 4: Sprint Retrospective & Artifacts**
  - [x] Document final performance numbers and speedups.
  - [x] Update `CHANGELOG.md` and mark issues resolved in `ISSUES.md`.
  - [x] Archive walkthrough in `docs/archive/sprint_505_walkthrough.md`.
