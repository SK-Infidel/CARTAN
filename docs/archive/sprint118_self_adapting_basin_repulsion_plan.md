# Sprint 118 Implementation Plan: Self-Adapting Dynamic Basin Energy Repulsion

## Overview
Implement Self-Adapting Dynamic Basin Energy Repulsion in `src/std/resonator.cl` and `src/std/resonator.ch` to dynamically push the Continuous Hopfield vector attractor out of previously visited energy minima during generation.

## Implementation Details
1. `src/std/resonator.cl`:
   - `resonator_repulsive_basin_relax`: Computes $E_{\text{repulsive}}(h) = E_{\text{hopfield}}(h) + \alpha \sum \exp(-\|h - s\|^2 / 2\sigma^2)$ over history vectors $s$, steering the Banach contraction mapping into unvisited regions on the $E_8$ manifold.
   - `resonator_sample_diverse_logits`: Applies self-adapting energy penalties to previously chosen token indices.
2. `test/geomind/chat.car`:
   - Integrated `resonator_repulsive_basin_relax` into the autoregressive hidden state update loop.

## Verification
- Compiled and executed `test/geomind/geomind.exe` with `cartanc.exe` and `zig cc` achieving exit status 0.
