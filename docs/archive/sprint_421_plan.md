# Sprint 421 Implementation Plan: In-Memory Hot NSES Graph Consolidation

## 1. Context & Objectives
- **Context**: During streaming training in `test/geomind/train.cl`, Metacognitive Sleep consolidation triggers periodically (every 20 chunks) and reactively on loss spikes. Currently, every sleep micro-nap executes `cargraph_sleep_consolidate_file` (reading 544 KB from disk, building SoA tables, writing a `.tmp` file, doing NTFS `MoveFileExA`, and reloading) and `sleep_run_axiomatic_consolidation` (re-reading 544 KB from disk a third time).
- **Goal**:
  1. Eliminate all disk file re-reads and re-writes during streaming Metacognitive Sleep turns.
  2. Implement `cargraph_sleep_consolidate_in_memory` and `sleep_run_axiomatic_consolidation_graph` operating directly on in-memory `NSES_Pipeline`, `CsrGraph`, and `CarGraphFile`.
  3. Fix the `CsrBuilder` memory leak in `cargraph_consolidate_pass`.
  4. Defer NSES graph disk synchronization to 100-chunk checkpoint intervals or clean shutdown.
  5. Empirically verify sub-millisecond in-memory compaction and 100% test pass.

---

## 2. Architecture & Design

### A. In-Memory Consolidation Core (`src/std/cargraph_consolidate.cl`)
1. Fix builder leak in `cargraph_consolidate_pass`: add `csr_builder_free(b)`.
2. Add `cargraph_sleep_consolidate_in_memory(base_csr, arena, thresh, metrics_out) -> CsrGraph`:
   - Executes `cargraph_consolidate_pass` in RAM without touching disk.
   - Returns compacted `CsrGraph` and records metrics (`pruned`, `retained`, `duration_ms`).
3. Add `nses_pipeline_consolidate_memory(pipe: NSES_Pipeline, arena: DynamicDeltaArena, thresh: float) -> CarGraphConsolidateReport`:
   - Compacts `pipe.csr` in place, replaces `pipe.csr = compacted_csr`, and frees the old CSR.

### B. In-Memory Axiomatic Consolidation (`src/std/sleep.cl`)
1. Implement `sleep_run_axiomatic_consolidation_graph(cg: CarGraphFile, basins_file: string, dim: float, lr_sleep: float) -> float`:
   - Operates directly on the in-memory `cg.embeddings_ptr` via `cargraph_get_rule_embedding`.
   - Projects 42 rule embeddings, performs novelty checking, and imprints slow weights via Hopfield relaxation without disk reads.
2. Refactor `sleep_run_axiomatic_consolidation(nses_graph_path, ...)` to load `cg` only if called from path, delegating to `sleep_run_axiomatic_consolidation_graph`.

### C. Streaming Training Integration (`test/geomind/train.cl`)
1. Maintain persistent `cons_arena = dynamic_arena_create(65536.0, 64.0)` across the entire training run.
2. In sleep trigger:
   - Execute `nses_pipeline_consolidate_memory(nses_pipe, cons_arena, 1.001)`.
   - Execute `sleep_run_axiomatic_consolidation_graph(nses_pipe.graph_file, basins_path, 2560.0, 0.0002)`.
   - Zero disk reads or writes during normal micro-naps.
3. At 100-chunk checkpoint intervals (`math_mod_val(total_chunks_trained, 100.0) == 0.0`):
   - Flush consolidated state if needed.

---

## 3. Verification Plan
- Build `geomind.exe` with Zig `-O3 LTO Vectorized Pass Pipeline`.
- Run regression tests: `test_sprint6_sleep_consolidation.car`, `test_sprint7_loss_shaping.car`.
- Execute `geomind.exe --sleep` and `geomind.exe --train-ce` verifying instantaneous sleep cycles and zero disk pause.
