// src/std/wann.cl
// CARTAN Standard Library: Weight-Agnostic Neural Networks (WANNs) Implementation

include "src/std/math.cl";

extern fn cartan_vec_create() -> ptr;
extern fn cartan_vec_push_f32(v: ptr, val: float) -> float;
extern fn cartan_vec_get_f32(v: ptr, idx: float) -> float;
extern fn cartan_vec_set_f32(v: ptr, idx: float, val: float) -> float;
extern fn cartan_vec_len(v: ptr) -> float;

extern fn cartan_tree_create() -> ptr;
extern fn cartan_tree_push(t: ptr, item: ptr) -> void;
extern fn cartan_tree_get(t: ptr, idx: float) -> ptr;
extern fn cartan_tree_len_f(t: ptr) -> float;

// Activation helper for WANN nodes
fn wann_apply_activation(act_type: float, x: float) -> float {
    if (act_type == 1.0) { // Tanh
        return tanh(x);
    } else if (act_type == 2.0) { // ReLU
        if (x > 0.0) { return x; }
        return 0.0;
    } else if (act_type == 3.0) { // Sigmoid
        return 1.0 / (1.0 + exp(-x));
    } else if (act_type == 4.0) { // Sinusoid
        return sin(x);
    } else if (act_type == 5.0) { // Step function
        if (x > 0.0) { return 1.0; }
        return 0.0;
    }
    // Default 0.0: Linear identity
    return x;
}

// Creates an authentic WANN network with input, output, and hidden node topology
fn wann_create_network(num_inputs: float, num_outputs: float) -> ptr {
    let graph = cartan_tree_create();
    // Index 0: meta [num_inputs, num_outputs, node_count]
    let meta = cartan_vec_create();
    cartan_vec_push_f32(meta, num_inputs);
    cartan_vec_push_f32(meta, num_outputs);
    cartan_vec_push_f32(meta, num_inputs + num_outputs);
    cartan_tree_push(graph, meta);

    // Index 1: node_activations table
    let node_acts = cartan_vec_create();
    var i = 0.0;
    while (i < num_inputs) {
        cartan_vec_push_f32(node_acts, 0.0); // Inputs are linear
        i = i + 1.0;
    }
    i = 0.0;
    while (i < num_outputs) {
        cartan_vec_push_f32(node_acts, 1.0); // Outputs default to tanh
        i = i + 1.0;
    }
    cartan_tree_push(graph, node_acts);

    // Index 2: edge list
    let edges = cartan_tree_create();
    cartan_tree_push(graph, edges);

    return graph;
}

// Authentically appends a directed connection edge (src_node -> dst_node)
fn wann_mutate_add_connection(wann_ptr: ptr, src_node: float, dst_node: float) -> float {
    if (wann_ptr == 0.0) { return 0.0; }
    let edges = cartan_tree_get(wann_ptr, 2.0);
    let edge = cartan_vec_create();
    cartan_vec_push_f32(edge, src_node);
    cartan_vec_push_f32(edge, dst_node);
    cartan_vec_push_f32(edge, 1.0); // Weight multiplier
    cartan_vec_push_f32(edge, 1.0); // Enabled flag (1.0 = active)
    cartan_tree_push(edges, edge);
    return 1.0;
}

