// src/std/elm.ch
// CARTAN Standard Library: Extreme Learning Machines (ELM) & Random Matrix Projections Header

extern fn elm_create(input_dim: float, hidden_dim: float, output_dim: float) -> ptr;
extern fn elm_fit_zero_shot(elm_ptr: ptr, inputs: ptr, targets: ptr, alpha: float) -> ptr;
extern fn elm_predict(elm_ptr: ptr, readout_weights: ptr, input_vec: ptr) -> ptr;
