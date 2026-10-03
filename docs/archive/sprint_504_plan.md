# Sprint 504 Plan: Sub-Second Prompt Prefill & High-Speed Autoregressive Generation

## 1. Context & Objective
Following empirical telemetry from Sprint 503 (`geomind.exe -prompt "What is 2+2?" -tokens 5`), prefill required 74,162 ms (74.16s) due to 4,536 synchronous per-token WebGPU queue/poll roundtrips, and decode required 785 ms/token due to scalar loop interpretation over 924k iterations.

The objective of Sprint 504 is to:
1. Eliminate the 74.1s prefill freeze by evaluating prompt tokens zero-copy via in-RAM AVX2 SIMD ($< 2.0\text{ seconds}$ TTFT).
2. Accelerate the 42-layer decode loop through 4-way unrolling across Q, W_o, Gate, Up, and Down GEMV projections in `cartan_manifold_layer_forward_native`.
3. Empirically measure time-to-first-token and tokens/sec on `bin/geomind.exe`.
4. Maintain 100% regression suite pass rate (88/88 targets).

---

## 2. Squad Alignments & Work Breakdown

### Compiler & Runtime Squad (`cartan_runtime_engineer`)
- In `src/std/transformer.cl` (`cartan_manifold_layer_forward_native`):
  - Ensure single-token steps (both prefill and decode) route to in-RAM AVX2 SIMD GeGLU, eliminating the 4,536 synchronous WebGPU driver roundtrips.
  - Implement 4-way unrolled AVX2 GEMV for Q projection ($2560 \times 2560$), W_o projection ($2560 \times 2560$), GeGLU Gate/Up ($10240 \times 2560$), and Down projection ($2560 \times 10240$).

### Architecture & Geometry Squad (`cartan_architect`)
- Ensure mathematical precision, KV-cache causal alignment, and zero-mock compliance across all 42 Sovereign Manifold layers.
- Verify that prompt prefill accurately primes the contiguous KV-cache before autoregressive generation begins.

### QA & Benchmark Squad (`cartan_qa_tester`)
- Compile `bin/geomind.exe` with `cartanc.exe`.
- Empirically verify prompt prefill latency (< 2.0 seconds) and decode generation tokens/second.
- Execute full compiler regression suite (`tools/run_affected_tests.ps1 -All`).

---

## 3. Definition of Done (DoD)
- [ ] Prompt prefill latency drops from 74.1s to $< 2.0$ seconds.
- [ ] Decode generation runs noticeably faster than 1.2 tok/s.
- [ ] Dialogue remains coherent and mathematically sound.
- [ ] Strict Zero-Mock Rule observed: 100% authentic computations.
- [ ] All 88 regression test suite targets pass with 0 failures.
- [ ] `CHANGELOG.md` and `ISSUES.md` updated.
- [ ] Walkthrough saved to `docs/archive/sprint_504_walkthrough.md`.
