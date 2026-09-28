# Sprint 434 Task List: Neuro-Symbolic Cognitive Memory Architecture

## Pre-Sprint Scrum
- [x] Code Review completed on `src/std/cargraph.cl`, `src/std/prompt_scaffold.cl`, `tools/zig_wrapper.py`, and `src/cartanc/core_runtime.car`.
- [x] Linker configuration tested with `winsqlite3` on Windows (`tools/zig_wrapper.py`).
- [x] Implementation Plan and Task List created and archived.

## Implementation Tasks
- [x] **Task 1: Tier 2 Embedded Database Engine (`src/std/sqlite_vec.cl`)**:
  - [x] Implement C-FFI bindings to `winsqlite3` (`sqlite3_open`, `sqlite3_close`, `sqlite3_exec`, `sqlite3_prepare_v2`, `sqlite3_step`, `sqlite3_column_*`) in `src/std/cartan_sqlite.c`.
  - [x] Implement 6-table relational schema (`domains`, `rule_elements`, `dependencies`, `randomicity_fragments`, `episodes`, `entity_states`).
  - [x] Implement helper APIs for upserting domains, rules, dependencies, fragments, episodes, and entity states.
  - [x] Implement Two-Way Sync Phase A (`sqlite_vec_materialize_to_cargraph`) to serialize DB records into `.car_graph` v2.
- [x] **Task 2: Tier 1 Native `.car_graph` v2 Binary Buffer (`src/std/cargraph.cl`)**:
  - [x] Add `num_entities` and `offset_entities` to `CarGraphHeader`.
  - [x] Define `EntityStateEntry` struct (32 bytes).
  - [x] Enforce strict 64-byte cacheline alignment on all section offsets (`offset_domains`, `offset_rules`, `offset_csr_ptrs`, `offset_csr_edges`, `offset_fragments`, `offset_entities`, `offset_embeddings`, `offset_string_pool`).
  - [x] Implement `cargraph_builder_add_entity(...)` and SoA entity lists in `CarGraphBuilder`.
  - [x] Update `cargraph_serialize_to_file` to write Header v2 and entity records.
  - [x] Update `cargraph_load_binary` to parse both v1 and v2 headers backwards-compatibly.
  - [x] Implement `cargraph_get_entity`, `cargraph_get_entity_state_string`, and entity accessors.
- [x] **Task 3: 4-Block Scaffold Active World-State Injection (`src/std/prompt_scaffold.cl`)**:
  - [x] Implement `prompt_assemble_scaffold_v2` with `entity_states_tree` support.
  - [x] Format active entity states as `[WORLD-STATE: User.attribute='value']`.
  - [x] Maintain `prompt_assemble_scaffold` backwards compatibility.
- [x] **Task 4: Empirical Regression Suite & Binary Verification**:
  - [x] Author `test/geomind/nses/test_sprint21_cognitive_memory_v2.car` testing Gates TS-21.1 through TS-21.4.
  - [x] Compile and run with `cartanc.exe`, verifying 100% pass (4.0 / 4.0 gates passed).
  - [x] Rebuild native `bin/geomind.exe` with Zig `-O3 LTO Vectorized Pass Pipeline`, verify `--verify`, and copy to all 4 binary paths.
- [x] **Task 5: Documentation & Closeout**:
  - [x] Update `ISSUES.md` with `[ISSUE-182] [FIXED]`.
  - [x] Update `CHANGELOG.md` to `[8.392.0]`.
  - [x] Create and archive `sprint_434_walkthrough.md`.
