# Sprint 421 Task List: In-Memory Hot NSES Graph Consolidation

- [x] **Task 1: Core In-Memory Compactor (`src/std/cargraph_consolidate.cl`)**
  - [x] Add `csr_builder_free(b)` to `cargraph_consolidate_pass` to fix heap leak.
  - [x] Implement `cargraph_sleep_consolidate_memory(base_csr, arena, thresh, metrics_out) -> CsrGraph`.

- [x] **Task 2: In-Memory Axiomatic Consolidation (`src/std/sleep.cl`)**
  - [x] Implement `sleep_run_axiomatic_consolidation_graph(cg: CarGraphFile, basins_file: string, dim: float, lr_sleep: float) -> float`.
  - [x] Implement `sleep_run_consolidation_cycle_memory` and `cartan_sleep_consolidate_cycle_memory`.
  - [x] Refactor `sleep_run_axiomatic_consolidation` to delegate to `sleep_run_axiomatic_consolidation_graph`.

- [x] **Task 3: Streaming Training Loop Integration (`test/geomind/train.cl`)**
  - [x] Maintain persistent `cons_arena` in `geomind_train_streaming_steady_state`.
  - [x] Replace `cargraph_sleep_consolidate_file` with `cargraph_sleep_consolidate_memory`.
  - [x] Replace `sleep_run_axiomatic_consolidation(nses_graph_path, ...)` with `sleep_run_axiomatic_consolidation_graph(nses_pipe.graph_file, ...)`.
  - [x] Add checkpoint-interval disk serialization hook at 100-chunk cadence.

- [x] **Task 4: Empirical Verification & Regression Testing**
  - [x] Build `geomind.exe` with Zig `-O3 LTO Vectorized Pass Pipeline`.
  - [x] Verify `geomind.exe --verify`.
  - [x] Verify `geomind.exe --sleep`.
  - [x] Run NSES regression test `cartanc.exe run test/geomind/nses/test_sprint6_sleep_consolidation.car`.
  - [x] Run NSES regression test `cartanc.exe run test/geomind/nses/test_sprint8_in_memory_consolidation.car`.
  - [x] Run live streaming training `geomind.exe --train-ce` verifying instantaneous sleep cycles.
