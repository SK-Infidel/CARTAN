// src/std/dip.ch
// CARTAN Standard Library: Untrained Network Inductive Biases (Deep Image Prior) Header

extern fn dip_create_prior_network(input_channels: float, hidden_channels: float) -> ptr;
extern fn dip_reconstruct_signal(dip_ptr: ptr, corrupted_signal: ptr, max_iters: float) -> ptr;
