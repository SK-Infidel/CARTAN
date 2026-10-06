# Sprint 540 Task List: Repository Log Decoupling: Partitioning `CHANGELOG.md` and `ISSUES.md` into Dedicated GeoMind Artifacts

- [x] **1. Startup Code Review & Audit**
  - [x] Analyze all 398 issues in `ISSUES.md` and 575 version entries in `CHANGELOG.md`.
  - [x] Construct logical dependency tree and migration classification matrix.
  - [x] Save startup code review to `docs/archive/startup_code_review_sprint540_repository_log_decoupling.md`.
  - [x] Save sprint plan to `docs/archive/sprint_540_plan.md`.

- [x] **2. Pre-Sprint Scrum Alignment**
  - [x] Dispatch plan to `cartan_architect` for architectural review and sign-off.
  - [x] Dispatch plan to `cartan_runtime_engineer` for runtime & hardware preservation review and sign-off.
  - [x] Dispatch plan to `cartan_qa_tester` for verification criteria and link checking review and sign-off.

- [x] **3. Create GeoMind Dedicated Artifacts**
  - [x] Author `test/geomind/ISSUES.md` incorporating pure GeoMind issues and GeoMind-facing descriptions of mixed issues.
  - [x] Author `test/geomind/CHANGELOG.md` incorporating GeoMind version releases and model milestones.
  - [x] Update `test/geomind/README.md` with links to `test/geomind/CHANGELOG.md` and `test/geomind/ISSUES.md`.

- [x] **4. Prune Root CARTAN Logs**
  - [x] Backup root `ISSUES.md` and `CHANGELOG.md`.
  - [x] Refactor root `ISSUES.md`: Strip pure GeoMind issues; in mixed issues, retain only the CARTAN compiler, language, runtime, or stdlib features implemented to empower GeoMind.
  - [x] Refactor root `CHANGELOG.md`: Retain CARTAN compiler/stdlib changes; move model-level prompt/canary/tuning notes to `test/geomind/CHANGELOG.md`.
  - [x] Verify clean UTF-8 encoding and remove backup files.

- [x] **5. Verification & Sprint Wrap-Up**
  - [x] Validate markdown links and formatting across all 4 log files.
  - [x] Execute regression test suite via `tools/run_affected_tests.ps1` (23/23 PASS in 131.94s).
  - [x] Mark `[ISSUE-398] [FIXED]`.
  - [x] Update `CHANGELOG.md` with version `[8.496.0]`.
  - [x] Save walkthrough to `docs/archive/sprint_540_walkthrough.md`.
