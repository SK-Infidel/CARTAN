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
        var cur_chunk = collections_list_get(arena.delta_head_offsets, u);
        while (cur_chunk >= 0.0 && cur_chunk < arena.capacity_bytes) {
            let buf = arena.arena_buffer;
            let cnt = cartan_byte_at(buf, cur_chunk + 63.0);
            var slot = 0.0;
            while (slot < cnt && slot < 4.0) {
                let t_off = cur_chunk + (slot * 4.0);
                let dst_lo = cartan_byte_at(buf, t_off + 0.0);
                let dst_hi = cartan_byte_at(buf, t_off + 1.0);
                let tgt = dst_lo + (dst_hi * 256.0);

                let w_off = cur_chunk + 28.0 + (slot * 4.0);
                let w_byte = cartan_byte_at(buf, w_off);
                let w = w_byte / 100.0;

                let rel = cartan_byte_at(buf, cur_chunk + 56.0 + slot);

                if (w >= thresh && tgt >= 0.0 && tgt < b.num_nodes) {
                    csr_builder_add_edge(b, u, tgt, w, rel, 0.0);
                    retained = retained + 1.0;
                } else {
                    pruned = pruned + 1.0;
                }
                slot = slot + 1.0;
            }

            // Traverse to chained previous chunk
            let p_lo = cartan_byte_at(buf, cur_chunk + 60.0);
            let p_mid = cartan_byte_at(buf, cur_chunk + 61.0);
            let p_hi = cartan_byte_at(buf, cur_chunk + 62.0);
            if (p_lo == 255.0 && p_mid == 255.0 && p_hi == 255.0) {
                cur_chunk = -1.0;
            } else {
                cur_chunk = p_lo + (p_mid * 256.0) + (p_hi * 65536.0);
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



// Extracts in-memory CsrGraph representation from a loaded binary CarGraphFile
fn cargraph_extract_csr(cg: CarGraphFile) -> CsrGraph {
    let num_rules = cg.header.num_rules;
    let b = csr_builder_create(num_rules);
    if (cg.csr_ptrs != 0.0 && cg.csr_edges != 0.0 && cg.header.num_edges > 0.0) {
        var u = 0.0;
        while (u < num_rules) {
            let r_start = cargraph_read_u64(cg.csr_ptrs, u * 8.0);
            let r_end = cargraph_read_u64(cg.csr_ptrs, (u + 1.0) * 8.0);
            var e = r_start;
            while (e < r_end && e < cg.header.num_edges) {
                let e_off = e * 16.0;
                let tgt = cargraph_read_u32(cg.csr_edges, e_off + 0.0);
                let w_u32 = cargraph_read_u32(cg.csr_edges, e_off + 4.0);
                let w = w_u32 / 100.0;
                let rel = cargraph_read_u32(cg.csr_edges, e_off + 8.0);
                let ts = cargraph_read_u32(cg.csr_edges, e_off + 12.0);
                csr_builder_add_edge(b, u, tgt, w, rel, ts);
                e = e + 1.0;
            }
            u = u + 1.0;
        }
    }
    let g = csr_builder_build(b);
    csr_builder_free(b);
    return g;
}

// Serializes in-memory CarGraphBuilder data and compacted CsrGraph into binary file
fn cargraph_serialize_to_file_with_csr(b: CarGraphBuilder, csr: CsrGraph, filepath: string) -> float {
    let num_domains = collections_list_len(b.domain_ids);
    let num_rules = collections_list_len(b.rule_domain_indices);
    let emb_dim = b.embedding_dim;
    var num_edges = 0.0;
    if (csr.edge_targets != 0.0) {
        num_edges = collections_list_len(csr.edge_targets);
    }

    let off_header = 0.0;
    let hdr_size = 128.0;

    let off_domains = cargraph_align_page(hdr_size);
    let domains_size = num_domains * 32.0;

    let off_rules = cargraph_align_page(off_domains + domains_size);
    let rules_size = num_rules * 32.0;

    let off_csr_ptrs = cargraph_align_page(off_rules + rules_size);
    let off_csr_edges = cargraph_align_page(off_csr_ptrs + ((num_rules + 1.0) * 8.0));
    let off_fragments = cargraph_align_page(off_csr_edges + (num_edges * 16.0) + 64.0);

    let off_embeddings = cargraph_align_page(off_fragments + 64.0);
    let vec_bytes = emb_dim * 8.0;
    let embeddings_size = num_rules * vec_bytes;

    let off_string_pool = cargraph_align_page(off_embeddings + embeddings_size);

    var str_pool_len = 0.0;
    var i = 0.0;
    while (i < num_rules) {
        let s = cartan_tree_get(b.rule_strings, i);
        str_pool_len = str_pool_len + cartan_string_length(s) + 1.0;
        i = i + 1.0;
    }
    let total_file_size = off_string_pool + str_pool_len + 64.0;

    let raw = cartan_alloc_binary_buffer(total_file_size);
    if (raw == 0.0) { return 0.0; }

    var m_idx = 0.0;
    while (m_idx < 8.0) {
        cartan_set_byte(raw, m_idx, cargraph_magic_byte(m_idx));
        m_idx = m_idx + 1.0;
    }

    cargraph_write_u32(raw, 8.0, 1.0);
    cargraph_write_u32(raw, 12.0, 0.0);
    cargraph_write_u64(raw, 16.0, total_file_size);
    cargraph_write_u32(raw, 24.0, emb_dim);
    cargraph_write_u32(raw, 28.0, num_domains);
    cargraph_write_u32(raw, 32.0, num_rules);
    cargraph_write_u32(raw, 36.0, b.num_strict);
    cargraph_write_u32(raw, 40.0, num_edges);
    cargraph_write_u32(raw, 44.0, 0.0);
    cargraph_write_u64(raw, 48.0, off_domains);
    cargraph_write_u64(raw, 56.0, off_rules);
    cargraph_write_u64(raw, 64.0, off_csr_ptrs);
    cargraph_write_u64(raw, 72.0, off_csr_edges);
    cargraph_write_u64(raw, 80.0, off_fragments);
    cargraph_write_u64(raw, 88.0, off_embeddings);
    cargraph_write_u64(raw, 96.0, off_string_pool);

    var d_i = 0.0;
    while (d_i < num_domains) {
        let d_id = collections_list_get(b.domain_ids, d_i);
        let d_start = collections_list_get(b.domain_rule_starts, d_i);
        let d_cnt = collections_list_get(b.domain_rule_counts, d_i);
        let d_strict = collections_list_get(b.domain_strict_counts, d_i);
        let d_off = off_domains + (d_i * 32.0);
        cargraph_write_u32(raw, d_off + 0.0, d_id);
        cargraph_write_u32(raw, d_off + 4.0, d_start);
        cargraph_write_u32(raw, d_off + 8.0, d_cnt);
        cargraph_write_u32(raw, d_off + 12.0, d_strict);
        cargraph_write_u32(raw, d_off + 16.0, 0.0);
        cargraph_write_u32(raw, d_off + 20.0, 0.0);
        d_i = d_i + 1.0;
    }

    var cur_str_off = off_string_pool;
    var r_i = 0.0;
    while (r_i < num_rules) {
        let d_idx = collections_list_get(b.rule_domain_indices, r_i);
        let e_type = collections_list_get(b.rule_element_types, r_i);
        let is_str = collections_list_get(b.rule_is_stricts, r_i);
        let s = cartan_tree_get(b.rule_strings, r_i);
        let s_len = cartan_string_length(s);
        let rel_str_off = cur_str_off - off_string_pool;

        let r_off = off_rules + (r_i * 32.0);
        cargraph_write_u32(raw, r_off + 0.0, r_i);
        cargraph_write_u32(raw, r_off + 4.0, d_idx);
        cargraph_write_u32(raw, r_off + 8.0, e_type);
        cargraph_write_u32(raw, r_off + 12.0, is_str);
        cargraph_write_u32(raw, r_off + 16.0, rel_str_off);
        cargraph_write_u32(raw, r_off + 20.0, s_len);
        cargraph_write_u32(raw, r_off + 24.0, r_i);
        cargraph_write_u32(raw, r_off + 28.0, 0.0);

        var c_idx = 0.0;
        while (c_idx < s_len) {
            let ch = c_cartan_string_char_at(s, c_idx);
            cartan_set_byte(raw, cur_str_off + c_idx, ch);
            c_idx = c_idx + 1.0;
        }
        cartan_set_byte(raw, cur_str_off + s_len, 0.0);
        cur_str_off = cur_str_off + s_len + 1.0;

        let emb_vec = cartan_tree_get(b.rule_embeddings, r_i);
        if (emb_vec != 0.0) {
            let vec_dst = cartan_c_ptr_add(raw, off_embeddings + (r_i * vec_bytes));
            cartan_c_memcpy(vec_dst, emb_vec, vec_bytes);
        }
        r_i = r_i + 1.0;
    }

    if (csr.row_ptrs != 0.0) {
        var u = 0.0;
        let n_rptrs = collections_list_len(csr.row_ptrs);
        while (u < n_rptrs) {
            let r_val = collections_list_get(csr.row_ptrs, u);
            cargraph_write_u64(raw, off_csr_ptrs + (u * 8.0), r_val);
            u = u + 1.0;
        }
    }

    if (num_edges > 0.0) {
        var e = 0.0;
        while (e < num_edges) {
            let tgt = collections_list_get(csr.edge_targets, e);
            let w = collections_list_get(csr.edge_weights, e);
            let rel = collections_list_get(csr.edge_rels, e);
            let ts = collections_list_get(csr.edge_timestamps, e);

            let e_off = off_csr_edges + (e * 16.0);
            cargraph_write_u32(raw, e_off + 0.0, tgt);
            cargraph_write_u32(raw, e_off + 4.0, floor(w * 100.0));
            cargraph_write_u32(raw, e_off + 8.0, rel);
            cargraph_write_u32(raw, e_off + 12.0, ts);
            e = e + 1.0;
        }
    }

    let write_ok = cartan_write_binary_file(filepath, raw, total_file_size);
    cartan_free_binary_buffer(raw);
    return write_ok;
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
    let base_csr = cargraph_extract_csr(cg);

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

    // Serialize with consolidated CSR topology to temporary file
    let tmp_path = string_concat(graph_path, ".tmp");
    let serialize_ok = cargraph_serialize_to_file_with_csr(b_new, compacted_csr, tmp_path);

    // Free intermediate objects and builders
    cargraph_builder_free(b_new);
    csr_graph_free(base_csr);
    csr_graph_free(compacted_csr);
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
