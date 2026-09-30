# Sprint 484 Task List: Eradicating Inference Stubs, Logit Hacks & C Kernels

## Gate 1: NSES Knowledge Integrity & Fallback Table Purge
- [x] **Task 1.1**: In `src/std/nses_pipeline.cl`, remove lines 360–485 containing all 40+ hardcoded string branches.
- [x] **Task 1.2**: Implement authentic SQLite fallback query (`pipe.db`) when node text is missing from `pipe.graph_file`.
- [x] **Task 1.3**: Verify `test/compiler_suite/test_nses_language_domain.car` and related targets pass with authentic dynamic knowledge retrieval.

## Gate 2: Chat Inference Logit Purity & Clamp Purge
- [x] **Task 2.1**: In `test/geomind/chat.cl`, delete manual punctuation suppression at lines 1419–1425 (`cartan_vec_set_f32(logits_vec, 236881.0, -10000.0)`).
- [x] **Task 2.2**: In `test/geomind/chat.cl`, remove arbitrary additive concept logit boosting (`semantics_apply_concept_logit_boost`); replace with continuous latent steering before layer forward.

## Gate 3: Pure CARTAN Analogy Search & C Kernel Elimination
- [x] **Task 3.1**: Implement `cartan_analogy_search_topk` in pure CARTAN in `src/std/geom.cl` using `@cartan_simd_dot_f32`.
- [x] **Task 3.2**: Update `test/geomind/main.car` to call native `cartan_analogy_search_topk`.
- [x] **Task 3.3**: In `src/std/transformer.cl`, manage KV cache arenas and PLE cache in pure CARTAN.
- [x] **Task 3.4**: In `src/cartanc/llvm_codegen.car`, add native `cartan_mmap_file(path: string) -> ptr` and `cartan_munmap_file(view: ptr) -> double` intrinsics.
- [x] **Task 3.5**: Delete dead C kernels and custom mmap wrappers from `src/std/cartan_native_io.c`.

## Gate 4: Empirical Chat Verification, Regression Clearance & Binary Sync
- [x] **Task 4.1**: Update `tools/run_affected_tests.ps1` with `$SprintMapping[484]` and enable execution on Targets 37–70.
- [x] **Task 4.2**: Recompile `geomind.exe` with Zig `-O3` LTO.
- [x] **Task 4.3**: Verify interactive chat with prompt `"What is the capital of Iran"` across 3 execution profiles (raw baseline `--no-expert-priming`, latent priming, stochastic sampling) without logit clamps.
- [x] **Task 4.4**: Run full 87-target compiler regression suite via `test/compiler_suite/run_tests.car`.
- [x] **Task 4.5**: Synchronize all 4 production binaries.
- [x] **Task 4.6**: Update `CHANGELOG.md`, `ISSUES.md`, and write `docs/archive/sprint_484_walkthrough.md`.

