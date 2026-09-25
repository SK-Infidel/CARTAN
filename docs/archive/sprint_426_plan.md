# Sprint 426 Implementation Plan: Core Memory Reclamation & Graph Topological Integrity

## Mission
Eliminate 7 critical memory leak and topological integrity defects identified by Rick across Hopfield relaxation, dynamic graph delta chaining, offline sleep consolidation, multimodal buffer management, and chat RLHF invariant protection.

---

## Targeted Issues
1. **[ISSUE-168] Root Invariant Erosion in Chat RLHF (`test/geomind/chat.cl`)**:
   - Negative reward decays edges 0..3, degrading Domain 0 axiomatic root conservation laws.
   - Fix: Whitelist Domain 0 edges (`e_idx >= 4.0`), decaying only conversational/dynamic domain edges.
2. **[ISSUE-169] Per-Turn Vector Leak in Interactive Chat (`test/geomind/chat.cl`)**:
   - `prompt_tokens`, `history`, `mom`, `cur_h`, `h_state`, `reply_toks`, `corr_toks` are never freed.
   - Fix: Free intermediate vectors per step and reclaim all turn allocations at turn exit.
3. **[ISSUE-170] Salient Attractor Bank Leak in Hopfield Relaxation (`src/std/resonator.cl`)**:
   - `resonator_salient_hopfield_relax` allocates `chosen_bank = cartan_tree_create()` and leaks it on return.
   - Fix: Implement `cartan_tree_free` / `resonator_free_bank_tree` and free `chosen_bank` before return.
4. **[ISSUE-171] Autoregressive Per-Step Vector Leak in `resonator_compute_energy` (`src/std/resonator.cl`)**:
   - `resonator_compute_energy` allocates `dots = cartan_vec_create()` per evaluation and leaks it.
   - Fix: Deallocate `dots` with `cartan_vec_free(dots)` before return.
5. **[ISSUE-172] Multi-Edge Dynamic Delta Dropping & Orphaning (`src/std/dynamic_graph.cl`, `src/std/cargraph_consolidate.cl`)**:
   - `dynamic_arena_append_edge` overwrites `delta_head_offsets[src_node]` on each append, orphaning older chunks and dropping edges. `cargraph_consolidate_pass` only reads slot 0.
   - Fix: Pack up to 4 edges per 64-byte chunk; chain overflow chunks using byte offsets 60..62; update `cargraph_consolidate_pass` to traverse chunk chains and read all slots.
6. **[ISSUE-173] `cargraph_sleep_consolidate_file` Drops Base Topology & Leaks Builders (`src/std/cargraph_consolidate.cl`)**:
   - `b_base` created with no edges, dropping base topology; compacted edges never serialized into `b_new`; `b_base`, `base_csr`, `compacted_csr`, `b_new` leaked.
   - Fix: Populate base edges from `cg` into `base_csr`; write CSR edges into disk serialization; free all intermediate builders and graphs via `csr_builder_free`, `csr_graph_free`, `cargraph_builder_free`.
7. **[ISSUE-174] Multimodal Grounding Buffer Leaks in Chat Generation (`test/geomind/chat.cl`)**:
   - Vision and audio temporary buffers (`img`, `patch`, `buf`, `dft_spec`, `vis_stream`, `aud_stream`) leaked every turn.
   - Fix: Deallocate raw image/patch and audio buffers immediately after projection; free projected streams after multimodal grounding.

---

## Architectural Verification Strategy
- Create dedicated regression suite `test/geomind/nses/test_sprint13_memory_leaks_and_graph_integrity.car`.
- Verify 100% gate pass with `cartanc.exe`.
- Rebuild `bin/geomind.exe` and test `--verify` and `--sleep`.
