// src/std/csr_graph.cl
// CARTAN Standard Library: Cycle-Safe Compressed Sparse Row (CSR) Graph Engine & Pinned Scratchpad
// Neuro-Symbolic Expert System (NSES) Phase 3 Core

include "src/std/math.cl";
include "src/std/collections.cl";
include "src/std/cargraph.cl";
include "src/std/plasticity.cl";

// Edge Relation Types
// 1.0 = REL_REQUIRES    (Dependency implication)
// 2.0 = REL_CONTRADICTS (Mutual exclusion / contradiction)
// 3.0 = REL_ASSOCIATES  (Associative semantic link)
// 4.0 = REL_EQUIVALENT  (Bidirectional equivalence)

// Compressed Sparse Row (CSR) Graph Representation
struct CsrGraph {
    num_nodes: float;
    num_edges: float;
    row_ptrs: ptr;        // collections_list of size num_nodes + 1
    edge_targets: ptr;    // collections_list of target node indices
    edge_weights: ptr;    // collections_list of synaptic weights
    edge_rels: ptr;       // collections_list of relation types
    edge_timestamps: ptr; // collections_list of last update timestamps
}

// In-Memory CSR Graph Builder for Constructing CSR Topologies
struct CsrBuilder {
    num_nodes: float;
    src_nodes: ptr;
    dst_nodes: ptr;
    weights: ptr;
    rels: ptr;
    timestamps: ptr;
}

// Pinned Zero-Allocation Scratchpad for Fast Traversal
struct NSES_Scratchpad {
    current_epoch: float;      // Monotonic epoch counter (eliminates memset)
    frontier_head: float;      // Queue head index
    frontier_tail: float;      // Queue tail index
    max_frontier: float;       // Frontier buffer capacity
    f_node_id: ptr;            // Dequeued / enqueued node ID
    f_parent_id: ptr;          // Parent node ID
    f_activation: ptr;         // Propagated activation value
    f_depth: ptr;              // Traversal depth (0, 1, 2)
    f_rel_type: ptr;           // Edge relation type
    f_path0: ptr;              // Static path history depth 0
    f_path1: ptr;              // Static path history depth 1
    f_path2: ptr;              // Static path history depth 2
    result_count: float;       // Total unique traversed nodes
    result_node_ids: ptr;      // Output list of unique node IDs
    result_activations: ptr;   // Output list of final activations
    max_nodes: float;          // Maximum node capacity
    v_epoch: ptr;              // query_epoch per node (DISTINCT ON selector)
    v_max_act: ptr;            // Maximum activation seen for node in current epoch
    v_parent_id: ptr;          // Best parent node ID
    v_rel_type: ptr;           // Inbound relation type
    v_depth: ptr;              // Traversal depth
}

// Create a CsrBuilder for N nodes
fn csr_builder_create(num_nodes: float) -> CsrBuilder {
    return CsrBuilder {
        num_nodes: num_nodes,
        src_nodes: collections_create_list(),
        dst_nodes: collections_create_list(),
        weights: collections_create_list(),
        rels: collections_create_list(),
        timestamps: collections_create_list()
    };
}

// Add directed edge to CsrBuilder
fn csr_builder_add_edge(b: CsrBuilder, src: float, dst: float, weight: float, rel: float, ts: float) {
    if (src >= 0.0 && src < b.num_nodes && dst >= 0.0 && dst < b.num_nodes) {
        collections_list_push(b.src_nodes, src);
        collections_list_push(b.dst_nodes, dst);
        collections_list_push(b.weights, weight);
        collections_list_push(b.rels, rel);
        collections_list_push(b.timestamps, ts);
    }
}

