// src/std/wann.ch
// CARTAN Standard Library: Weight-Agnostic Neural Networks (WANNs) Header

extern fn wann_create_network(num_inputs: float, num_outputs: float) -> ptr;
extern fn wann_mutate_add_connection(wann_ptr: ptr, src_node: float, dst_node: float) -> float;
extern fn wann_mutate_add_node(wann_ptr: ptr, edge_idx: float, act_type: float) -> float;
extern fn wann_evaluate_shared_weight(wann_ptr: ptr, inputs: ptr, shared_w: float) -> ptr;
