// src/std/es_opt.ch
// Header declaration file for CARTAN Evolution Strategies (ES) Optimizer
// Implements Mirrored Gaussian Noise Perturbation (Antithetic Variates) and Z-Score Standardized Score Function Gradient Estimation

fn es_optimizer_create(dimension: float, population_size: float, sigma: float, alpha: float) -> ptr;
fn es_optimizer_get_param(opt: ptr, idx: float) -> float;
fn es_optimizer_set_param(opt: ptr, idx: float, val: float) -> float;
fn es_optimizer_get_perturbed_param(opt: ptr, clone_idx: float, param_idx: float, sign: float) -> float;
fn es_optimizer_step(opt: ptr, fitness_pos: ptr, fitness_neg: ptr) -> float;
fn es_optimizer_free(opt: ptr) -> float;