// Assemble CsrBuilder data into compact Compressed Sparse Row (CSR) format
fn csr_builder_build(b: CsrBuilder) -> CsrGraph {
    let n_nodes = b.num_nodes;
    let n_edges = collections_list_len(b.src_nodes);

    // 1. Compute node degrees
    let degrees = collections_create_list();
    var i = 0.0;
    while (i < n_nodes) {
        collections_list_push(degrees, 0.0);
        i = i + 1.0;
    }

    var e = 0.0;
    while (e < n_edges) {
        let u = collections_list_get(b.src_nodes, e);
        let cur_deg = collections_list_get(degrees, u);
        collections_list_set(degrees, u, cur_deg + 1.0);
        e = e + 1.0;
    }

    // 2. Compute CSR row pointers (prefix sums)
    let r_ptrs = collections_create_list();
    var cur_offset = 0.0;
    i = 0.0;
    while (i < n_nodes) {
        collections_list_push(r_ptrs, cur_offset);
        let deg = collections_list_get(degrees, i);
        cur_offset = cur_offset + deg;
        i = i + 1.0;
    }
    collections_list_push(r_ptrs, cur_offset); // Final boundary row_ptrs[N]

    // 3. Pre-allocate CSR edge arrays
    let e_targets = collections_create_list();
    let e_weights = collections_create_list();
    let e_rels = collections_create_list();
    let e_timestamps = collections_create_list();

    e = 0.0;
    while (e < n_edges) {
        collections_list_push(e_targets, 0.0);
        collections_list_push(e_weights, 0.0);
        collections_list_push(e_rels, 0.0);
        collections_list_push(e_timestamps, 0.0);
        e = e + 1.0;
    }

    // Offset counter for each row
    let cur_row_pos = collections_create_list();
    i = 0.0;
    while (i < n_nodes) {
        let start_pos = collections_list_get(r_ptrs, i);
        collections_list_push(cur_row_pos, start_pos);
        i = i + 1.0;
    }

    // 4. Fill CSR edge records
    e = 0.0;
    while (e < n_edges) {
        let u = collections_list_get(b.src_nodes, e);
        let v = collections_list_get(b.dst_nodes, e);
        let w = collections_list_get(b.weights, e);
        let r = collections_list_get(b.rels, e);
        let ts = collections_list_get(b.timestamps, e);

        let write_idx = collections_list_get(cur_row_pos, u);
        collections_list_set(e_targets, write_idx, v);
        collections_list_set(e_weights, write_idx, w);
        collections_list_set(e_rels, write_idx, r);
        collections_list_set(e_timestamps, write_idx, ts);

        collections_list_set(cur_row_pos, u, write_idx + 1.0);
        e = e + 1.0;
    }

    collections_free_list(degrees);
    collections_free_list(cur_row_pos);

    return CsrGraph {
        num_nodes: n_nodes,
        num_edges: n_edges,
        row_ptrs: r_ptrs,
        edge_targets: e_targets,
        edge_weights: e_weights,
        edge_rels: e_rels,
        edge_timestamps: e_timestamps
    };
}

// Free CsrBuilder resources
fn csr_builder_free(b: CsrBuilder) {
    if (b.src_nodes != 0.0) { collections_free_list(b.src_nodes); }
    if (b.dst_nodes != 0.0) { collections_free_list(b.dst_nodes); }
    if (b.weights != 0.0) { collections_free_list(b.weights); }
    if (b.rels != 0.0) { collections_free_list(b.rels); }
    if (b.timestamps != 0.0) { collections_free_list(b.timestamps); }
}

// Free CsrGraph resources
fn csr_graph_free(g: CsrGraph) {
    if (g.row_ptrs != 0.0) { collections_free_list(g.row_ptrs); }
    if (g.edge_targets != 0.0) { collections_free_list(g.edge_targets); }
    if (g.edge_weights != 0.0) { collections_free_list(g.edge_weights); }
    if (g.edge_rels != 0.0) { collections_free_list(g.edge_rels); }
    if (g.edge_timestamps != 0.0) { collections_free_list(g.edge_timestamps); }
}

// Create a Pinned Zero-Allocation Scratchpad
fn nses_scratchpad_create(max_nodes: float, max_frontier: float) -> NSES_Scratchpad {
    let f_node = collections_create_list();
    let f_parent = collections_create_list();
    let f_act = collections_create_list();
    let f_depth = collections_create_list();
    let f_rel = collections_create_list();
    let f_p0 = collections_create_list();
    let f_p1 = collections_create_list();
    let f_p2 = collections_create_list();
    let res_ids = collections_create_list();
    let res_acts = collections_create_list();

    var i = 0.0;
    while (i < max_frontier) {
        collections_list_push(f_node, 0.0);
        collections_list_push(f_parent, 0.0);
        collections_list_push(f_act, 0.0);
        collections_list_push(f_depth, 0.0);
        collections_list_push(f_rel, 0.0);
        collections_list_push(f_p0, -1.0);
        collections_list_push(f_p1, -1.0);
        collections_list_push(f_p2, -1.0);
        collections_list_push(res_ids, 0.0);
        collections_list_push(res_acts, 0.0);
        i = i + 1.0;
    }

    let v_ep = collections_create_list();
    let v_m_act = collections_create_list();
    let v_par = collections_create_list();
    let v_r = collections_create_list();
    let v_dep = collections_create_list();

    i = 0.0;
    while (i < max_nodes) {
        collections_list_push(v_ep, 0.0);
        collections_list_push(v_m_act, 0.0);
        collections_list_push(v_par, -1.0);
        collections_list_push(v_r, 0.0);
        collections_list_push(v_dep, 0.0);
        i = i + 1.0;
    }

    return NSES_Scratchpad {
        current_epoch: 1.0,
        frontier_head: 0.0,
        frontier_tail: 0.0,
        max_frontier: max_frontier,
        f_node_id: f_node,
        f_parent_id: f_parent,
        f_activation: f_act,
        f_depth: f_depth,
        f_rel_type: f_rel,
        f_path0: f_p0,
        f_path1: f_p1,
        f_path2: f_p2,
        result_count: 0.0,
        result_node_ids: res_ids,
        result_activations: res_acts,
        max_nodes: max_nodes,
        v_epoch: v_ep,
        v_max_act: v_m_act,
        v_parent_id: v_par,
        v_rel_type: v_r,
        v_depth: v_dep
    };
}

