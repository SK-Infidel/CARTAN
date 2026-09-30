# Sprint 479 Task List: Non-Euclidean Geometric Manifold Transformation & Empirical Analogy Alignment

- [x] **Task 1: Pre-Sprint Scrum & Squad Alignment**
  - [x] Spawn Compiler Core Squad (`cartan_compiler_engineer`) to review 64-bit addressability, binary formats, and SIMD top-K kernels.
  - [x] Spawn Architecture Squad (`cartan_architect`) to formulate Riemannian metric whitening, 8 Lie subgroup decomposition, and geodesic parallel transport.
  - [x] Spawn QA Squad (`cartan_qa_tester`) to establish canonical analogy benchmark criteria and zero-priming telemetry metrics.
  - [x] Integrate squad feedback into implementation plan.

- [x] **Task 2: Fix Analogy Metric Normalization & Native SIMD Top-K Runner**
  - [x] Fix broken denominator in `test/geomind/main.car:416` to divide by `(norm_t * norm_c)`.
  - [x] Implement native AVX2 SIMD `c_cartan_analogy_search_topk` in `src/std/cartan_native_io.c` for fast candidate evaluation over 262k vocabulary.
  - [x] Expose `c_cartan_analogy_search_topk` in `src/std/cartan_native_io.c` and declare in CARTAN headers.

- [x] **Task 3: Decouple Analogy Engine to Support Authentic 2,560D Embeddings**
  - [x] Update `geomind_eval_single_analogy` in `test/geomind/main.car` to support authentic 2,560D embeddings from `geomind_embeddings_full_262k.bin`.
  - [x] Stream authentic 2,560D embeddings and centered manifold coordinates into `main.car`.
  - [x] Add truthful telemetry reporting exact candidate rank, cosine similarity, and margin without masking test failures.

- [x] **Task 4: Curate Canonical Analogy Benchmark Dataset**
  - [x] Build `test/geomind/trainingdata/analogy_benchmark.json` containing 6 balanced categories (Family, Capital-Country, Currency, Comparative, Superlative, Opposite).
  - [x] Verify each word maps to exact single BPE token IDs in Gemma's 262,144 vocabulary.

- [x] **Task 5: Implement Non-Euclidean Manifold Transformation Substrate**
  - [x] Author `tools/eval_analogy_benchmark.py` implementing:
    - Phase 1: Flat baseline extraction.
    - Phase 2: Centering & Killing-Cartan metric tensor whitening ($S_G^{2559}$).
    - Phase 3: Cartan Lie subalgebra decomposition (8 subgroups x 320D).
    - Phase 4: Riemannian geodesic parallel transport and exponential map.
  - [x] Serialize centered manifold embeddings to `geomind_embeddings_centered_262k.bin` (2.68 GB).

- [x] **Task 6: Empirical Execution & Telemetry Benchmarking**
  - [x] Run benchmark runner across all 4 phases and record Top-1, Top-5, MRR, and Cosine Margin.
  - [x] Mind the gap: analyze rank improvements and geometric distortions with zero expert priming.

- [x] **Task 7: Compiler Verification & Regression Prevention**
  - [x] Compile `geomind.exe` with `cartanc.exe`.
  - [x] Run `tools/run_affected_tests.ps1` to verify all affected compiler suite targets pass cleanly (5/5 passed in 15.35s).

- [x] **Task 8: Retrospective, Documentation & Sprint Closure**
  - [x] Update `CHANGELOG.md` with version `[8.437.0]`.
  - [x] Update `ISSUES.md` ([ISSUE-284] through [ISSUE-287]).
  - [x] Save Sprint 479 Walkthrough to `docs/archive/sprint_479_walkthrough.md`.
