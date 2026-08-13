# Pre-Sprint Plan: Sprint 107 — Absolute Zero Reasoning (AZR) Compiler Self-Play & Dual-Agent Feedback Engine

**Sprint Goal:** Implement Absolute Zero Reasoning (AZR) self-play in `test/geomind/azr_engine.car`, coupling dual-agent task proposer/solver loops with verifiable binary rewards from `cartanc.exe` compilation exits.  
**Date:** August 11, 2026  
**Archive File:** `docs/archive/sprint107_azr_selfplay_plan.md`  

---

## I. Architectural Components

1. **Task Proposer Agent (`AZRProposer`)**:
   - Synthesizes curriculum challenge tasks in CARTAN language syntax without human dataset reliance.
2. **Task Solver Agent (`AZRSolver`)**:
   - Generates candidate CARTAN source code implementations solving the proposer's task.
3. **Verifiable Objective Binary Reward Signal (`AZREvaluator`)**:
   - Compiles candidate code via `cartanc.exe`.
   - Reward $R = 1.0$ if compiler exit code is `0` (clean compilation & execution success).
   - Reward $R = 0.0$ if compilation fails.
   - Updates Continuous Hopfield attractor basin energy weights along non-Euclidean Finsler geodesics.

---

## II. Execution & Verification Steps
1. Create `test/geomind/azr_engine.car` defining `AZRProposer`, `AZRSolver`, and `AZREvaluator`.
2. Add `--azr-selfplay` flag handler to `test/geomind/main.car`.
3. Rebuild `cartanc.exe` release compiler binary and native `geomind.exe`.
4. Run `geomind.exe --azr-selfplay` and verify self-play iterations complete with exit status 0.
