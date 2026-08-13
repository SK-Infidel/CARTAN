# Pre-Sprint Plan: Sprint 106 — Sakana AI M2N2 Evolutionary Niche Fusion & MAP-Elites Attraction Crossover Engine

**Sprint Goal:** Implement Model Merging of Natural Niches (M2N2) in `src/std/fusion.car` using dynamic split-point boundaries, weight attraction pairing heuristics, and MAP-Elites quality-diversity search.  
**Date:** August 11, 2026  
**Archive File:** `docs/archive/sprint106_m2n2_fusion_plan.md`  

---

## I. Architectural Components

1. **Dynamic Flexible Split-Point Boundary (`fusion_m2n2_dynamic_split`)**:
   - Eliminates fixed-layer parameter partitions. Calculates dynamic split boundaries $S \in [0, N]$ based on activation fitness profiles.
2. **Weight Attraction Heuristic (`fusion_m2n2_attraction_pair`)**:
   - Evaluates attraction score $A(w_A, w_B) = \frac{\langle w_A, w_B \rangle}{\|w_A\| \|w_B\| + \epsilon} \cdot \exp(-\|w_A - w_B\|^2)$.
   - Pairs complementary weights across distinct model niches.
3. **MAP-Elites Quality-Diversity Search (`fusion_m2n2_map_elites_crossover`)**:
   - Maintains a multi-niche grid archive of elite model candidates, executing genetic crossover and mutation without backpropagation data loss.

---

## II. Execution & Verification Steps
1. Add `fusion_m2n2_dynamic_split`, `fusion_m2n2_attraction_pair`, and `fusion_m2n2_map_elites_crossover` to `src/std/fusion.car`.
2. Integrate M2N2 passes into `test/geomind/merge_model_weights.car` and `test/geomind/main.car`.
3. Rebuild `cartanc.exe` release compiler binary and native `geomind.exe`.
4. Verify clean execution across `run_geomind_all_modes.exe` with exit status 0.
