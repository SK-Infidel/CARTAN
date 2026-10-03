# Biological Architecture, Fast Inference Learning, and Zero-Day Multimodal Ingestion

## 1. Executive Summary & Core Motivation

Traditional artificial neural networks suffer from the **fundamental plasticity-stability dilemma**:
1. **Sample Inefficiency**: Standard models require hammering weights with millions of gradient steps over countless hours via Backpropagation Through Time (BPTT) with infinitesimal learning rates ($\eta \approx 10^{-4}$).
2. **Catastrophic Forgetting & Transient Memory**: A conversation with an LLM does not modify its physical network; it only populates an ephemeral KV-cache that discards context once a token horizon is reached.
3. **Biological Contrast**: Human infants learn new concepts, objects, words, and foods after **1 to 3 sensory exposures**. When paired with emotional reward (dopamine), retention is near instantaneous. Infants learn through multimodal sensory confluence (vision, audition, touch, language) simultaneously, actively exploring and consolidating memories during sleep.

This document formalizes the architectural avenues, dormant systems, and new primitives required to transform **GeoMind** and **CARTAN** into a genuine biological-inspired intelligence architecture capable of **Zero-Day Intelligence Ingestion** and **Direct Inference Learning** (learning by reading, observing, and listening without traditional backpropagation).

---

## 2. Dormant Architectural Features in Current Codebase

A systematic review of `test/geomind/` and `src/cartanc/` identified existing biological-style components that are currently disconnected, bypassed, or stubbed:

