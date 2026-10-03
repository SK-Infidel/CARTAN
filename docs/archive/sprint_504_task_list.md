# Sprint 504 Task List: Sub-Second Prompt Prefill & High-Speed Autoregressive Generation

- [ ] **Task 504.1: Pre-Sprint Scrum Alignment**
  - Convene subagents (`cartan_runtime_engineer`, `cartan_architect`, `cartan_qa_tester`) to sign off on architectural design and read-ahead risks.
- [ ] **Task 504.2: Zero-Copy AVX2 SIMD Prefill Routing in `src/std/transformer.cl`**
  - Eliminate the 4,536 synchronous per-token WebGPU queue/poll roundtrips in `cartan_manifold_layer_forward_native` during sequence prefill.
  - Route all sequential token forward steps directly through zero-copy in-RAM AVX2 SIMD.
- [ ] **Task 504.3: 4-Way Unrolled High-Throughput GEMVs in `src/std/transformer.cl`**
  - Unroll Q projection 4-way ($4 \times \text{cartan\_simd\_dot\_f32}$).
  - Unroll W_o projection 4-way ($4 \times \text{cartan\_simd\_dot\_f32}$).
  - Upgrade GeGLU Gate/Up and Down projections to 4-way unrolling with interleaved accumulation.
- [ ] **Task 504.4: Rebuild `bin/geomind.exe` and Empirical Latency Telemetry**
  - Compile `bin/geomind.exe` using `cartanc.exe`.
  - Empirically verify prompt-to-response prefill latency ($< 2.0$ seconds) and decode generation tokens/second.
- [ ] **Task 504.5: Full Compiler Suite Regression Verification**
  - Execute `tools/run_affected_tests.ps1 -All` (88 targets).
  - Update `CHANGELOG.md`, `ISSUES.md`, and generate `docs/archive/sprint_504_walkthrough.md`.
