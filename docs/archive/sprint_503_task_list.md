# Sprint 503 Task List: Ultra-Low-Latency Manifold Generation & PCIe Bottleneck Elimination

- [ ] **Task 503.1: Pre-Sprint Scrum Alignment**
  - Convene subagents (`cartan_runtime_engineer`, `cartan_architect`, `cartan_qa_tester`) to sign off on architectural design and read-ahead risks.
- [ ] **Task 503.2: Persistent WebGPU Staging Buffers in `src/std/wgpu.cl`**
  - Implement reusable pinned staging readback buffer pool (`g_wgpu_persistent_staging_buf`, `g_wgpu_persistent_staging_size`) in `cartan_wgpu_read_buffer`.
  - Eliminate all `wgpuDeviceCreateBuffer` and `wgpuBufferDestroy` calls during readback passes.
- [ ] **Task 503.3: High-Speed Zero-Copy In-RAM AVX2 FFN for Decode in `src/std/transformer.cl`**
  - In `cartan_manifold_layer_forward_raw`, execute single-token decode ($T=1$, `seq_len == pos + 1`) via native AVX2 SIMD dot products in DDR5 host RAM, completely bypassing the 13.2 GB PCIe weight upload.
  - Retain GPU GeGLU hardware acceleration for sequence prefill (`seq_len > pos + 1`) where layer weights are amortized across prompt tokens.
- [ ] **Task 503.4: Zero-Copy LM Head Logits Pipeline in `test/geomind/chat.cl`**
  - Optimize `geomind_chat_dispatch_gpu_lm_head` and sampling loop to eliminate the 262,144 scalar `cartan_vec_set_f32` unpack overhead.
- [ ] **Task 503.5: Rebuild `bin/geomind.exe` and Empirical Generation Verification**
  - Build `bin/geomind.exe` with `cartanc.exe`.
  - Empirically measure prompt-to-first-token latency and decode tokens/sec.
- [ ] **Task 503.6: Full Compiler Suite Regression & Sprint Wrap-Up**
  - Execute `tools/run_affected_tests.ps1 -All` (88 targets).
  - Update `CHANGELOG.md`, `ISSUES.md`, and generate `docs/archive/sprint_503_walkthrough.md`.
