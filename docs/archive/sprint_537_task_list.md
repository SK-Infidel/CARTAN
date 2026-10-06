# Sprint 537 Task List: GeoMind Documentation Realignment, Architecture Synthesis & Obsolescence Cleanup

- [x] **1. Archive Historical Documents**
  - [x] Copy full legacy text of `test/geomind/docs/architecture.md` into `test/geomind/docs/historical_documents/legacy_opencl_architecture_and_walkthroughs.md`.
  - [x] Verify historical archive contains all mathematical formulas, Freudenthal magic square tables, non-Euclidean kernels, and early training insights.
  - [x] Archive legacy python documentation (`legacy_python_architecture_topological_init.md`, `legacy_python_conversation_builder.md`).

- [x] **2. Exhaustive GeoMind Architecture Specification (`test/geomind/docs/architecture.md`)**
  - [x] Author comprehensive, pure-CARTAN architecture document:
    - 42-Layer Sovereign Manifold Structure (2,560D hidden dimension, GQA, 262k SentencePiece vocab).
    - WebGPU INT4 Hardware Pipeline (ping-pong staging, 1.87 GB resident in GDDR6 VRAM, AVX2 SIMD fallback).
    - Lie Subgroup Stream Decomposition (8 maximal Lie subgroups, SVD adapters).
    - Sasaki Brainstem Mixture of Experts (MoE) Dynamic Routing (Layer 24 phase-space gating, Fast Path bypass $w^* \ge 0.35$).
    - Continuous Hopfield Associative Memory & Live Fast Weights (2560D attractor basins, speculative drafting).
    - Embedded Tier 2 Cognitive Memory & NSES (10 Domains in SQLite WAL).
    - Dynamic JIT Context Grounding & Minimal Startup Prefill ($\le 30$ tokens, on-demand Domain 10 retrieval).
    - Agentic Host Operations & Hardware Perception (GDI/WinRT screen OCR, web browsing, shell & file I/O).
    - Terminal Interface, Interactive REPL & Non-Blocking Async Key Interruption (`/` key CRT polling).
    - Mathematical Formulations (Finsler-Randers metric, Zipfian logit adjustment, StreamingLLM attention sinks).

- [x] **3. CARTAN GeoMind File Reference (`test/geomind/docs/file_by_file.md`)**
  - [x] Author pure-CARTAN file-by-file reference detailing:
    - `test/geomind/main.car`, `chat.cl`, `moe.cl`, `streams.cl`, `train.cl`, `cloze_engine.cl`, `sft_train.cl`, `webgpu_causal_engine.cl`, `merge_model_weights.cl`, `sleep.car`, `azr_engine.cl`.
    - Standard library dependencies: `src/std/transformer.cl`, `wgpu.cl`, `sqlite_vec.cl`, `cargraph.cl`, `fusion.cl`, `distill.cl`, `domain_lexicon.cl`, `burroughs.cl`.
    - Active regression test suite targets and hardware perception tools (`tools/read_screen_ocr.cs`, `tools/build_screen_ocr.ps1`).

- [x] **4. Comprehensive User Guide (`test/geomind/docs/user_guide.md`)**
  - [x] Author pure-CARTAN user guide detailing:
    - Compilation with `cartanc.exe` and execution modes (`--chat`, `--train-pre`, `--train-cloze`, `--train-ce`, `--train-sft`, etc.).
    - Complete CLI flag catalog (`-prompt`, `-user`, `-tokens`, `-stream-prune`, `-cpu`, `-vram`, etc.).
    - Biometric camera authentication and face enrollment (`/register-face`).
    - Full interactive REPL slash command catalog (`/help`, `/think`, `/telemetry`, `/stream`, `/color`, `/anim`, `/whoami`, `/register-face`, `/screen`, `/browse`, `/read`, `/write`, `/exec`, `/ls`, `/exit`).
    - Non-blocking `/` key interruption during live generation.

- [x] **5. Modernized `test/geomind/README.md` with NSES Integration**
  - [x] Rewrite `test/geomind/README.md` to introduce GeoMind, highlight its core pillars, and provide quickstart commands.
  - [x] Integrate comprehensive Neuro-Symbolic Expert System (NSES) section detailing the 10 Cognitive Domains, relational graph traversal, and safety guardrails.
  - [x] Add explicit navigation links to `architecture.md`, `user_guide.md`, `file_by_file.md`, `GEOMIND_PIPELINE.md`, and `roadmap.md`.

- [x] **6. Modernized Roadmap (`test/geomind/docs/roadmap.md`)**
  - [x] Update `test/geomind/docs/roadmap.md` to reflect completed CARTAN milestones (Phases 1–7) and future horizons (Phases 8–10: Metacognitive Sleep, Multimodal Eikonal Vision, Distributed Multi-GPU Federation).

- [x] **7. Verification & Sprint Wrap-Up**
  - [x] Verify markdown links, formatting, and file paths across all modified docs.
  - [x] Run regression suite (`tools/run_affected_tests.ps1 -Sprint 537`: 18/18 PASS in 122.44s).
  - [x] Mark `[ISSUE-395] [FIXED]` in `ISSUES.md`.
  - [x] Update `CHANGELOG.md` to version `[8.493.0]`.
  - [x] Save walkthrough to `docs/archive/sprint_537_walkthrough.md`.
