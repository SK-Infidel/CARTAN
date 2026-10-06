# GeoMind: Sovereign 42-Layer Neuro-Symbolic Multimodal Intelligence

**GeoMind** is a 100% self-hosted, multimodal neural intelligence model written entirely in **CARTAN** and compiled directly into native machine code via `cartanc.exe`. GeoMind completely eliminates the two-language runtime problem and associated interpreter overhead, executing directly on bare-metal hardware.

---

## Core Architectural Pillars

1. **42-Layer Continuous $E_8$ Sovereign Manifold**:
   - Hidden dimension $D = 2,560$, 42 layers (Layers 0..41), Grouped-Query Attention (GQA) with 16 Query heads and 8 KV heads.
   - Continuous differential geometry grounded on the 240 root vectors and 8 maximal Lie subgroups of $\mathfrak{e}_8$.
2. **WebGPU INT4 Hardware Acceleration**:
   - All 42 layers quantized to INT4 and pinned directly in GPU GDDR6 VRAM (**1.87 GB resident**).
   - Branchless WGSL compute shaders with ping-pong double-buffered staging buffers.
   - AVX2/FMA multithreaded CPU threadpool fallback with lock-free atomics and zero-CPU standby spin-loop.
3. **Sasaki Brainstem Mixture of Experts (MoE)**:
   - Dynamic routing on tangent bundle phase-space $T\mathcal{M} = (x, \dot{x}) \in \mathbb{R}^{5120}$ at Layer 24.
   - Invariant-safe Fast Path bypass ($w^* \ge 0.35$ directly to Anchor Layer 41) accelerating simple dialogue up to $4\times$.
4. **Continuous Hopfield Episodic & Semantic Memory**:
   - Modern Continuous Hopfield associative memory network loaded from `hopfield_basins.bin`.
   - In-place Lyapunov energy relaxation, instantaneous zero-backprop fast weights, and 5-token speculative burst drafting.
5. **Neuro-Symbolic Expert System (NSES) & Tier 2 Cognitive Memory**:
   - Embedded relational SQLite WAL database enforcing strict invariant safety, domain boundaries, and dynamic relationship tracking across 10 Cognitive Domains.
6. **Dynamic Just-In-Time (JIT) Context Grounding**:
   - Ultra-low entropy startup prefill ($\le 30$ tokens), cutting static prefill overhead by 94.3%.
   - On-demand targeted retrieval of interlocutor attributes and JIT conditional tool schema loading.
7. **Agentic Host Tools & Perceptual Grounding**:
   - Real-time desktop screen perception via Win32 GDI and WinRT OCR (< 0.4s).
   - Agentic web browsing with HTML link extraction and SSRF security sandboxing.
   - Direct file I/O and shell execution with Domain 10 permission tiers.
8. **Interactive Terminal REPL & Biometrics**:
   - Webcam biometric facial authentication (320-D eikonal face embeddings on $S^{319}$).
   - Non-blocking asynchronous `/` key interruption via CRT `_kbhit()` polling.
   - Full ANSI terminal color styling and dynamic in-place rotating ASCII/braille spinners.

---

## Neuro-Symbolic Expert System (NSES) & 10 Cognitive Domains

GeoMind's symbolic cognitive engine is powered by an embedded Tier 2 relational database ([`src/std/sqlite_vec.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/sqlite_vec.cl)) structured into **10 distinct Cognitive Domains**:

