# Sprint 514 Task List: Workspace Structure Normalization

- [x] **Phase 1: Root Hygiene & Transient Debris Purge**
  - [x] Remove transient build files in root (`geomind.exe`, `geomind.lib`, `geomind.ll`, `geomind.pdb`, `cartan_jit_run.*`, `out.ll`, `capture_camera.exe`).
  - [x] Remove editor backup files (`src/cartanc/*.bak`, `src/std/*.bak`, `tools/*.bak`, `scratch/*.tmp`).
  - [x] Remove redundant root safetensors hardlinks (`cache_geomind_model.safetensors`, `cache_google_gemma-4-E4B-it_model.safetensors`, `model.safetensors`), preserving canonical `cache_model.safetensors`.
  - [x] Remove redundant transient safetensors from `bin/cache_model.safetensors` and `scratch/gemma4_hf/model.safetensors`.

- [x] **Phase 2: Test Hierarchy Normalization**
  - [x] Move `test/test_add.car` and `test/test_enum.car` to `test/legacy/`.
  - [x] Remove redundant directories `test/geomind/scratch/` and `test/geomind/tools/`.
  - [x] Remove transient build outputs from `test/geomind/` (`geomind.exe`, `geomind.ll`, `geomind.pdb`, `capture_camera.exe`, `geomind_memory.db`).
  - [x] Rename `test/geomind/Documentation/` to `test/geomind/docs/` and sanitize file names.

- [x] **Phase 3: Tools & Docs Cleanup**
  - [x] Clean build artifacts from `tools/` (`quantize_manifold_int8.exe`, `.exp`, `.lib`, `.ll`, `.pdb`, `capture_camera.pdb`, `__pycache__`).
  - [x] Move outdated `docs/CHANGELOG.md` to `docs/archive/historical_CHANGELOG_2026-07.md`.

- [x] **Phase 4: Empirical Verification & Documentation**
  - [x] Verify test runner passes (`tools/run_affected_tests.ps1 -Sprint 513`).
  - [x] Verify git status and check for unversioned debris.
  - [x] Record changes in `CHANGELOG.md` and walkthrough archive.
