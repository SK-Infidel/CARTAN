# GeoMind Sovereign Architectural Roadmap

## Vision & Core Objectives
**GeoMind** is an autonomous, multimodal, neuro-symbolic cognitive intelligence model written natively in **CARTAN**. The mission of the GeoMind project is to eliminate the two-language barrier, delivering high-performance bare-metal execution, continuous Lie algebra differential geometry, associative memory relaxation, and verified symbolic reasoning in a unified, self-contained architecture.

---

## Completed Milestones (Phases 1–7)

### Phase 1: Native CARTAN Architecture & Self-Hosting Port
- Decoupled from Python/PyTorch and legacy OpenCL runtimes.
- Implemented full 42-layer transformer and continuous manifold in pure CARTAN (`Projects/geomind/chat.cl`, `src/std/transformer.cl`).
- Validated self-hosting compiler compilation via `cartanc.exe`.

### Phase 2: WebGPU INT4 Quantization & VRAM Residency
- Implemented native `@cartan_simd_dot_i4_f32` AVX2 vector intrinsic.
- Built offline quantizer halving model weights from 3.95 GB to 1.87 GB.
- Pinned all 42 INT4 manifold layers (1.87 GB resident) directly in GPU GDDR6 VRAM via WebGPU WGSL compute shaders.
- Implemented branchless GPU decoding (`unpack4x8unorm` + `select`) and ping-pong double-buffered staging.

### Phase 3: Sasaki Brainstem Dynamic MoE Routing
- Formulated 5,120-dimensional tangent bundle phase-space $T\mathcal{M} = (x, \dot{x})$ at Layer 24.
- Implemented Riemannian Sasaki metric distance evaluations against expert prototypes.
- Implemented invariant-safe Fast Path bypass ($w^* \ge 0.35$ directly to Anchor Layer 41), accelerating conversational decode up to $4\times$ while running full layers for complex reasoning.

### Phase 4: Continuous Hopfield Memory & Speculative Drafting
- Integrated Modern Continuous Hopfield energy minimization network with 2,560-D attractor centroids (`hopfield_basins.bin`).
- Implemented zero-backprop fast weights registering conversational turn hidden states.
- Implemented 5-token speculative burst candidate drafting with invariant KV cache rollback (`cartan_kv_cache_clear_range`).

### Phase 5: Tier 2 Cognitive Memory & 10-Domain NSES
- Connected embedded SQLite WAL database managing 10 structured Cognitive Domains (`src/std/sqlite_vec.cl`).
- Implemented relational rules, dependencies, and heuristic edge weight adjustments.
- Built dynamic interlocutor attribute store and multi-clause conversational fact extraction.

### Phase 6: Terminal Interface, Async Interruption & Agentic Perception
- Integrated non-blocking CRT `_kbhit()` polling during autoregressive decode, enabling instantaneous `/` key interruption.
- Built full ANSI terminal styling engine with dynamic in-place rotating braille/ASCII spinners and line erasure.
- Integrated DirectShow/Win32 camera capture and 320-D eikonal face embeddings for biometric interlocutor authentication ($\ge 0.85$ threshold).
- Integrated hardware-accelerated desktop screen OCR via Win32 GDI and WinRT `OcrEngine` (< 0.4s).
- Implemented agentic web browsing with HTML link extraction and SSRF security sandboxing.
- Enforced Domain 10 permission tiers (sandboxed visitor vs root verified execution).

### Phase 7: Dynamic JIT Context Grounding & Minimal Startup Prefill
- Slashed prompt prefill overhead by 94.3% (from 351 to 20 tokens).
- Established minimal cognitive preamble ($\le 30$ tokens) adhering strictly to Gemma's 2-turn format.
- Implemented targeted JIT attribute retrieval querying Domain 10 only when personal semantics are present.
- Decoupled 176 tokens of tool definitions into conditional JIT schema loading.
- Added clean `/exit` and `/quit` REPL termination.

---

## Active & Upcoming Strategic Horizons (Phases 8–10)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       Future Development Horizons                           │
│                                                                             │
│  Phase 8: Autonomous Metacognitive Sleep & Replay Consolidation             │
│  - Deep offline consolidation of interaction episodes into Hopfield basins │
│  - Hebbian topological weight reinforcement and synaptic pruning            │
│                                                                             │
│  Phase 9: Multimodal Eikonal Vision Cross-Attention                         │
│  - Direct camera frame patch embedding via Continuous Eikonal paths         │
│  - Real-time perceptual grounding and visual scene question answering       │
│                                                                             │
│  Phase 10: Distributed Multi-GPU Manifold Sharding & CARTAN Federation      │
│  - Model parallelism across heterogeneous GPUs using WebGPU pipe buffers    │
│  - Peer-to-peer sovereign CARTAN agent mesh networks                        │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Phase 8: Autonomous Metacognitive Sleep & Replay Consolidation
- **Objective**: During idle sessions or via `--sleep`, GeoMind traverses newly accumulated interaction episodes from Domain 7 and updates Continuous Hopfield memory basins.
- **Topological Refinement**: Calculates clustering density over memory vectors, pruning transient noise and reinforcing high-frequency semantic invariants.

### Phase 9: Multimodal Eikonal Vision Cross-Attention
- **Objective**: Directly ingest camera frames (`camera_frame.bmp`) into the 42-layer manifold via spatial patch projections and Eikonal ray-tracing attention.
- **Capabilities**: Visual scene analysis, UI inspection, and spatial reasoning grounded in real-time camera and screen inputs.

### Phase 10: Distributed Multi-GPU Manifold Sharding & CARTAN Node Federation
- **Objective**: Shard deep manifold layers across multiple physical GPUs (e.g. discrete workstation GPU + laptop GPU).
- **Federation**: Peer-to-peer encrypted exchange of cognitive domain facts between sovereign CARTAN nodes.
