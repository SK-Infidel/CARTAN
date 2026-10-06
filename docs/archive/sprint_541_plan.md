# Sprint 541 Plan: Workspace Realignment to Projects Hierarchy & Dependency Normalization

## Goal
Fully realign the CARTAN repository and GeoMind model codebase to Rick's new `Projects/` folder hierarchy (`Projects/geomind/`, `Projects/geomind/Testing-scratch/`, `Projects/legacy/`), stage git renames to preserve full version history, eradicate all residual `test/` path literals and includes, and empirically verify clean compilation and execution across all affected regression targets.

## User Stories
1. **As a CARTAN compiler developer**, I need all include directives, tool invocations, and test references to resolve directly to `Projects/geomind/` and `Projects/geomind/Testing-scratch/` without relying on legacy fallbacks.
2. **As an architect**, I need git tracking to reflect true file moves and renames rather than 263 deletions and additions, maintaining unbroken repository lineage.
3. **As a QA engineer**, I need regression tests (including `test_bindgen.car`) and path resolution routines to pass 100% cleanly under the new directory layout.

## Scope of Work
1. **Target 31 Command Fix**: Update `Projects/geomind/Testing-scratch/test_bindgen.car:8` from `test/compiler_suite/test_math_string_full.car` to `Projects/geomind/Testing-scratch/test_math_string_full.car`.
2. **GeoMind Main Includes**: Update lines 5–13 in `Projects/geomind/main.car` from `test/geomind/*.cl` to `Projects/geomind/*.cl`.
3. **Path Literal Normalization**: Replace residual `test/geomind/trainingdata/` references in `Projects/geomind/train.cl`, `sleep.car`, and `Projects/geomind/nses/*.car` with `Projects/geomind/trainingdata/`.
4. **Documentation Alignment**: Synchronize `docs/TRAINING_TOOLCHAIN.md` and `docs/spec.md` references to `Projects/`.
5. **Git Staging**: Stage all 263 moved files via `git add -A` and verify git detects renames.
6. **Issue Registration**: Register `[ISSUE-399]` in root `ISSUES.md` and `Projects/geomind/ISSUES.md`. Add `[ISSUE-398]` to `Projects/geomind/ISSUES.md`.
7. **Empirical Verification**: Run `tools/run_affected_tests.ps1` to confirm 100% PASS across regression targets.