// Reset Scratchpad for next query in O(1) time without heap allocations or memset
fn nses_scratchpad_reset_for_query(pad: NSES_Scratchpad) {
    pad.current_epoch = pad.current_epoch + 1.0;
    pad.frontier_head = 0.0;
    pad.frontier_tail = 0.0;
    pad.result_count = 0.0;
}

// Check if candidate node exists in the static integer path history
fn csr_is_in_path(node_id: float, p0: float, p1: float, p2: float) -> float {
    if (node_id == p0 || node_id == p1 || node_id == p2) {
        return 1.0;
    }
    return 0.0;
}

// High-Performance Zero-Allocation Cycle-Safe BFS Traversal Engine
// Enforces:
// 1. Zero runtime heap allocations (pinned scratchpad reuse)
// 2. Static integer path cycle rejection (self-loops, mutual cycles, multi-node rings)
// 3. Contradiction masking (REL_CONTRADICTS dropped immediately)
// 4. Activation attenuation thresholding (act * w * 0.85 >= tau)
// 5. Epoch-stamped deduplication (DISTINCT ON (node_id))
fn csr_traverse_bfs(
    graph: CsrGraph,
    pad: NSES_Scratchpad,
    seed_node_ids: ptr,
    seed_activations: ptr,
    max_depth: float,
    tau_threshold: float,
    decay_factor: float,
    current_time: float
) -> float {
    // Step 1: O(1) Epoch Reset
    nses_scratchpad_reset_for_query(pad);
    let epoch = pad.current_epoch;

    let num_seeds = collections_list_len(seed_node_ids);
    if (num_seeds == 0.0) { return 0.0; }

    // Step 2: Seed the frontier
    var s_idx = 0.0;
    while (s_idx < num_seeds) {
        let s_node = collections_list_get(seed_node_ids, s_idx);
        let s_act = collections_list_get(seed_activations, s_idx);

        if (s_node >= 0.0 && s_node < pad.max_nodes && pad.frontier_tail < pad.max_frontier) {
            let tail = pad.frontier_tail;
            collections_list_set(pad.f_node_id, tail, s_node);
            collections_list_set(pad.f_parent_id, tail, -1.0);
            collections_list_set(pad.f_activation, tail, s_act);
            collections_list_set(pad.f_depth, tail, 0.0);
            collections_list_set(pad.f_rel_type, tail, 0.0);
            collections_list_set(pad.f_path0, tail, s_node);
            collections_list_set(pad.f_path1, tail, -1.0);
            collections_list_set(pad.f_path2, tail, -1.0);
            pad.frontier_tail = tail + 1.0;

            // Record in visited table
            collections_list_set(pad.v_epoch, s_node, epoch);
            collections_list_set(pad.v_max_act, s_node, s_act);
            collections_list_set(pad.v_parent_id, s_node, -1.0);
            collections_list_set(pad.v_rel_type, s_node, 0.0);
            collections_list_set(pad.v_depth, s_node, 0.0);

            // Add to results
            if (pad.result_count < pad.max_frontier) {
                let res_idx = pad.result_count;
                collections_list_set(pad.result_node_ids, res_idx, s_node);
                collections_list_set(pad.result_activations, res_idx, s_act);
                pad.result_count = res_idx + 1.0;
            }
        }
        s_idx = s_idx + 1.0;
    }

    // Step 3: BFS Expansion Loop
    while (pad.frontier_head < pad.frontier_tail) {
        let head = pad.frontier_head;
        let u = collections_list_get(pad.f_node_id, head);
        let act_u = collections_list_get(pad.f_activation, head);
        let depth_u = collections_list_get(pad.f_depth, head);
        let p0 = collections_list_get(pad.f_path0, head);
        let p1 = collections_list_get(pad.f_path1, head);
        let p2 = collections_list_get(pad.f_path2, head);
        pad.frontier_head = head + 1.0;

        // Depth-bounded traversal
        if (depth_u < max_depth) {
            let start_edge = collections_list_get(graph.row_ptrs, u);
            let end_edge = collections_list_get(graph.row_ptrs, u + 1.0);

            var e = start_edge;
            while (e < end_edge) {
                let v = collections_list_get(graph.edge_targets, e);
                let raw_w = collections_list_get(graph.edge_weights, e);
                let rel = collections_list_get(graph.edge_rels, e);
                let ts = collections_list_get(graph.edge_timestamps, e);

                // --- GATE 1: Contradiction Masking ---
                // If edge indicates logical contradiction, drop immediately!
                if (rel != 2.0) { // 2.0 = REL_CONTRADICTS
                    // --- GATE 2: Static Path Cycle Rejection ---
                    // Prunes self-loops, mutual cycles, and multi-node rings
                    if (csr_is_in_path(v, p0, p1, p2) == 0.0) {
                        // --- GATE 3: Hebbian Decay & Attenuation Thresholding ---
                        let eff_w = hebbian_compute_decayed_weight(raw_w, ts, current_time, 0.01, 1.0);
                        let act_next = act_u * eff_w * decay_factor;

                        if (act_next >= tau_threshold) {
                            // --- GATE 4: Epoch-Stamped Deduplication (DISTINCT ON (node_id)) ---
                            let last_ep = collections_list_get(pad.v_epoch, v);
                            if (last_ep == epoch) {
                                // Already visited in this query: update if higher activation found
                                let prev_max = collections_list_get(pad.v_max_act, v);
                                if (act_next > prev_max) {
                                    collections_list_set(pad.v_max_act, v, act_next);
                                    collections_list_set(pad.v_parent_id, v, u);
                                }
                            } else {
                                // First visit in this epoch: record and enqueue
                                collections_list_set(pad.v_epoch, v, epoch);
                                collections_list_set(pad.v_max_act, v, act_next);
                                collections_list_set(pad.v_parent_id, v, u);
                                collections_list_set(pad.v_rel_type, v, rel);
                                collections_list_set(pad.v_depth, v, depth_u + 1.0);

                                // Add to results
                                if (pad.result_count < pad.max_frontier) {
                                    let r_idx = pad.result_count;
                                    collections_list_set(pad.result_node_ids, r_idx, v);
                                    collections_list_set(pad.result_activations, r_idx, act_next);
                                    pad.result_count = r_idx + 1.0;
                                }

                                // Enqueue to frontier
                                if (pad.frontier_tail < pad.max_frontier) {
                                    let new_tail = pad.frontier_tail;
                                    collections_list_set(pad.f_node_id, new_tail, v);
                                    collections_list_set(pad.f_parent_id, new_tail, u);
                                    collections_list_set(pad.f_activation, new_tail, act_next);
                                    collections_list_set(pad.f_depth, new_tail, depth_u + 1.0);
                                    collections_list_set(pad.f_rel_type, new_tail, rel);

                                    // Update static history path
                                    if (depth_u == 0.0) {
                                        collections_list_set(pad.f_path0, new_tail, p0);
                                        collections_list_set(pad.f_path1, new_tail, v);
                                        collections_list_set(pad.f_path2, new_tail, -1.0);
                                    } else {
                                        collections_list_set(pad.f_path0, new_tail, p0);
                                        collections_list_set(pad.f_path1, new_tail, p1);
                                        collections_list_set(pad.f_path2, new_tail, v);
                                    }
                                    pad.frontier_tail = new_tail + 1.0;
                                }
                            }
                        }
                    }
                }
                e = e + 1.0;
            }
        }
    }

    return pad.result_count;
}

