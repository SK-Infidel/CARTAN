# Sprint 537 Plan: GeoMind Documentation Realignment, Architecture Synthesis & Obsolescence Cleanup

## Objective
Thoroughly clean up and realign the `test/geomind/` documentation suite:
1. Archive historical math and algorithms from `test/geomind/docs/architecture.md` into `test/geomind/docs/historical_documents/legacy_opencl_architecture_and_walkthroughs.md`.
2. Rewrite `test/geomind/docs/architecture.md` completely as an exhaustive, authoritative, self-contained specification of the production CARTAN GeoMind model (not a changelog).
3. Rewrite `test/geomind/docs/file_by_file.md` to map 100% strictly to the CARTAN GeoMind model files.
4. Rewrite `test/geomind/docs/user_guide.md` as the definitive user guide for `geomind.exe` (CLI flags, modes, camera biometrics, REPL commands, async interruption).
5. Modernize `test/geomind/README.md` with an integrated NSES overview (10 Cognitive Domains) and clean links to `architecture.md`, `user_guide.md`, `file_by_file.md`, and `GEOMIND_PIPELINE.md`.
6. Update `test/geomind/docs/roadmap.md` with modern CARTAN milestones.

## Work Breakdown
- **Phase 1**: Archive legacy OpenCL architecture text.
- **Phase 2**: Author comprehensive `test/geomind/docs/architecture.md`.
- **Phase 3**: Author CARTAN-specific `test/geomind/docs/file_by_file.md`.
- **Phase 4**: Author comprehensive `test/geomind/docs/user_guide.md`.
- **Phase 5**: Update `test/geomind/README.md` with NSES integration and cross-links.
- **Phase 6**: Update `test/geomind/docs/roadmap.md`.
- **Phase 7**: Validation, regression testing, CHANGELOG and ISSUES update, walkthrough archiving.
