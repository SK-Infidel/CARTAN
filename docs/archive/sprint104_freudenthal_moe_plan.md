# Pre-Sprint Plan: Sprint 104 — 4x4 Division Algebra Freudenthal MoE Grid & Sasaki Router

**Sprint Goal:** Implement the full 16-expert $4 \times 4$ Freudenthal Magic Square division algebra matrix ($\mathbb{R}, \mathbb{C}, \mathbb{H}, \mathbb{O}$) and Sasaki tangent bundle phase-space router ($TM = M \times T_x M$) in `test/geomind/moe.car`.  
**Date:** August 11, 2026  
**Archive File:** `docs/archive/sprint104_freudenthal_moe_plan.md`  

---

## I. Architectural Components

1. **Composition Algebra Expert Grid ($\mathbb{R}, \mathbb{C}, \mathbb{H}, \mathbb{O} \times \mathbb{R}, \mathbb{C}, \mathbb{H}, \mathbb{O}$)**:
   - 16 distinct expert blocks mapping Lie algebra symmetries ($\mathfrak{so}(3), \mathfrak{su}(3), \mathfrak{sp}(3), \mathfrak{f}_4, \mathfrak{e}_6, \mathfrak{e}_7, \mathfrak{e}_8$).
2. **Sasaki Phase-Space Router (`SasakiRouter`)**:
   - Evaluates tangent bundle distance $d_{\text{Sasaki}}^2(e) = \sum (x_{e,d}^2 + v_{e,d}^2)$ over position $x$ and velocity momentum $v = x_l - x_{l-1}$.
   - Softmax routing logits: $\text{probs} = \text{softmax}(-d_{\text{Sasaki}}^2 \cdot \sigma_{\text{Shannon}})$.
3. **Hardware Autotuned GEMM Tiling**:
   - Integrates `autotune_matmul_tiled` for micro-kernel execution across expert blocks.

---

## II. Execution & Verification Steps
1. Update `test/geomind/moe.car` to define `FreudenthalExpert` struct, `SasakiRouter` struct, and 16-expert grid dispatch.
2. Rebuild release compiler `cartanc.exe` and native `geomind.exe`.
3. Verify clean execution of `geomind.exe --help`, `geomind.exe --chat`, and `geomind.exe --train-sft` with exit code 0.
