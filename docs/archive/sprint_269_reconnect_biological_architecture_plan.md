# Sprint 269 Implementation Plan: Reconnecting Dormant Biological Architecture & Eliminating Stubs

## 1. Sprint Goal
Eliminate all stubbed, simulated, or dormant architectural components identified in [`[ISSUE-018]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md#L292-L308). Connect genuine WordNet/SlangNet LCA taxonomy distance, Continuous Hopfield memory attractor ingestion & relaxation, 8-stream Lie cortical processing, authentic Sasaki phase-space routing, real AZR compilation verification, and multimodal vision tensor processing into `test/geomind/`.

---

## 2. Pre-Sprint Scrum & Dependency Graph

### Dependency Boundaries & Read-Ahead Analysis
```
┌─────────────────────────────────────────────────────────────┐
│ src/cartanc/c_runtime.c                                     │
│ - Hopfield persistent memory pool (ingest & relax)          │
│ - Sasaki router gating applied to expert projections        │
└──────────────┬──────────────────────────────────────────────┘
               │ (Exposes C-ABI extern functions)
               ▼
┌─────────────────────────────────────────────────────────────┐
│ src/std/ (semantics.cl, resonator.cl, vision.car)            │
│ - LCA tree distance & Information Content calculations      │
│ - Multidimensional Hopfield matrix relaxation               │
│ - Real RGB image creation & bilinear patch resize           │
└──────────────┬──────────────────────────────────────────────┘
               │ (Standard library modules)
               ▼
┌─────────────────────────────────────────────────────────────┐
│ test/geomind/ (chat.cl, streams.cl, moe.cl, azr_engine.cl)   │
│ - Replace chat.cl stubs with genuine semantics & vision     │
│ - Standardize streams.cl to modern CARTAN syntax            │
│ - Fix moe.cl Sasaki routing to evaluate full vectors        │
│ - Fix azr_engine.cl to invoke compiler for real reward      │
└──────────────┬──────────────────────────────────────────────┘
               │ (Included into driver)
               ▼
┌─────────────────────────────────────────────────────────────┐
│ test/geomind/main.car -> bin/geomind_native.exe             │
│ - Verified via cartanc_boot.exe across all operational modes│
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Detailed Work Breakdown & Task List

- [ ] **Task 1: WordNet/SlangNet LCA Taxonomy Wiring ([`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl))**
  - Replace the arithmetic stub `lca_dist = 1.0 / (1.0 + plen * 0.1)` with genuine [`semantics_lca_tree_distance`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/semantics.cl#L29-L39) and [`semantics_get_concept_ic`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/semantics.cl#L41-L53).
  - Compute actual semantic tree distance between prompt concepts and entity nodes.

- [ ] **Task 2: Continuous Hopfield Memory Attractor Pool & Ingestion ([`src/cartanc/c_runtime.c`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/c_runtime.c), [`test/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car), [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl))**
  - In `c_runtime.c`, implement persistent Hopfield attractor basin store:
    - `cartan_hopfield_ingest_token_embedding(const float* emb, size_t dim)`
    - `cartan_hopfield_relax_hidden_state(float* h, size_t dim, float beta, int max_iters)`
    - `cartan_hopfield_get_energy(const float* h, size_t dim)`
  - In `main.car:--ingest`, tokenize the target file, compute embeddings, and store them into the persistent Hopfield attractor matrix.
  - In `chat.cl:geomind_chat_generate_reply`, relax the prompt hidden state against active Hopfield basins before generating tokens.

- [ ] **Task 3: Sasaki Brainstem Router & Freudenthal MoE Gating ([`src/cartanc/c_runtime.c`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/c_runtime.c), [`test/geomind/moe.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/moe.cl))**
  - In `c_runtime.c:4242-4250`, scale each quadrant block projection by `expert_gates[e]` so router scores actually steer model representations.
  - In `test/geomind/moe.cl:geomind_sasaki_route`, evaluate phase-space distance across all vector dimensions instead of only index 0.

- [ ] **Task 4: Standardize & Reconnect 8 Lie Cortical Streams ([`test/geomind/streams.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/streams.cl), [`test/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car))**
  - Refactor `streams.cl` from obsolete `import`/`impl` syntax to valid CARTAN functions:
    - `stream_cosformer_process`, `stream_ssm_process`, `stream_spectral_process`, `stream_poincare_process`, `stream_homology_process`, `stream_eikonal_process`, `stream_heat_kernel_process`, `stream_triality_process`.
    - Provide `geomind_multistream_dispatch(h: ptr, stream_idx: float) -> ptr`.
  - Include `test/geomind/streams.cl` in `main.car`.

- [ ] **Task 5: Objective AZR Compiler Self-Play Reward ([`test/geomind/azr_engine.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/azr_engine.cl))**
  - Replace file-existence check with genuine compilation test using `c_cartan_system_exec` or compilation invocation verifying that proposed code builds with exit code 0.

- [ ] **Task 6: Multimodal Vision Tensor Ingestion ([`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl))**
  - Replace `return 1.0;` stub with genuine image creation, bilinear resizing, RGB tensor normalization via [`src/std/vision.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/vision.cl), and projection into the hidden state dimension.

- [ ] **Task 7: Full Compilation & Multi-Mode Verification**
  - Synchronize `src/cartanc/c_runtime.c` to `~/.cartan/c_runtime.c`.
  - Compile `test/geomind/main.car` with `cartanc_boot.exe` to `bin/geomind_native.exe`.
  - Empirically verify all modes (`--chat`, `--ingest`, `--azr-selfplay`, `--train-distill`, `--merge-slerp`, `--help`).
  - Update `ISSUES.md`, `CHANGELOG.md`, and archive the walkthrough.