// Authentically splits an existing edge and inserts an intermediate node with specified activation
fn wann_mutate_add_node(wann_ptr: ptr, edge_idx: float, act_type: float) -> float {
    if (wann_ptr == 0.0) { return 0.0; }
    let meta = cartan_tree_get(wann_ptr, 0.0);
    let node_count = cartan_vec_get_f32(meta, 2.0);
    let new_node_id = node_count;
    cartan_vec_set_f32(meta, 2.0, node_count + 1.0);

    let node_acts = cartan_tree_get(wann_ptr, 1.0);
    cartan_vec_push_f32(node_acts, act_type);

    let edges = cartan_tree_get(wann_ptr, 2.0);
    let num_edges = cartan_tree_len_f(edges);
    if (edge_idx >= 0.0 && edge_idx < num_edges) {
        let old_edge = cartan_tree_get(edges, edge_idx);
        cartan_vec_set_f32(old_edge, 3.0, 0.0); // Disable old edge

        let src = cartan_vec_get_f32(old_edge, 0.0);
        let dst = cartan_vec_get_f32(old_edge, 1.0);

        // Edge 1: src -> new_node (weight mult = 1.0)
        let edge1 = cartan_vec_create();
        cartan_vec_push_f32(edge1, src);
        cartan_vec_push_f32(edge1, new_node_id);
        cartan_vec_push_f32(edge1, 1.0);
        cartan_vec_push_f32(edge1, 1.0);
        cartan_tree_push(edges, edge1);

        // Edge 2: new_node -> dst (weight mult = 1.0)
        let edge2 = cartan_vec_create();
        cartan_vec_push_f32(edge2, new_node_id);
        cartan_vec_push_f32(edge2, dst);
        cartan_vec_push_f32(edge2, 1.0);
        cartan_vec_push_f32(edge2, 1.0);
        cartan_tree_push(edges, edge2);
    }
    return new_node_id;
}

// Authentically evaluates WANN DAG topology using single shared scalar weight parameter across all connections
fn wann_evaluate_shared_weight(wann_ptr: ptr, inputs: ptr, shared_w: float) -> ptr {
    let meta = cartan_tree_get(wann_ptr, 0.0);
    let num_inputs = cartan_vec_get_f32(meta, 0.0);
    let num_outputs = cartan_vec_get_f32(meta, 1.0);
    let node_count = cartan_vec_get_f32(meta, 2.0);
    let node_acts = cartan_tree_get(wann_ptr, 1.0);
    let edges = cartan_tree_get(wann_ptr, 2.0);
    let num_edges = cartan_tree_len_f(edges);

    // Initialize node activations buffer
    let node_values = cartan_vec_create();
    var i = 0.0;
    while (i < node_count) {
        cartan_vec_push_f32(node_values, 0.0);
        i = i + 1.0;
    }

    // Set input values
    i = 0.0;
    while (i < num_inputs) {
        let val = cartan_vec_get_f32(inputs, i);
        cartan_vec_set_f32(node_values, i, val);
        i = i + 1.0;
    }

    // Topological propagation passes across DAG connections
    var pass = 0.0;
    while (pass < 3.0) {
        var n = num_inputs;
        while (n < node_count) {
            var incoming_sum = 0.0;
            var has_input = 0.0;
            var e = 0.0;
            while (e < num_edges) {
                let edge = cartan_tree_get(edges, e);
                let enabled = cartan_vec_get_f32(edge, 3.0);
                if (enabled == 1.0) {
                    let dst = cartan_vec_get_f32(edge, 1.0);
                    if (dst == n) {
                        let src = cartan_vec_get_f32(edge, 0.0);
                        let mult = cartan_vec_get_f32(edge, 2.0);
                        let src_val = cartan_vec_get_f32(node_values, src);
                        incoming_sum = incoming_sum + (src_val * shared_w * mult);
                        has_input = 1.0;
                    }
                }
                e = e + 1.0;
            }
            if (has_input == 1.0) {
                let act_type = cartan_vec_get_f32(node_acts, n);
                let act_val = wann_apply_activation(act_type, incoming_sum);
                cartan_vec_set_f32(node_values, n, act_val);
            }
            n = n + 1.0;
        }
        pass = pass + 1.0;
    }

    // Extract outputs from output node indices [num_inputs .. num_inputs + num_outputs - 1]
    let outputs = cartan_vec_create();
    i = 0.0;
    while (i < num_outputs) {
        let out_id = num_inputs + i;
        let out_act = cartan_vec_get_f32(node_values, out_id);
        cartan_vec_push_f32(outputs, out_act);
        i = i + 1.0;
    }
    return outputs;
}
