# Implementation Plan - CARTAN Reorganization and Scratch Cleanup

This plan addresses the high entropy of the project folder structure by cleaning up obsolete development helper scripts, unifying test files into a dedicated version-controlled directory, and merging duplicate/conflicting documentation folders.

## User Review Required

> [!IMPORTANT]
> - **Self-Hosted Compiler Stubs (`cartan_src/compiler/`)**: The folder `cartan_src/compiler/` contains old, stubbed versions of the self-hosted compiler files (e.g. `lexer.car` which does no actual tokenization) from earlier phases, alongside a `bootstrap.sh` script. The newer, modular, and fully functional self-hosted compiler files reside directly in `cartan_src/`. We propose deleting `cartan_src/compiler/` to remove these confusing duplicate stubs.
> - **Scratch Directory**: We will keep the empty `Scratch/` folder in the root workspace as the designated workspace for running transient test compilations. To keep git status clean, we will ignore the contents of `Scratch/` in `.gitignore`.

## Open Questions

- *None at this stage.*

---

## Proposed Changes

### Component 1: Root Workspace Cleanup

Remove obsolete compiled executables and empty directories polluting the repository root.

#### [DELETE] `cartanc.exe` (stale compiled binary)
#### [DELETE] `zig` (empty directory)
#### [DELETE] `implementation_plan_geometry.md` (moving to `docs/archive/`)

---

### Component 2: Dedicated Test Suite

Create a unified, version-controlled `tests/` directory in the root workspace to organize all Cartan language test files.

#### [NEW] [tests/](file:///c:/Users/rich-/source/repos/CARTAN/tests)
- Move all `.car` test files from `Scratch/tests/`, `Scratch/`, and `compiler/` into this directory.
- Move `tokenizer.json` to support BPE tokenization tests.
- Rename conflicting/duplicate test files:
  - `Scratch/test_autodiff.car` -> `tests/test_autodiff_simple.car`
  - `Scratch/tests/test_autodiff.car` -> `tests/test_autodiff_fn.car`
  - `compiler/test_phase4.ct` -> `tests/test_phase4.car`
  - Keep the newer version of `test_sprint2.car` (using `in Minkowski`) as `tests/test_sprint2.car` and discard the old one.

---

### Component 3: Documentation Unification

Merge walkthroughs and logs into a single documentation directory structure under `docs/` and establish an archive folder.

#### [NEW] [docs/archive/](file:///c:/Users/rich-/source/repos/CARTAN/docs/archive)
- Move historical phase walkthroughs and completed implementation plans here to keep the main `docs/` clean.
- Files to archive:
  - `documentation/phase1_walkthrough.md`
  - `documentation/phase2_walkthrough.md`
  - `documentation/phase3_walkthrough.md`
  - `documentation/phase4_walkthrough.md`
  - `documentation/phase5_walkthrough.md`
  - `docs/walkthrough_continuous_depth.md`
  - `docs/CHANGELOG_phase8.md`
  - `implementation_plan_geometry.md`
#### [DELETE] `documentation/changelog.md` (redundant; `docs/CHANGELOG.md` is the master changelog)
#### [DELETE] `documentation/` (empty folder once files are moved)

---

### Component 4: Scratch Folder Cleanup

Clean up obsolete Python patch scripts and test outputs from the scratch folder to restore its intended use as a clean run space.

#### [DELETE] `Scratch/*` (except keeping `Scratch/` itself as an empty directory)
- Deletes 100+ Python patch scripts (e.g. `fix_*.py`, `update_*.py`).
- Deletes temp files (`foo.rs`, `line_test.rs`, `line_test.pdb`, `temp.rs`, `cartan_compiler.car`).
- Deletes `Scratch/tests/` (after contents are moved to root `tests/`).

---

### Component 5: Git Configuration

Update `.gitignore` to keep temporary compilation and scratch run files from polluting the git status.

#### [MODIFY] [.gitignore](file:///c:/Users/rich-/source/repos/CARTAN/.gitignore)
- Add `/build/`, `/release/`, and `/Scratch/` to ignored patterns.

---

### Component 6: Compiler, Runtime, and Stale Stubs Cleanup

Clean up intermediate test files, obsolete rewrite scripts, and duplicate self-hosted compiler stubs.

#### [DELETE] `compiler/*.py` (stale rewrite scripts)
#### [DELETE] `compiler/rewrite.rs` (stale lexer rewriter)
#### [DELETE] `compiler/ast_output.txt`, `compiler/benchmark_results.txt`, `compiler/output.aer`, `compiler/output.ll`, `compiler/output.wgsl`
#### [DELETE] `gpu_runtime/patch.py`, `gpu_runtime/output.ll`, `gpu_runtime/output.wgsl`
#### [DELETE] `tensor_runtime/check_no_mangle.py`
#### [DELETE] `cartan_src/compiler/` (old stubs and duplicate bootstrap code)

---

## Verification Plan

### Automated Tests
1. Run cargo tests on compiler to verify no regressions:
   `cd compiler && cargo test`
2. Run standard cartan compilation on the relocated `hello.car` using the compiled binary to verify compiler execution:
   `.\compiler\target\release\cartanc.exe run tests/hello.car`

### Manual Verification
- Check `git status` to verify the workspace is clean and only the reorganized/new files (like `tests/` and updated `.gitignore`) are listed.
