# Sprint 113 Implementation Plan: CARTAN Evolution Strategies (ES) Optimizer Standard Library

## Overview
Implement native CARTAN Evolution Strategies (ES) Optimizer (`src/std/es_opt.ch` and `src/std/es_opt.cl`) providing Mirrored Gaussian Noise Perturbation (Antithetic Variates) and Z-Score Standardized Score Function Gradient Estimation ($\Delta \theta = \frac{\alpha}{N \sigma} \sum (F_i^+ - F_i^-) \epsilon_i$).

## Core Features
1. `src/std/es_opt.ch`: Public header function prototypes (`es_optimizer_create`, `es_optimizer_get_param`, `es_optimizer_set_param`, `es_optimizer_get_perturbed_param`, `es_optimizer_step`).
2. `src/std/es_opt.cl`: High-throughput Box-Muller Gaussian PRNG, zero-allocation memory pools, and score function recombination update step.
3. `test/compiler_suite/test_es_opt.car`: Verification suite testing parameter update alignment towards target character weights (`"AI"` ASCII codes `[65.0, 73.0]`).

## Verification
- Added Target 44 to `test/compiler_suite/run_tests.car`.
- Executed `run_tests.exe` with `cartanc.exe` achieving exit code 0.
