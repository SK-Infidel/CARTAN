# Sprint 426 Task List: Memory Reclamation & Graph Integrity

## Phase 1: Diagnostics & Setup
- [x] Pre-sprint deep code review across all 7 defect sites.
- [x] Document issues [ISSUE-168] through [ISSUE-174] in `ISSUES.md`.
- [x] Save sprint implementation plan and task list to `docs/archive/`.

## Phase 2: Resonator & Hopfield Leak Elimination
- [x] Implement `cartan_tree_free` / `collections_free_tree` in `src/std/collections.cl` and deallocate `chosen_bank` in `resonator_salient_hopfield_relax` (`src/std/resonator.cl`).
- [x] Deallocate `dots` vector with `cartan_vec_free(dots)` in `resonator_compute_energy` (`src/std/resonator.cl`).

## Phase 3: Dynamic Delta Chaining & Consolidation Overhaul
- [x] Overhaul `dynamic_arena_append_edge` in `src/std/dynamic_graph.cl` to pack up to 4 edges per chunk and chain overflow chunks via bytes 60..62.
- [x] Update `cargraph_consolidate_pass` in `src/std/cargraph_consolidate.cl` to iterate all slots 0..3 and traverse linked chunk chains.

## Phase 4: Sleep Consolidation Topology & Memory Reclamation
- [x] Implement `cargraph_extract_csr(cg)` in `src/std/cargraph_consolidate.cl` to populate base topology from binary `.car_graph`.
- [x] Write consolidated CSR edges to disk in `cargraph_serialize_to_file_with_csr` / `cargraph_sleep_consolidate_file`.
- [x] Free all intermediate structures (`base_csr`, `compacted_csr`, `b_new`, `cg`) in `cargraph_sleep_consolidate_file`.

## Phase 5: Multimodal & Turn Memory Reclamation in Chat Engine
- [x] Deallocate raw image/patch and audio buffers in `geomind_chat_process_image_*` and `geomind_chat_process_audio_*` (`test/geomind/chat.cl`).
- [x] Deallocate `vis_stream` and `aud_stream` after multimodal grounding in `geomind_chat_step` (`test/geomind/chat.cl`).
- [x] Protect Domain 0 edges in `geomind_chat_apply_human_feedback` (`e_idx >= 4.0`, `min_w = 0.10`).
- [x] Free all per-step and per-turn vectors (`mom`, `prev_h`, `history`, `prompt_tokens`, `hidden_state`, `cur_h`) at turn exit.

## Phase 6: Empirical QA Verification & Regression Gate
- [x] Author comprehensive regression test suite `test/geomind/nses/test_sprint13_memory_leaks_and_graph_integrity.car`.
- [x] Compile and run test suite with `cartanc.exe` (Gates TS-13.1 through TS-13.4 passing 100%).
- [x] Rebuild `geomind.exe` with Zig `-O3 LTO Vectorized Pass Pipeline`.
- [x] Verify `geomind.exe --verify` clean execution.
- [x] Update `CHANGELOG.md` to `[8.384.0]` and mark issues in `ISSUES.md` as `[FIXED]`.
- [x] Archive `sprint_426_walkthrough.md`.
