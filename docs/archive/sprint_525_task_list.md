# Sprint 525 Task List: Continuous Hopfield Speculative Burst Persistence

- [x] **Task 1: Version 3 Hopfield Basin Format Serialization**
  - Upgrade `resonator_save_basins` in [`src/std/resonator.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/resonator.cl) to Version 3 with token bursts.
  - Upgrade `resonator_load_basins` in [`src/std/resonator.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/resonator.cl) to parse Version 3 token bursts while maintaining backward compatibility with Version 1 and 2.
- [x] **Task 2: KV Cache Clean Range Utility**
  - Implement `cartan_kv_cache_clear_range` in [`src/std/transformer.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/transformer.cl) for zeroing rejected speculative token positions.
- [x] **Task 3: Semantic Corpus Ingestion Token Burst Pairing**
  - Update `geomind_hopfield_ingest_semantic` in [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl) to pair the first 5–8 tokens of each semantic chunk with its mean-pooled attractor basin.
  - Wire speculative verification rollback in `test/geomind/chat.cl:3075-3078` calling `cartan_kv_cache_clear_range`.
  - Remove all uncalibrated vector modifications from `cur_h` during decode, prefill relaxation, and doubt rewind.
  - Implement stream-gated logit modulation at LM head leaving `cur_h` 100% uncorrupted.
- [x] **Task 4: Compilation & Ingestion Execution**
  - Recompile `cartanc.exe` and `geomind.exe`.
  - Re-run `--ingest` on `test/geomind/trainingdata/gutenberg_classics.txt` to produce Version 3 `hopfield_basins.bin` containing both attractor vectors and token bursts.
- [x] **Task 5: Empirical Verification & Regression Testing**
  - Execute live prompt inference testing speculative drafting and clean generation.
  - Run regression test suite (`tools/run_affected_tests.ps1`).
  - Document results in `docs/archive/sprint_525_walkthrough.md`, `CHANGELOG.md`, and resolve `[ISSUE-383]` in `ISSUES.md`.
