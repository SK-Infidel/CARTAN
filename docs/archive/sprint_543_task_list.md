# Sprint 543 Task List: Standard Library Promotion (JSON, Process & XML) & Orphan Cleanup

- [x] Task 1: Create `src/std/json.cl` with scalar, string, array parsing and serialization routines.
- [x] Task 2: Create `src/std/process.cl` with `process_exec`, `process_exec_to_file`, and path security checks.
- [x] Task 3: Expand `src/std/xml.cl` with lightweight `xml_extract_attribute`, `xml_extract_tag_body`, and `xml_extract_tag_body_by_name`.
- [x] Task 4: Delete orphaned duplicate file `Projects/geomind/geom.cl`.
- [x] Task 5: Refactor `Projects/geomind/chat.cl` to import and consume `src/std/json.cl`, `src/std/process.cl`, and `src/std/xml.cl`.
- [x] Task 6: Refactor `Projects/geomind/train.cl` to consume `src/std/json.cl`.
- [x] Task 7: Author Target 90 regression test `Projects/geomind/Testing-scratch/test_stdlib_json_process_xml.car`.
- [x] Task 8: Register Target 90 and Preset 543 in `tools/run_affected_tests.ps1`.
- [x] Task 9: Recompile `bin/geomind.exe` and test binary via `cartanc build`.
- [x] Task 10: Run affected tests runner (`tools/run_affected_tests.ps1 -Sprint 543`).
- [x] Task 11: Register `[ISSUE-401]` in `ISSUES.md`.
- [x] Task 12: Update `CHANGELOG.md` ([`8.499.0`]) and `docs/ROADMAP.md` Phase 25.
- [x] Task 13: Save Walkthrough artifact to `docs/archive/sprint_543_walkthrough.md`.
