# Startup Code Review: Sprint 537 — GeoMind Documentation Realignment, Architecture Synthesis & Obsolescence Cleanup

**Date**: 2026-10-05  
**Reviewer**: Antigravity  
**Target**: `test/geomind/` Documentation Suite, Architecture Reference, File Reference, User Guide, and NSES Integration  

---

## 1. Executive Context & Objectives
During the development of GeoMind from its early exploratory prototypes to the sovereign 42-layer multimodal neural model compiled natively in CARTAN (`bin/geomind.exe`), the internal documentation in `test/geomind/docs/` has severely lagged behind. 

Specifically:
- `test/geomind/docs/architecture.md` (42 KB) is a historical compilation of legacy Python and C++ OpenCL walkthroughs and work logs referencing deprecated modules (`setup.py`, `FinslerOptimizer`, `csrc/tensor.h`, `NumpyContextRouter`, PyTorch, OpenCL).
- `test/geomind/docs/file_by_file.md` documents files from the obsolete Python project (`geomind.py`, `rif_assimilator.py`, `config.py`) that do not exist in CARTAN.
- `test/geomind/docs/user_guide.md` describes Python CLI commands (`python geomind.py --train`) instead of `geomind.exe` and its interactive REPL, biometrics, agentic tools, and performance flags.
- `test/geomind/docs/roadmap.md` outlines Python v2.5 milestones rather than the modern CARTAN sovereign model architecture.
- `test/geomind/README.md` is minimal (32 lines) and references legacy compiler paths and modes without explaining GeoMind's 10 Cognitive Domains, Neuro-Symbolic Expert System (NSES), or linking to updated documentation.

---

## 2. Logical Dependency Tree of GeoMind in CARTAN

```
test/geomind/main.car (Top-level CLI Driver, REPL Dispatcher, Camera Biometrics)
│
├── test/geomind/chat.cl (Multimodal Neuro-Symbolic Chat Engine & Agentic Dispatch)
│   ├── src/std/transformer.cl (42-Layer Model Execution, INT4 AVX2, Threadpool, KV Cache)
│   ├── src/std/wgpu.cl (WebGPU Compute Shaders, VRAM Pinning, Double-Buffered Staging)
│   ├── src/std/sqlite_vec.cl (Embedded Tier 2 Cognitive Memory: 10 Domains, Vectors)
│   ├── src/std/tokenizer.cl (SentencePiece 262k BPE Tokenizer)
│   ├── src/std/vision.cl (Multimodal Image Ingestion & Resizing)
│   ├── src/std/hub.cl (Safetensors Model Checkpoint & Weight Loader)
│   ├── test/geomind/moe.cl (Sasaki Brainstem MoE Dynamic Router, Layer 24 Phase-Space Gating)
│   └── test/geomind/streams.cl (8 Lie Subgroup Stream Transformations & SVD Adapters)
│
├── test/geomind/train.cl (Autoregressive CE Training, Anchored Cloze Curriculum Stream, SFT)
├── test/geomind/distill.cl (Teacher-Student KL Divergence Distillation)
├── test/geomind/slerp.cl (Zero-Day SLERP Geodesic Weight Merging on S^247)
├── test/geomind/azr_engine.cl (Absolute Zero Reasoning Compiler Self-Play Loop)
├── test/geomind/geometry.cl & e8_attention_engine.cl (E8 Root System Differential Geometry)
└── test/geomind/ising_state_machine.cl & ode_solver.cl (Continuous Hopfield Spin Relaxation)
```

---

## 3. Findings, Obsolescence Audit & Technical Debt

1. **Valuable Historical Mathematical Insights in `architecture.md`**:
   - Freudenthal Magic Square $4 \times 4$ MoE table over composition algebras $(\mathbb{R}, \mathbb{C}, \mathbb{H}, \mathbb{O})$.
   - 8 Lie subgroup stream domain decompositions ($SO(16)$, $E_7 \times SU(2)$, $SU(9)$, $SU(3) \times E_6$, etc.).
   - Geometric Attention Topologies (Poincaré hyperbolic, geodesic ray-tracing/Eikonal, simplicial loop homology, heat kernel diffusion).
   - Zipfian logit adjustment theory ($\text{logits} - \gamma \cdot \text{IC}(w)$).
   - *Action*: Archive these valuable historical sections to `test/geomind/docs/historical_documents/legacy_opencl_architecture_and_walkthroughs.md` before rewriting `architecture.md`.

2. **Complete Architecture Specification Needed (`test/geomind/docs/architecture.md`)**:
   - Must be an authoritative, exhaustive architectural description of the production CARTAN GeoMind model, NOT a changelog or narrative of past bugs.
   - Core sections: Sovereign 42-Layer Manifold, WebGPU INT4 Hardware Pipeline, Sasaki Brainstem MoE Dynamic Routing, Lie Subgroup Stream Transformations, Continuous Hopfield Associative Memory & Fast Weights, Embedded Tier 2 Cognitive Memory (10 Domains), Dynamic JIT Context Grounding & Minimal Prefill, Agentic Host Tools & Hardware Perception, Terminal Interface & REPL Architecture.

3. **Complete Rewrite of File Reference (`test/geomind/docs/file_by_file.md`)**:
   - Must map 100% to actual CARTAN files in `test/geomind/` and relevant `src/std/` modules.

4. **Complete Rewrite of User Guide (`test/geomind/docs/user_guide.md`)**:
   - Must document compilation via `cartanc.exe`, execution modes, CLI flags, camera biometrics, interactive REPL slash commands, and non-blocking key interruption (`/`).

5. **Integrated `test/geomind/README.md` & NSES**:
   - Modernize `README.md` to introduce GeoMind, its architectural highlights, quick start guide, and an integrated section on the Neuro-Symbolic Expert System (NSES) with its 10 Cognitive Domains, linking cleanly to `docs/architecture.md`, `docs/user_guide.md`, `docs/file_by_file.md`, and `GEOMIND_PIPELINE.md`.

---

## 4. Git Issues Identified
- Logged `[ISSUE-395]` in `ISSUES.md`: GeoMind Documentation Obsolescence, Architectural Disconnect & Missing Comprehensive Model Reference.
