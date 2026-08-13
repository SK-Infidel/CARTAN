# Pre-Sprint Plan: Sprint 111 — Standard Library `.cl` / `.ch` Extension Migration & AI Breakthrough Modularization

**Sprint Goal:** Migrate all CARTAN standard library files in `src/std/` to `.cl` (implementations) and `.ch` (headers), implement reusable AI breakthrough libraries (`reasoning`, `fusion`, `optim`, `resonator`), update include sites, and verify 100% clean compilation and execution.  
**Date:** August 11, 2026  
**Archive File:** `docs/archive/sprint111_std_cl_ch_migration_plan.md`  

---

## I. Architectural Components

1. **Standard Library Extension Migration (`src/std/*.cl` & `src/std/*.ch`)**:
   - Rename/move all standard library files in `src/std/` from `.car` to `.cl`.
   - Create corresponding `.ch` header files declaring exported signatures.
2. **AI Breakthrough Libraries**:
   - `src/std/reasoning.ch` / `src/std/reasoning.cl`: AZR compiler self-play & binary execution rewards.
   - `src/std/fusion.ch` / `src/std/fusion.cl`: M2N2 evolutionary crossover, KnOTS SVD, SLERP, TIES, DARE.
   - `src/std/optim.ch` / `src/std/optim.cl`: Finsler-Randers Riemannian natural gradients & ExpMap retractions.
   - `src/std/resonator.ch` / `src/std/resonator.cl`: Continuous Hopfield energy attractor basins & Banach contraction mapping.
3. **Include Path Synchronization**:
   - Update `include` paths across `test/geomind/*.car` to consume the new `.ch` / `.cl` standard library files.

---

## II. Execution & Verification Steps
1. Perform file migration in `src/std/`.
2. Create AI breakthrough library `.ch` and `.cl` modules.
3. Update include paths in `test/geomind/*.car`.
4. Rebuild `cartanc.exe` release compiler binary and native `geomind.exe`, `merge_model_weights.exe`, `run_geomind_all_modes.exe`.
5. Run full regression test suite with exit status 0.
