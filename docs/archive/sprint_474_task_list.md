# Sprint 474 Task List: Native 42-Layer Gemma Ingestion & 3-Tier Execution Pipeline

- [x] **Task 1: Pre-Sprint Scrum Alignment**
  - [x] Hold scrum with Compiler Engineer, Architect, and QA Tester subagents.
  - [x] Align on contract boundaries: `src/std/hub.cl`, `test/geomind/chat.cl`, and Target 84.

- [x] **Task 2: Eliminate Hub Checkpoint Stubs (`src/std/hub.cl`)**
  - [x] Remove 12-byte dummy `"CARTAN_CKPT\n"` writer.
  - [x] Implement `cartan_load_signed_checkpoint` with header validation (`CARTAN_MANIFOLD_CKPT_V2`), layer count, embedding dimension, and manifest parsing.
  - [x] Implement layer-streaming loader from Safetensors / binary tensors into compute buffers.

- [x] **Task 3: Wire Authentic Gemma 4 Decoder Execution in `test/geomind/chat.cl`**
  - [x] Replace 248-dim decaying average with full 2,560-dim embedding matrix lookup from `geomind_embeddings_full_262k.bin`.
  - [x] Wire sequential Gemma decoder layer execution using `cartan_gemma_layer_forward`.
  - [x] Wire final RMSNorm (`geomind_final_norm.bin`).
  - [x] Wire tied-embedding LM head projection with logit soft-capping ($30.0 \cdot \tanh(\text{logits}/30.0)$).

- [x] **Task 4: Connect Tier 3 Cognitive Warehouse Associative Fallback**
  - [x] When top-1 confidence drops below threshold or entropy spikes ("tip of the tongue"), query NSES SQLite `cognitive_memory.db` / `atomic_discourse.car_graph`.
  - [x] Relax retrieved attractor into hidden state before sampling to resolve uncertainty.

- [x] **Task 5: Author QA Target 84 (`test/compiler_suite/test_gemma4_full_model_execution.car`)**
  - [x] Gate 1: Checkpoint header verification and layer streaming loader.
  - [x] Gate 2: Full 2,560-dim token embedding lookup and sequence pooling.
  - [x] Gate 3: Gemma decoder layer forward execution with QK-Norm, GQA, and GeGLU MLP.
  - [x] Gate 4: Final RMSNorm and tied-embedding LM head soft-capped logit generation.
  - [x] Gate 5: Tier 3 reflective doubt cognitive warehouse retrieval under low confidence.

- [x] **Task 6: Empirical Compilation & Verification**
  - [x] Compile Target 84 via `cartanc.exe` with Zig `-O3 LTO Vectorized Pass Pipeline`.
  - [x] Run Target 84 executable and verify all 5 gates pass.
  - [x] Register Target 84 in `test/compiler_suite/run_tests.car` and verify full 84-target suite.

- [x] **Task 7: Documentation & Session Closeout**
  - [x] Update `ISSUES.md` (`[ISSUE-264]` and `[ISSUE-265]` marked FIXED; log resolution).
  - [x] Update `CHANGELOG.md` with concise session summary.
  - [x] Save `docs/archive/sprint_474_walkthrough.md`.
