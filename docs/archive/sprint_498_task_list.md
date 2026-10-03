# Sprint 498 Task List: Restore Natural Language Generation & Manifold Coherence in GeoMind

- [ ] **Task 1: Pre-Sprint Scrum & Squad Alignment**
  - [ ] Review blocking issues and findings from startup code review.
  - [ ] Align Squad Leads (Architect, Runtime Engineer, QA Tester).

- [ ] **Task 2: Eliminate Destructive Latent Warping & Secure WebGPU Manifold Dispatch**
  - [ ] Replace `chat_streams_fwd` non-linear warping in `test/geomind/chat.cl` with calibrated affine pass-through / RMS scaling.
  - [ ] Ensure `geomind_chat_dispatch_gpu_manifold` preserves calibrated 2560-D vector magnitudes and angles.

- [ ] **Task 3: Restore Authentic Full-Sequence Prefill & KV-Cache Population**
  - [ ] Remove `if (num_tokens > 8.0)` bypass in `geomind_execute_manifold_sequence_prefill`.
  - [ ] Ensure all prompt tokens $p \in [0, N-1]$ are evaluated layer-by-layer across all 42 layers.

- [ ] **Task 4: Purge Poisoned Episodes & Optimize Cognitive Preamble**
  - [ ] Purge corrupted episodes from `test/geomind/trainingdata/cognitive_memory.db`.
  - [ ] Optimize preamble to be concise and focused, or pass clean single-turn prompts without context poisoning.

- [ ] **Task 5: Recompile `geomind.exe` and Verify Live Dialogue Generation**
  - [ ] Compile `test/geomind/main.car` into `geomind.exe` using `cartanc.exe`.
  - [ ] Run `geomind.exe -prompt "What is the capital of Germany?" -tokens 20` and verify clean output.
  - [ ] Run `geomind.exe -prompt "What is the capital of France?" -tokens 20` and verify clean output.

- [ ] **Task 6: Regression Prevention & Sprint Retrospective**
  - [ ] Run full 88-target regression test suite (`tools/run_affected_tests.ps1 -All`).
  - [ ] Update `CHANGELOG.md` and `ISSUES.md`.
  - [ ] Write `docs/archive/sprint_498_walkthrough.md`.
