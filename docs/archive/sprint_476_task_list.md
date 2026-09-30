# Sprint 476 Task List: Authentic 42-Layer Gemma Transformer Streaming

- [x] **Task 1: Baseline Test Suite Run & Audit Verification** <!-- id: 0 -->
  - [x] Verify clean baseline across existing 85 compiler targets.
  - [x] Inspect donor safetensors layer keys and verify tensor shapes and datatypes.

- [x] **Task 2: Layer Extraction & Binary Streaming Substrate** <!-- id: 1 -->
  - [x] Update `tools/clone_gemma_to_cartan.py` to extract all 42 Gemma Transformer layers from `cache_google_gemma-4-E4B-it_model.safetensors`.
  - [x] Serialize structured layer files to `test/geomind/trainingdata/checkpoints/layers/gemma4_layer_{l}.bin` with standard binary headers and aligned float offsets.

- [x] **Task 3: Layer Streaming Forward Pass in test/geomind/chat.cl** <!-- id: 2 -->
  - [x] Implement `geomind_execute_gemma_layers` in `chat.cl`.
  - [x] Stream each layer weights buffer and call `cartan_gemma_layer_forward` sequentially across layers $0..41$.
  - [x] Replace synthetic 16-step polynomial scalar formula (`e8_attention_forward_step_with_momentum`).

- [x] **Task 4: Calibrate Reflective Doubt & LM Head Memory Optimization** <!-- id: 3 -->
  - [x] Calibrate reflective doubt thresholds in `chat.cl` to `conf < 0.01` and `ent > 5.50`.
  - [x] Ingest/buffer full 262k embedding table in host memory or eliminate individual small seeks per step in `cartan_tensor_compute_lm_head_logits`.

- [x] **Task 5: Author QA Target 86 & Empirical Regression Verification** <!-- id: 4 -->
  - [x] Author `test/compiler_suite/test_gemma4_layer_streaming_pipeline.car`.
  - [x] Whitelist Target 86 in `.gitignore` and register in `test/compiler_suite/run_tests.car`.
  - [x] Run full compiler test suite ensuring all 86 targets pass with 0 failures.

- [x] **Task 6: Empirical Model Generation Verification & Sprint Closeout** <!-- id: 5 -->
  - [x] Rebuild `build/geomind.exe` with `cartanc.exe`.
  - [x] Run `geomind.exe --chat -prompt "In biology, cells divide through" -tokens 10` and verify contextual coherence.
  - [x] Update `CHANGELOG.md` with version `[8.434.0]` and close `[ISSUE-272]`, `[ISSUE-273]`, `[ISSUE-274]`.
  - [x] Author `docs/archive/sprint_476_walkthrough.md`.
