# Sprint 526 Task List: Cortical Stream Dynamic Vocabulary Pruning & Ghost-Free Speculative Drafting

- [ ] **Task 1: Build Stream Domain Vocabulary Mask Generator**
  - [ ] Create `tools/build_stream_domain_masks.py` parsing `cache_google_gemma-4-E4B-it_tokenizer.json`.
  - [ ] Construct common core syntax (~1,000 tokens) + 8 stream domain vocabularies (~1,500 tokens each).
  - [ ] Generate binary mask file `test/geomind/trainingdata/checkpoints/geomind_stream_masks.bin` (2,097,152 bytes).

- [ ] **Task 2: Runtime Stream Mask Loading & Dynamic Gating**
  - [ ] In `test/geomind/chat.cl`: Implement `geomind_load_stream_masks_if_needed()`.
  - [ ] Implement `geomind_get_stream_pruned_vocab_mask(script, stream_idx, stream_w)`.
  - [ ] Wire pruned mask into `cartan_tensor_compute_lm_head_logits` with telemetry counters (`g_telemetry_pruned_lm_evals`).
  - [ ] Add CLI flag `-stream-prune` in `test/geomind/main.car`.

- [ ] **Task 3: Ghost-Free Stream-Driven Speculative Fast Drafting**
  - [ ] In `test/geomind/streams.cl` or `test/geomind/chat.cl`: Implement `geomind_stream_draft_candidate_tokens`.
  - [ ] In `test/geomind/chat.cl`: Refactor speculative decode loop so anchor token $tok_0$ is always committed first.
  - [ ] Single batched forward pass on $[tok_0, c_1, c_2, c_3]$.
  - [ ] Sequential verification with `cartan_kv_cache_clear_range` on mismatch.
  - [ ] Verify zero ghost passes and measure acceptance rate.

- [ ] **Task 4: Empirical Benchmark & Regression Testing**
  - [ ] Rebuild `bin/geomind.exe` with Clang `-O2` AVX2/FMA MSVC.
  - [ ] Benchmark live prompts on Homer, Kant, and factual Q&A.
  - [ ] Run 16-target compiler regression suite via `tools/run_affected_tests.ps1 -Sprint 526`.

- [ ] **Task 5: Documentation & Closure**
  - [ ] Save walkthrough to `docs/archive/sprint_526_walkthrough.md`.
  - [ ] Update `CHANGELOG.md` to `[8.482.0]`.
  - [ ] Mark `[ISSUE-384]` resolved in `ISSUES.md`.
