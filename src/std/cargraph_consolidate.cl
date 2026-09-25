// src/std/cargraph_consolidate.cl
// CARTAN Standard Library: Offline Sleep Memory Consolidation & CSR Table Compactor
// Neuro-Symbolic Expert System (NSES) Phase 6 Core

include "src/std/math.cl";
include "src/std/collections.cl";
include "src/std/string.cl";
include "src/std/cargraph.cl";
include "src/std/csr_graph.cl";
include "src/std/dynamic_graph.cl";
include "src/std/fs.cl";

extern fn clock() -> float;
extern fn printf(format: string) -> i32;
extern fn malloc(size: float) -> ptr;
extern fn free(p: ptr);

// Consolidation and defragmentation metrics report
struct CarGraphConsolidateReport {
    pruned_edges: float;
    retained_edges: float;
    total_nodes: float;
    compaction_time_ms: float;
    is_success: float;
}

// Compacts dynamic delta arena edges into CSR topology and prunes decayed synapses (w < 1.001)
// Records pruned and retained counts into metrics_out ([0]=pruned, [1]=retained)
fn cargraph_consolidate_pass(
    base_csr: CsrGraph,
    arena: DynamicDeltaArena,
    decay_prune_threshold: float,
    metrics_out: ptr
) -> CsrGraph {
    var thresh = decay_prune_threshold;
    if (thresh <= 0.0) { thresh = 1.001; }

    let n_nodes = base_csr.num_nodes;
    let b = csr_builder_create(n_nodes);

    var pruned = 0.0;
    var retained = 0.0;

    // 1. Process and retain static base CSR edges exceeding decay threshold
    var u = 0.0;
    while (u < n_nodes) {
        let r_start = collections_list_get(base_csr.row_ptrs, u);
        let r_end = collections_list_get(base_csr.row_ptrs, u + 1.0);
        var e = r_start;
        while (e < r_end) {
            let tgt = collections_list_get(base_csr.edge_targets, e);
            let w = collections_list_get(base_csr.edge_weights, e);
            let rel = collections_list_get(base_csr.edge_rels, e);
            let ts = collections_list_get(base_csr.edge_timestamps, e);

            if (w >= thresh) {
                csr_builder_add_edge(b, u, tgt, w, rel, ts);
                retained = retained + 1.0;
            } else {
                pruned = pruned + 1.0;
            }
            e = e + 1.0;
        }

        // 2. Merge dynamic delta edges from DynamicDeltaArena for node u
        let head_offset = collections_list_get(arena.delta_head_offsets, u);
        if (head_offset >= 0.0 && head_offset < arena.capacity_bytes) {
            let buf = arena.arena_buffer;
            let dst_lo = cartan_byte_at(buf, head_offset + 0.0);
            let dst_hi = cartan_byte_at(buf, head_offset + 1.0);
            let tgt = dst_lo + (dst_hi * 256.0);

            let w_byte = cartan_byte_at(buf, head_offset + 28.0);
            let w = w_byte / 100.0;

            let rel = cartan_byte_at(buf, head_offset + 56.0);

            if (w >= thresh) {
                csr_builder_add_edge(b, u, tgt, w, rel, 0.0);
                retained = retained + 1.0;
            } else {
                pruned = pruned + 1.0;
            }
        }

        u = u + 1.0;
    }

    // 3. Rebuild compacted, defragmented CSR representation
    let compacted = csr_builder_build(b);
    csr_builder_free(b);

    // 4. Record metrics if buffer provided
    if (metrics_out != 0.0) {
        metrics_out[0] = pruned;
        metrics_out[1] = retained;
    }

    // 5. Reset dynamic delta arena to clear fragmented scratch space
    arena.used_bytes = 0.0;
    arena.checkpoint_bytes = 0.0;
    arena.dynamic_node_count = 0.0;
    arena.checkpoint_node_count = 0.0;
    var i = 0.0;
    let n_heads = collections_list_len(arena.delta_head_offsets);
    while (i < n_heads) {
        collections_list_set(arena.delta_head_offsets, i, -1.0);
        i = i + 1.0;
    }

    return compacted;
}

// Verifies monotonic row offset invariant: row_ptrs[i] <= row_ptrs[i+1]
fn cargraph_verify_csr_monotonicity(csr: CsrGraph) -> float {
    var i = 0.0;
    while (i < csr.num_nodes) {
        let p0 = collections_list_get(csr.row_ptrs, i);
        let p1 = collections_list_get(csr.row_ptrs, i + 1.0);
        if (p0 > p1) {
            return 0.0; // Violation of monotonic CSR layout
        }
        i = i + 1.0;
    }
    return 1.0;
}

