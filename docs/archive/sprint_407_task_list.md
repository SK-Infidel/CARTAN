# Sprint 407 Task List: Native `.car_graph` Binary Storage Engine & SIMD Vector Core

- [x] **Task 1: Core Header & Type Definitions ([`src/std/cargraph.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/cargraph.cl))**
  - Define `CarGraphHeader` (64 bytes), `RuleElementMeta` (32 bytes), `DomainPartitionMeta`, and `NSES_EdgeChunk` (64 bytes).
  - Define byte constants, section alignments (4096-byte section, 64-byte vector alignment), and magic number `0x4850415247524143` ("CARGRAPH").

- [x] **Task 2: Binary Serializer & Zero-Copy Loader ([`src/std/cargraph.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/cargraph.cl))**
  - Implement `cargraph_builder_create()`, `cargraph_builder_add_domain()`, `cargraph_builder_add_rule()`, `cargraph_builder_set_embedding()`.
  - Implement `cargraph_serialize_to_file(builder, filepath)` with 4096-byte page alignment and 64-byte vector alignment.
  - Implement `cargraph_load_binary(filepath)` with sanity checks (magic, version, bounds validation) and zero-copy pointer mapping.

- [x] **Task 3: SIMD 1536-D Cosine Dot Product Core ([`src/cartanc/cargraph_simd.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/cargraph_simd.car))**
  - Implement 4-accumulator unrolled loop `cargraph_simd_dot_1536(a, b)` for AVX2/AVX-512 FMA auto-vectorization.
  - Implement `cargraph_simd_normalize_1536(v)` for unit sphere projection.
  - Implement `cargraph_simd_batch_topk(query_vec, candidate_matrix, num_candidates, k)` for fast domain and rule retrieval.

- [x] **Task 4: Empirical Regression Test Suite ([`test/geomind/nses/test_sprint1_binary_loader.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/nses/test_sprint1_binary_loader.car))**
  - Implement `TS-1.1`: Serialization roundtrip validation.
  - Implement `TS-1.2`: 64-byte cacheline alignment assertion.
  - Implement `TS-1.3`: Fuzzing test with corrupt magic, truncated headers, and out-of-bounds offsets.
  - Implement `TS-1.4`: Performance latency benchmark ($< 1.0\text{ ms}$ init, $< 2.0\text{ }\mu\text{s}$ SIMD dot).

- [x] **Task 5: Compile & Empirical Verification**
  - Compile `test_sprint1_binary_loader.car` with `cartanc.exe`.
  - Execute test binary and verify all gates pass with code 0.
  - Document results in `docs/archive/sprint_407_walkthrough.md` and update `CHANGELOG.md`.
