# Sprint 427 Task List: Gated Reactive Metacognitive Sleep

## Phase 1: Diagnostics & Architecture
- [x] Pre-sprint deep code review on reactive sleep trigger logic in `test/geomind/train.cl`.
- [x] Document [ISSUE-175] in `ISSUES.md`.
- [x] Save sprint plan and task list to `docs/archive/`.

## Phase 2: Core Synaptic Threshold Detection
- [x] Implement `cargraph_has_prunable_synapses(csr: CsrGraph, arena: DynamicDeltaArena, threshold: float) -> float` in `src/std/cargraph_consolidate.cl`.

## Phase 3: Training Loop Trigger Gating
- [x] Update reactive sleep triggers in `test/geomind/train.cl` so acute loss/PPL spikes and climbing streaks require `cargraph_has_prunable_synapses(...) == 1.0`.

## Phase 4: Empirical QA Verification
- [x] Author regression test harness `test/geomind/nses/test_sprint14_gated_reactive_sleep.car`.
- [x] Compile and verify regression gates via `cartanc.exe` (100% pass across TS-14.1 to TS-14.4).
- [x] Rebuild native `bin/geomind.exe` and verify with `--verify`.
- [x] Update `CHANGELOG.md` to `[8.385.0]`, mark [ISSUE-175] as `[FIXED]` in `ISSUES.md`, and save `docs/archive/sprint_427_walkthrough.md`.
