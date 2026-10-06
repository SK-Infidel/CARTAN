# Sprint 538 Plan: GeoMind End-to-End Pipeline Realignment, Zero-C Tokenizer Synchronization & Documentation Hardening

## Background & Objective
During Sprint 537 review, Rick identified an obsolete reference in [`test/geomind/GEOMIND_PIPELINE.md`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/GEOMIND_PIPELINE.md#L56-L61) to a "C-Runtime Parser" and `src/cartanc/c_runtime.c#L1310-L1380`.
The C runtime was completely eliminated in Sprints 287/312 (`c_runtime.c.deprecated`) in favor of a 100% self-hosted CARTAN runtime. Furthermore, tokenizer ingestion and decoding was ported to pure CARTAN in [`src/std/tokenizer.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/tokenizer.cl) operating over a pre-compiled binary Trie arena (`test/geomind/trainingdata/geomind_vocab_262k.bin`).
Additionally, `GEOMIND_PIPELINE.md` used outdated `.car` extensions for standard library `.cl` modules and omitted the modern 8 Lie subgroup streams, WebGPU INT4 pipeline, Sasaki MoE, Tier 2 NSES, and agentic host execution.

Sprint 538 completely overhauls `test/geomind/GEOMIND_PIPELINE.md` to be an authoritative, pure-CARTAN, zero-C end-to-end pipeline specification, updates cross-references in `README.md` and research documents, and empirically validates the compiler test suite.

---

## Deliverables
1. **Startup Code Review & Dependency Graph**:
   - Audit `test/geomind/GEOMIND_PIPELINE.md`, `src/std/tokenizer.cl`, `src/cartanc/core_runtime.car`, and research docs for any remaining `c_runtime.c` references.
   - Establish end-to-end dependency chain from `cartanc.exe` to standard libraries and `bin/geomind.exe`.
2. **Authoritative `test/geomind/GEOMIND_PIPELINE.md` Rewrite**:
   - Phase 1: Spherical Linear Interpolation (SLERP) weight consolidation ([`src/std/fusion.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/fusion.cl), [`test/geomind/merge_model_weights.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/merge_model_weights.cl)).
   - Phase 2: Teacher-Student KL Divergence & Cloze Distillation ([`src/std/distill.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/distill.cl), [`test/geomind/cloze_engine.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/cloze_engine.cl), [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl)).
   - Phase 3: Supervised Fine-Tuning (SFT) & Hub Dataset Ingestion ([`src/std/hub.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/hub.cl), [`test/geomind/sft_train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/sft_train.cl)).
   - Phase 4: Multimodal Vision & Perception Ingestion ([`src/std/vision.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/vision.cl), [`tools/read_screen_ocr.cs`](file:///C:/Users/rich-/source/repos/CARTAN/tools/read_screen_ocr.cs)).
   - Phase 5: 42-Layer Sovereign Manifold, 8 Lie Streams & Sasaki Brainstem MoE ([`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl), [`test/geomind/streams.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/streams.cl), [`test/geomind/moe.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/moe.cl), [`src/std/transformer.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/transformer.cl), [`src/std/wgpu.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/wgpu.cl)).
   - Phase 6: Pure-CARTAN SentencePiece BPE Trie Engine (Zero-C Runtime) ([`src/std/tokenizer.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/tokenizer.cl)).
   - Phase 7: Tier 2 Cognitive Memory & Relational Entity Graph ([`src/std/sqlite_vec.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/sqlite_vec.cl), [`src/std/cargraph.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/cargraph.cl)).
   - Phase 8: Interactive REPL, Non-Blocking Async Polling & Agentic Tool Execution ([`test/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car), [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl)).
3. **Research Document Cleanup**:
   - Clean up stale `c_runtime.c` references in [`test/geomind/docs/research/BIOLOGICAL_ARCHITECTURE_AND_INFERENCE_LEARNING.md`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/docs/research/BIOLOGICAL_ARCHITECTURE_AND_INFERENCE_LEARNING.md).
4. **Empirical Regression Verification**:
   - Execute regression test suite runner via `tools/run_affected_tests.ps1` to ensure zero regressions across targets.
5. **Issue Tracking & Changelog Updates**:
   - Add `[ISSUE-396]` to `ISSUES.md` and mark `[FIXED]`.
   - Update `CHANGELOG.md` with version `[8.494.0]`.
   - Save walkthrough to `docs/archive/sprint_538_walkthrough.md`.