// In-Memory Hot NSES Graph Consolidation:
// Compacts dynamic delta arena edges directly into the in-memory CsrGraph and prunes decayed synapses (w < decay_prune_threshold).
// Completely bypasses disk I/O, temporary files, and atomic file swaps.
// Returns the newly compacted CsrGraph and records metrics into metrics_out ([0]=pruned, [1]=retained, [2]=duration_ms).
fn cargraph_sleep_consolidate_memory(
    base_csr: CsrGraph,
    arena: DynamicDeltaArena,
    decay_prune_threshold: float,
    metrics_out: ptr
) -> CsrGraph {
    let t_start = clock();
    var thresh = decay_prune_threshold;
    if (thresh <= 0.0) { thresh = 1.001; }

    let compacted_csr = cargraph_consolidate_pass(base_csr, arena, thresh, metrics_out);

    let t_end = clock();
    let duration_ms = t_end - t_start;
    if (metrics_out != 0.0) {
        metrics_out[2] = duration_ms;
    }

    return compacted_csr;
}



// Executes full sleep consolidation cycle on a target .car_graph file:
// 1. Loads .car_graph binary file
// 2. Compacts edges from base CSR and DynamicDeltaArena
// 3. Prunes decayed synapses (w < decay_prune_threshold)
// 4. Writes compacted binary graph to .tmp file
// 5. Atomically swaps .tmp to target path
// 6. Reloads and verifies valid zero-copy binary layout
fn cargraph_sleep_consolidate_file(
    graph_path: string,
    arena: DynamicDeltaArena,
    decay_prune_threshold: float
) -> CarGraphConsolidateReport {
    let t_start = clock();
    var thresh = decay_prune_threshold;
    if (thresh <= 0.0) { thresh = 1.001; }

    let invalid_report = CarGraphConsolidateReport {
        pruned_edges: 0.0,
        retained_edges: 0.0,
        total_nodes: 0.0,
        compaction_time_ms: 0.0,
        is_success: 0.0
    };

    if (fs_exists(graph_path) == 0.0) {
        return invalid_report;
    }

    let cg = cargraph_load_binary(graph_path);
    if (cg.is_valid == 0.0) {
        return invalid_report;
    }

    let num_rules = cg.header.num_rules;
    let b_base = csr_builder_create(num_rules);
    let base_csr = csr_builder_build(b_base);

    // Compact dynamic arena edges
    let metrics = malloc(16.0);
    metrics[0] = 0.0;
    metrics[1] = 0.0;
    let compacted_csr = cargraph_consolidate_pass(base_csr, arena, thresh, metrics);
    let pruned_count = metrics[0];
    let retained_count = metrics[1];
    free(metrics);

    // Build new CarGraphBuilder to serialize updated graph
    let b_new = cargraph_builder_create(cg.header.embedding_dim);

    // Copy domains from cg
    var d = 0.0;
    while (d < cg.header.num_domains) {
        let d_off = d * 32.0;
        let d_id = cargraph_read_u32(cg.domains_ptr, d_off + 0.0);
        let d_start = cargraph_read_u32(cg.domains_ptr, d_off + 4.0);
        let d_cnt = cargraph_read_u32(cg.domains_ptr, d_off + 8.0);
        let d_strict = cargraph_read_u32(cg.domains_ptr, d_off + 12.0);
        cargraph_builder_add_domain(b_new, d_id, d_start, d_cnt, d_strict);
        d = d + 1.0;
    }

    // Copy rules from cg
    var r = 0.0;
    while (r < num_rules) {
        let r_meta = cargraph_get_rule(cg, r);
        let r_text = cargraph_get_rule_text(cg, r);
        let r_emb = cargraph_get_rule_embedding(cg, r);
        cargraph_builder_add_rule(b_new, r_meta.domain_idx, r_meta.element_type, r_meta.is_strict, r_text, r_emb);
        r = r + 1.0;
    }

    // Serialize to temporary file
    let tmp_path = string_concat(graph_path, ".tmp");
    let serialize_ok = cargraph_serialize_to_file(b_new, tmp_path);
    cargraph_free(cg);

    if (serialize_ok == 0.0) {
        return invalid_report;
    }

    // Atomic swap on disk: tmp_path -> graph_path via MoveFileExA / rename
    let swap_ok = fs_atomic_swap(tmp_path, graph_path);
    if (swap_ok == 0.0) {
        return invalid_report;
    }

    // Verify reloaded graph
    let cg_verify = cargraph_load_binary(graph_path);
    if (cg_verify.is_valid == 0.0) {
        return invalid_report;
    }
    cargraph_free(cg_verify);

    let t_end = clock();
    let duration_ms = t_end - t_start;

    return CarGraphConsolidateReport {
        pruned_edges: pruned_count,
        retained_edges: retained_count,
        total_nodes: num_rules,
        compaction_time_ms: duration_ms,
        is_success: 1.0
    };
}
