# Sprint 540 Plan: Repository Log Decoupling: Partitioning `CHANGELOG.md` and `ISSUES.md` into Dedicated GeoMind Artifacts

## 1. Context & Core Directives
- **Directive**: User Rule 3 establishes that GeoMind is a testing-only model in `test/geomind/` and not part of the CARTAN programming language project. Rick directed: "give geomind it's own changelog, and issues.md. Strip out the geomind entries and add them to it's own logs. Only cartan related entries should be related to changes in cartan required to implement geomind features."
- **Issue**: `[ISSUE-398]`
- **Target Deliverables**:
  1. `test/geomind/ISSUES.md`: Dedicated GeoMind issue tracker.
  2. `test/geomind/CHANGELOG.md`: Dedicated GeoMind release history and changelog.
  3. Update `test/geomind/README.md` to link to GeoMind's new changelog and issues tracker.
  4. Refactor root `ISSUES.md`: Strip pure GeoMind issues; in mixed issues, retain only the CARTAN compiler, language, runtime, or stdlib features implemented to empower GeoMind.
  5. Refactor root `CHANGELOG.md`: Retain CARTAN compiler/stdlib changes; move model-level prompt/canary/tuning notes to `test/geomind/CHANGELOG.md`.

---

## 2. Squad Responsibilities

1. **Architecture & Geometry Squad (`cartan_architect`)**:
   - Inspect log boundary definitions to guarantee exact separation of concerns between general-purpose language/compiler specifications and model-specific experimental tracking.
2. **QA & Benchmark Squad (`cartan_qa_tester`)**:
   - Verify link integrity across both sets of markdown files, validate test suite execution via `tools/run_affected_tests.ps1`, and confirm no loss of historical information.
3. **Runtime & Hardware Squad (`cartan_runtime_engineer`)**:
   - Verify that all hardware acceleration, AVX2 SIMD intrinsics, pinned KV cache arenas, and WebGPU compute shader entries are accurately preserved on the CARTAN side of the ledger.

---

## 3. Implementation Steps

1. **Step 1: Parse and Partition Issues**:
   - Build migration dataset separating pure GeoMind, pure CARTAN, and mixed issues.
   - Author `test/geomind/ISSUES.md`.
   - Update root `ISSUES.md` with pure GeoMind entries stripped, mixed entries pruned to CARTAN focus.
2. **Step 2: Parse and Partition Changelogs**:
   - Author `test/geomind/CHANGELOG.md`.
   - Update root `CHANGELOG.md` to preserve language/compiler/runtime entries and remove model-specific tuning notes.
3. **Step 3: Update `test/geomind/README.md`**:
   - Add links to `test/geomind/CHANGELOG.md` and `test/geomind/ISSUES.md`.
4. **Step 4: Empirical Regression Run**:
   - Run selective regression suite via `tools/run_affected_tests.ps1 -Sprint 539`.
5. **Step 5: Sprint Review & Retro**:
   - Mark `[ISSUE-398] [FIXED]`, record new versions in changelogs, save walkthrough to `docs/archive/`.
