# Pre-Sprint Plan: Sprint 112 — WANNs, ESNs, DIP, and ELM Standard Library Implementation & GeoMind Extension

**Sprint Goal:** Implement four novel AI paradigms as model-agnostic CARTAN standard libraries (`wann`, `esn`, `dip`, `elm`), integrate zero-shot ELM calibration and reservoir computing into GeoMind, and verify clean native execution via `cartanc.exe`.  
**Date:** August 11, 2026  
**Archive File:** `docs/archive/sprint112_novel_ai_libraries_plan.md`  

---

## I. Architectural Components

1. **Weight-Agnostic Neural Networks (`src/std/wann.ch` / `src/std/wann.cl`)**:
   - SoA DAG network topology, shared scalar weight evaluation, structural mutation operators (add edge, add node, change activation).
2. **Echo State Networks / Reservoir Computing (`src/std/esn.ch` / `src/std/esn.cl`)**:
   - Frozen sparse recurrent reservoir $W_{\text{res}}$ ($\rho < 1.0$), non-linear echo state updates, single-step Ridge regression linear readout solve.
3. **Deep Image Prior (`src/std/dip.ch` / `src/std/dip.cl`)**:
   - Untrained network structural prior $f_\theta(z)$, early-stopping signal reconstruction, E8 non-Euclidean manifold trajectory smoothing.
4. **Extreme Learning Machines (`src/std/elm.ch` / `src/std/elm.cl`)**:
   - Random matrix projections $H = g(X W_{\text{in}} + B)$, closed-form linear output weight computation $\beta = (H^T H + \lambda I)^{-1} H^T Y$.

---

## II. Execution & Verification Steps
1. Create `src/std/wann.ch`, `src/std/wann.cl`, `src/std/esn.ch`, `src/std/esn.cl`, `src/std/dip.ch`, `src/std/dip.cl`, `src/std/elm.ch`, `src/std/elm.cl`.
2. Create `test/compiler_suite/test_novel_ai_libs.car`.
3. Rebuild `cartanc.exe` release compiler binary and native test executables.
4. Execute `test_novel_ai_libs.exe` and `run_geomind_all_modes.exe` with exit status 0.
5. Finalize `CHANGELOG.md` and `docs/ROADMAP.md`.
