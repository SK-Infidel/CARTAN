# Sprint 514 Plan: Workspace & File Structure Normalization and Entropy Reduction

## 1. Goal
Execute a thorough, disciplined reorganization of the CARTAN repository following Workspace Organization Standards:
- `test/`: Regression test suites (`test/compiler_suite/`), verified test models (`test/geomind/`), archived legacy tests (`test/legacy/`).
- `tools/`: Reusable developer tools and build scripts.
- `scratch/`: Disposable single-use experiment workspace.
- `docs/`: Language reference, roadmaps, specs, and archived sprint deliverables.

## 2. Execution Phases
1. **Phase 1: Root Hygiene & Transient Debris Purge**
   - Remove root build artifacts (`geomind.*`, `cartan_jit_run.*`, `out.ll`, `capture_camera.exe`).
   - Remove editor backup files (`*.bak`, `*.tmp`).
   - Remove redundant root safetensors aliases (`cache_geomind_model.safetensors`, `cache_google_gemma-4-E4B-it_model.safetensors`, `model.safetensors`), keeping canonical `cache_model.safetensors`.
   - Remove transient safetensors copies from `bin/` and `scratch/gemma4_hf/`.
2. **Phase 2: Test Hierarchy Normalization**
   - Relocate loose `test/test_add.car` and `test/test_enum.car` into `test/legacy/`.
   - Purge empty directory `test/geomind/scratch/` and redundant `test/geomind/tools/`.
   - Purge transient build artifacts from `test/geomind/` (`geomind.*`, `capture_camera.exe`, `geomind_memory.db`).
   - Normalize `test/geomind/Documentation/` to lowercase `test/geomind/docs/` and sanitize file names.
3. **Phase 3: Tools & Docs Cleanup**
   - Remove compiled binaries and PDBs from `tools/` (`quantize_manifold_int8.exe/pdb/ll/exp/lib`, `capture_camera.pdb`, `__pycache__`).
   - Archive outdated `docs/CHANGELOG.md` to `docs/archive/historical_CHANGELOG_2026-07.md`.
4. **Phase 4: Empirical Regression Verification & Integrity Check**
   - Run selective regression suite via `tools/run_affected_tests.ps1 -Sprint 513`.
   - Verify compiler and path resolution integrity across the entire project.