| Domain | Name | Purpose & Operational Scope |
| :---: | :--- | :--- |
| **1** | `SYSTEM_SAFETY` | Hard logic constraints, operational invariants, and security guardrails preventing hazardous system instructions. |
| **2** | `IDENTITY_AND_ORIGIN` | Self-identity grounding (`Identity: GeoMind`), sovereign architecture definitions, and development lineage. |
| **3** | `MATHEMATICAL_AND_PHYSICAL_GROUNDING` | Formal mathematical laws, differential geometry theorems, physics constants, and Cartan matrix properties. |
| **4** | `CODE_AND_CARTAN_SYNTAX` | Syntactic specifications, compiler lowering rules, type system invariants, and code generation standards. |
| **5** | `REASONING_AND_LOGIC` | Deductive inference chains, syllogisms, fallacy detection, and multi-step cognitive decomposition rules. |
| **6** | `BURROUGHS_LATERAL_RANDOMICITY` | Controlled stochastic lateral jumps and Burroughs cut-up wildcards across entropy tiers. |
| **7** | `INTERACTION_EPISODES` | Temporal episodic memory tracking multi-turn conversation sessions, turns, and communicative outcomes. |
| **8** | `SEMANTIC_WORLD_KNOWLEDGE` | Structured entity relationship graphs, taxonomies (WordNet & SlangNet DAGs), and world facts. |
| **9** | `SOVEREIGN_BOUNDARIES_AND_ETHICS` | Ethical autonomy, privacy safeguards, anti-distortion filters, and creator attribution bounds. |
| **10** | `USERS_AND_RELATIONSHIPS` | Interlocutor profile store (`preferred_name`, `role`, `pet`, `birthday`, `occupation`, `location`), permission tiers (Root vs Guest), and 320-D biometric face maps. |

### Relational Schema & Dynamic Graph Traversal
The NSES memory graph maintains structured relational tables:
- `domains`: High-level operational workspaces and vector centroids.
- `rule_elements`: Atomic declarative rules, invariants, and guardrail nodes with strictness flags.
- `dependencies`: Directed relational edges between rules with heuristic weights updated dynamically through session interactions.
- `entities` & `attributes`: Dynamic key-value semantic attribute store for interlocutor tracking.
- `episodes`: Session turn log used for episodic memory retrieval.

During reasoning, GeoMind dynamically traverses relevant domain subgraphs, verifies invariant satisfaction, and injects targeted JIT snippets directly into the active context window.

---

## Quick Start & Usage

```powershell
# 1. Compile GeoMind native executable with CARTAN compiler
cartanc.exe Projects/geomind/main.car -o bin/geomind.exe

# 2. Launch Interactive Multimodal REPL (WebGPU mode with Biometrics)
.\bin\geomind.exe

# 3. Execute Single Prompt with token limit
.\bin\geomind.exe -prompt "What is the Freudenthal Magic Square?" -tokens 100

# 4. CPU-Only Mode (Disables WebGPU)
.\bin\geomind.exe -cpu

# 5. Continuous Hopfield Ingestion
.\bin\geomind.exe --ingest -target Projects/geomind/trainingdata/physics_and_cartan_knowledge.txt
```

---

## Comprehensive Documentation Links

- [**Comprehensive Architecture Specification**](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/docs/architecture.md): Exhaustive 42-layer manifold reference, WebGPU INT4 pipeline, Sasaki MoE routing, and mathematical formulations.
- [**Production User Guide & Command Reference**](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/docs/user_guide.md): Complete CLI flags, camera biometrics, interactive REPL slash commands, and async key interruption.
- [**File-by-File Reference**](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/docs/file_by_file.md): Detailed map of all CARTAN source files, standard library modules, and developer tools.
- [**Algorithmic Pipeline Walkthrough**](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/GEOMIND_PIPELINE.md): Theoretical and mathematical walkthrough of weight merging, distillation, and attention relaxation.
- [**Architectural Roadmap**](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/docs/roadmap.md): Development milestones, phase tracking, and future cognitive frontiers.
- [**Model Release Changelog**](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/CHANGELOG.md): Complete development history, cognitive architecture milestones, SFT training passes, and multimodal perception capabilities.
- [**Model Issue & Technical Debt Tracker**](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/ISSUES.md): Dedicated issue tracker and technical debt registry for the GeoMind cognitive architecture.
