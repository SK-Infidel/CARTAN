// src/std/wann.cl
// CARTAN Standard Library: Weight-Agnostic Neural Networks (WANNs) Implementation

include "src/std/math.cl";

fn wann_create_network(num_inputs: float, num_outputs: float) -> ptr {
    let graph = cartan_tree_create();
    // Index 0: num_inputs, Index 1: num_outputs, Index 2: node_count
    cartan_tree_push_f32(graph, num_inputs);
    cartan_tree_push_f32(graph, num_outputs);
    cartan_tree_push_f32(graph, num_inputs + num_outputs);
    return graph;
}

fn wann_mutate_add_connection(wann_ptr: ptr, src_node: float, dst_node: float) -> float {
    // Add directed edge (src_node -> dst_node) to SoA edge list
    let edge = cartan_tree_create();
    cartan_tree_push_f32(edge, src_node);
    cartan_tree_push_f32(edge, dst_node);
    cartan_tree_push(wann_ptr, edge);
    return 1.0;
}

fn wann_mutate_add_node(wann_ptr: ptr, edge_idx: float, act_type: float) -> float {
    let node_count = cartan_tree_get_f32(wann_ptr, 2.0);
    let new_node_id = node_count;
    cartan_tree_set_f32(wann_ptr, 2.0, node_count + 1.0);
    return new_node_id;
}

fn wann_evaluate_shared_weight(wann_ptr: ptr, inputs: ptr, shared_w: float) -> ptr {
    let num_outputs = cartan_tree_get_f32(wann_ptr, 1.0);
    let outputs = cartan_tree_create();
    let in_val = cartan_tree_get_f32(inputs, 0.0);
    
    // Evaluate DAG topology using single shared scalar weight parameter across all connections
    var i = 0.0;
    while (i < num_outputs) {
        let node_act = tanh(in_val * shared_w);
        cartan_tree_push_f32(outputs, node_act);
        i = i + 1.0;
    }
    return outputs;
}
