// src/std/esn.ch
// CARTAN Standard Library: Reservoir Computing & Echo State Networks (ESNs) Header

extern fn esn_create_reservoir(input_dim: float, res_size: float, spectral_radius: float) -> ptr;
extern fn esn_step_forward(esn_ptr: ptr, input_vec: ptr) -> ptr;
extern fn esn_solve_readout_ridge(state_matrix: ptr, target_matrix: ptr, alpha: float) -> ptr;