// Free NSES_Scratchpad resources
fn nses_scratchpad_free(pad: NSES_Scratchpad) {
    if (pad.f_node_id != 0.0) { collections_free_list(pad.f_node_id); }
    if (pad.f_parent_id != 0.0) { collections_free_list(pad.f_parent_id); }
    if (pad.f_activation != 0.0) { collections_free_list(pad.f_activation); }
    if (pad.f_depth != 0.0) { collections_free_list(pad.f_depth); }
    if (pad.f_rel_type != 0.0) { collections_free_list(pad.f_rel_type); }
    if (pad.f_path0 != 0.0) { collections_free_list(pad.f_path0); }
    if (pad.f_path1 != 0.0) { collections_free_list(pad.f_path1); }
    if (pad.f_path2 != 0.0) { collections_free_list(pad.f_path2); }
    if (pad.result_node_ids != 0.0) { collections_free_list(pad.result_node_ids); }
    if (pad.result_activations != 0.0) { collections_free_list(pad.result_activations); }
    if (pad.v_epoch != 0.0) { collections_free_list(pad.v_epoch); }
    if (pad.v_max_act != 0.0) { collections_free_list(pad.v_max_act); }
    if (pad.v_parent_id != 0.0) { collections_free_list(pad.v_parent_id); }
    if (pad.v_rel_type != 0.0) { collections_free_list(pad.v_rel_type); }
    if (pad.v_depth != 0.0) { collections_free_list(pad.v_depth); }
}
