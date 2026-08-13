// src/std/resonator.ch
// CARTAN Standard Library: Continuous Hopfield Resonator & Banach Contraction Mapping Header

extern fn resonator_banach_contraction_relax(h_state: float, weight: float, beta: float, max_iters: float) -> float;
extern fn resonator_repulsive_basin_relax(h_state: float, weight: float, beta: float, max_iters: float, visited_history: ptr, repulsion_scale: float) -> float;
extern fn resonator_sample_diverse_logits(logits: ptr, active_history: ptr, rep_scale: float, temp: float) -> float;

