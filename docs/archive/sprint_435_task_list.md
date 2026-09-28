# Sprint 435 Task List: Phase B Metacognitive Sleep Consolidation & Interactive Cognitive Chat Integration

## Status: COMPLETED
**Lead Architect**: Supervisor Agent
**Engineer**: cartan-compiler-engineer
**QA / Verification**: cartan-qa-tester

---

### Task 1: SQLite C-FFI Consolidation Functions (`src/std/cartan_sqlite.c` & `src/std/sqlite_vec.cl`)
- [x] Implement `cartan_sqlite_consolidate_unprocessed_episodes()` in `cartan_sqlite.c`
- [x] Implement `cartan_sqlite_supersede_rule()` in `cartan_sqlite.c`
- [x] Implement `cartan_sqlite_apply_ebbinghaus_decay()` in `cartan_sqlite.c`
- [x] Implement `cartan_sqlite_flush_hebbian_weight()` in `cartan_sqlite.c`
- [x] Expose bindings in `src/std/sqlite_vec.cl`:
  - `sqlite_vec_consolidate_episodes(db, domain_id)`
  - `sqlite_vec_supersede_rule(db, old_elem_id, new_elem_id)`
  - `sqlite_vec_apply_ebbinghaus_decay(db, domain_id, min_conf)`
  - `sqlite_vec_flush_hebbian_weight(db, src_id, tgt_id, weight)`
- [x] Add prepared statement helper for all entity states in a domain

### Task 2: `.car_graph` v2 Consolidation & Entity Preservation (`src/std/cargraph_consolidate.cl`)
- [x] Update `cargraph_sleep_consolidate_file()` to copy existing entity states into `b_new`
- [x] Upgrade `cargraph_serialize_to_file_with_csr()` to write `.car_graph` v2 header (version 2.0, 128-byte cache-aligned header, entity section, 64-byte aligned offsets)
- [x] Verify zero-loss entity round-trip through sleep consolidation pass

### Task 3: Interactive Cognitive Chat Integration (`test/geomind/chat.cl` & `test/geomind/main.car`)
- [x] Add database initialization and connection handle to chat subsystem (`geomind_chat_start()`)
- [x] Wire user & assistant turn logging to `episodes` table
- [x] Inject active world-state from DB / `.car_graph` into prompt scaffold using `prompt_assemble_scaffold_v2()`
- [x] Add REPL slash commands:
  - `/set <entity>.<attr>=<val>` (upsert to `entity_states`)
  - `/state` (print all active world states)
  - `/sleep` (trigger online sleep consolidation and re-materialization)
  - `/remember <fact>` (insert into Hopfield, `episodes`, and `rule_elements`)
- [x] Update `--sleep` in `main.car` to run Phase B Two-Tier synchronization if DB exists

### Task 4: Empirical Verification Suite (`test/geomind/nses/test_sprint22_sleep_consolidation_chat.car`)
- [x] Gate TS-22.1: Metacognitive Episode Consolidation & Fact Extraction
- [x] Gate TS-22.2: Belief Revision & Contradiction Supersession
- [x] Gate TS-22.3: Ebbinghaus Synaptic Decay & Hebbian Flush
- [x] Gate TS-22.4: End-to-End Chat Dialogue & Entity Memory Continuity
- [x] Compile and verify 100% empirical pass with `cartanc.exe`

### Task 5: Production Build & Documentation Closeout
- [x] Rebuild `geomind.exe` with Zig `-O3 LTO Vectorized Pass Pipeline`
- [x] Verify `geomind.exe --verify`
- [x] Sync `geomind.exe` to `bin/`, `build/`, root, and `test/geomind/`
- [x] Update `ISSUES.md` (`[ISSUE-183] [FIXED]`)
- [x] Update `CHANGELOG.md` to `[8.393.0]`
- [x] Save walkthrough to `docs/archive/sprint_435_walkthrough.md`