| Subsystem | File & Location | Designed Biological Purpose | Current State / Disconnect | Required Activation |
| :--- | :--- | :--- | :--- | :--- |
| **Continuous Hopfield Resonator** | [`src/std/resonator.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/resonator.cl), [`test/geomind/ising_state_machine.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/ising_state_machine.cl) | **Hippocampal Fast Weights**: $\mathcal{O}(1)$ one-shot episodic memory basin storage with exponential capacity ($C \approx 2^{d/2}$). | [`--ingest`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car#L197-L216) reads byte counts without writing to memory tensors. | Bind associative attractor basins directly into inference forward pass and `--ingest`. |
| **8 Lie Subgroup Streams** | [`test/geomind/streams.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/streams.cl) | **Functional Cortical Specialization**: Dedicated submanifolds for Auditory/Fourier (`SpectralStream`), Visual/Ray (`EikonalStream`), Hierarchical/Grammar (`PoincareStream`), and Temporal Recurrence (`SSMStream`). | Omitted from [`main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car); runtime defaults to flat GEMM. | Re-integrate 8-stream parallel execution into the 42-layer manifold backbone. |
| **Sasaki Phase-Space Router** | [`test/geomind/moe.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/moe.cl), [`src/cartanc/c_runtime.c`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/c_runtime.c#L4217-L4239) | **Brainstem Dynamic Routing**: Evaluates tangent bundle phase-space $(x, \dot{x})$ (cognitive state and momentum) to dispatch tokens. | Router gating is computed in `c_runtime.c` but omitted from expert matrix output. | Apply calculated gating weights to Freudenthal expert projections. |
| **Sleep Consolidation Loop** | `docs/archive/research_original_geomind_codebase_and_docs_report.md` (`sleep.ctn`) | **Metacognitive Memory Consolidation**: Offline replay of episodic memories to stabilize slow cortical weights. | Dormant in archive; offline training relies on monolithic token epochs. | Re-implement async background daemon replaying Hopfield basins during idle state. |
| **Multimodal Vision Engine** | [`src/std/vision.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/vision.car), [`test/geomind/chat.cl:L54`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl#L54) | **Visual Cortex Grounding**: Patch extraction, bilinear scaling, and RGB tensor projection into $E_8$. | Stubbed (`return 1.0;`). | Connect native vision tensors to Eikonal stream projections. |

---

## 3. Core Principles for Human-Like Learning

### 3.1 Dual-Memory System (Complementary Learning Systems Theory)
* **Hippocampus (Fast Episodic Memory)**:
  - High plasticity, rapid synaptic updates.
  - Implemented via **Continuous Modern Hopfield Attractor Networks**.
  - Stores experiences in $\mathcal{O}(1)$ step without gradient descent:
    $$W_{\text{mem}} \leftarrow W_{\text{mem}} + \xi_t \xi_t^T \quad \text{or} \quad \mathcal{M} = [\mathcal{M}, \xi_t]$$
  - Retrieval minimizes energy to recall patterns:
    $$h^{(k+1)} = \mathbf{\Xi}^T \text{softmax}\left(\beta \mathbf{\Xi} h^{(k)}\right)$$
* **Neocortex (Slow Semantic Memory)**:
  - Low plasticity, highly structured representations.
  - Implemented via the 42-layer $E_8$ Lie Manifold Transformer.
  - Updates occur slowly to prevent catastrophic interference.

### 3.2 Direct Inference Learning via Three-Factor Hebbian Plasticity
Rather than unrolling computational graphs through time for backpropagation, the biological brain executes **Three-Factor Hebbian Learning**:
$$\Delta W_{ij} = \eta \cdot \text{Pre}_i \cdot \text{Post}_j \cdot M$$
where:
* $\text{Pre}_i$ is the presynaptic activation (input feature).
* $\text{Post}_j$ is the postsynaptic activation (output neuron response).
* $M$ is the **Neuromodulatory Signal**:
  $$M = \alpha \cdot R_{\text{reward}} + \gamma \cdot S_{\text{surprise}}$$
  * $R_{\text{reward}}$: Positive feedback from user, environment, or task completion (Dopamine).
  * $S_{\text{surprise}}$: Cross-entropy prediction error or free-energy deviation (Norepinephrine/Acetylcholine).
* **Operational Mode**: When GeoMind reads a sentence, sees an object, or hears a phrase, $M$ triggers instantaneous local rank-1 synaptic updates during the forward pass.

### 3.3 Zero-Day Intelligence Absorption (Model Cannibalization)
Instead of pre-training foundational intelligence from scratch:
1. **Language**: Graft 2560D hidden layers and vocabulary projections from open-weight donors (e.g., Gemma 4E4B in [`cache_google_gemma-4-E4B-it_model.safetensors`](file:///C:/Users/rich-/source/repos/CARTAN/cache_google_gemma-4-E4B-it_model.safetensors)).
2. **Vision**: Graft vision transformer patch encoders (SigLIP/CLIP) via the `EikonalStream`.
3. **Audition**: Graft audio spectrogram encoders (Whisper) via the `SpectralStream`.
4. **Geodesic Alignment**: Use Riemannian Retraction (`fusion_riemannian_retraction` in [`src/std/fusion.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/fusion.car)) to project donor weight representations onto GeoMind's unified 248D $E_8$ coordinate manifold.

### 3.4 Unified Multimodal Invariant Grounding
```
                      [ Reading: Text BPE ]   [ Seeing: 2D Vision Patches ]   [ Hearing: Audio Spectrogram ]
                                │                           │                              │
                                ▼                           ▼                              ▼
                        Poincare Stream              Eikonal Stream                 Spectral Stream
                       (Hyperbolic Trees)          (Geodesic Rays)                (Fourier Harmonics)
                                │                           │                              │
                                └───────────────────────────┼──────────────────────────────┘
                                                            ▼
                                                Sasaki Brainstem Router
                                                 Tangent Bundle (x, ẋ)
                                                            │
                                                            ▼
                                              Shared 248D E8 Lie Manifold
                                           ┌───────────────────────────────┐
                                           │  Unified Concept Attractor:   │
                                           │       "Apple" Basin           │
                                           │  (Word = Sight = Sound)       │
                                           └───────────────────────────────┘
```
Because all sensory streams project into the same $E_8$ Lie algebra root coordinate system, an infant or agent that sees an apple, hears the phoneme /'æp.əl/, and reads the word "apple" activates the **exact same geometric attractor basin**.

---

## 4. Implementation Blueprint & Roadmap

### Phase A: Reconnect Dormant Memory & Cortical Streams
1. **Hopfield Memory Buffer**:
   - Allocate a persistent associative memory matrix in VRAM.
   - Connect `--ingest` to encode text chunks into key-value attractor vectors.
   - Update `geomind_chat_generate_reply` to perform Hopfield relaxation against the active memory pool prior to LM head decoding.
2. **Activate the 8 Specialized Streams**:
   - Include and compile [`test/geomind/streams.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/streams.cl) in the main pipeline.
   - Route multimodal token embeddings through corresponding streams before Freudenthal MoE aggregation.
3. **Connect Sasaki Phase-Space Brainstem Gating**:
   - Multiply expert output tensors by calculated `expert_gates[e]` in `src/cartanc/c_runtime.c`.

### Phase B: Inference Plasticity & Neuromodulation
1. **Three-Factor Synaptic Update Operator**:
   - Implement `cartan_tensor_hebbian_update(W, pre, post, neuromodulator, lr)` in runtime.
   - Hook into `geomind_chat_apply_human_feedback` and online conversational reading.
2. **Objective AZR Reward Verification**:
   - Replace file-existence checks in [`test/geomind/azr_engine.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/azr_engine.cl) with genuine AST compilation and exit-status validation via `cartanc.exe`.

### Phase C: Multimodal Ingestion (Read, See, Listen)
1. **Vision Ingestion**:
   - Implement native image loading, bilinear resizing, and patch embedding in [`src/std/vision.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/vision.car).
   - Replace stub in [`test/geomind/chat.cl:L54`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl#L54) with actual visual tensor forward pass.
2. **Audio/Speech Ingestion**:
   - Implement STFT spectrogram extraction in [`src/std/audio.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/audio.car).
   - Feed audio frequency components directly into `SpectralStream`.

### Phase D: Autonomous Metacognitive Sleep Daemon
1. **Replay Consolidation Loop**:
   - Implement background thread waking on user idle.
   - Samples episodic attractors from Hopfield memory pool and runs low-temperature forward/backward replay into the 42-layer manifold weights.
   - Applies Elastic Weight Consolidation (EWC) penalty to preserve prior knowledge.
