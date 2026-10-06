# GeoMind Multimodal Architecture & End-to-End Pipeline

## Executive Overview
**GeoMind** is a high-performance, 100% self-contained neural intelligence architecture written entirely in native **CARTAN** and compiled to standalone native machine code via `cartanc.exe`. It completely eradicates the two-language problem and runtime overhead:
- **Zero C Runtime**: No legacy C-bridges, no C runtime JSON parsers, no external C libraries.
- **Zero External Orchestrators**: No Python wrappers, no PyTorch dependencies, no runtime interpreters.
- **Sovereign CARTAN Primitives**: All neural layers, Lie subgroup projections, differential geometry solvers, tokenizers, vector databases, and hardware compute drivers are compiled natively from CARTAN standard library modules (`src/std/`) and core engine sources (`Projects/geomind/`).

The pipeline operates across two tightly coupled subsystems:
1. **Offline Training, Distillation & Weight Consolidation Pipeline** (Phases 1–3).
2. **Online Cognitive Inference, Memory Grounding & Host Execution Dataflow** (Phases 4–8).

---

## High-Level Execution Dataflow

```
                              ┌────────────────────────────────────────────────────────┐
                              │                    cartanc.exe                         │
                              │           (Self-Hosting CARTAN Compiler)               │
                              └──────────────────────────┬─────────────────────────────┘
                                                         │
                                                         ▼
                                              bin/geomind.exe (Native)
                                                         │
      ┌──────────────────────────────────────────────────┴──────────────────────────────────────────────────┐
      │                                                                                                     │
      ▼                                                                                                     ▼
[Offline Training & Consolidation]                                                     [Online Cognitive Inference Loop]
 ├── Phase 1: SLERP Weight Fusion                                                       ├── Ingress: Pure-CARTAN SentencePiece BPE Trie
 ├── Phase 2: KL Divergence & Cloze Distillation                                        ├── Phase 7: Tier 2 NSES Cognitive Memory Grounding
 └── Phase 3: SFT & Hub Dataset Ingestion                                               ├── Phase 5: 42-Layer Manifold, 8 Lie Streams & Sasaki MoE
                                                                                        ├── Egress: LM Head & O(1) BPE String Pool Dereference
                                                                                        └── Phase 8: Non-Blocking CRT REPL & Host Perception
```

---

## Phase 1: Spherical Linear Interpolation (SLERP) & Geodesic Weight Fusion
- **Modules**: [`src/std/fusion.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/fusion.cl), [`Projects/geomind/merge_model_weights.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/merge_model_weights.cl)
- **CLI Flag**: `geomind.exe --merge-slerp` *(Standalone Harness: `cartanc.exe build Projects/geomind/merge_model_weights.cl`)*
- **Mathematical Formulation**:
  Interpolates between distinct parameter checkpoints along the spherical geodesic manifold using the Killing-Cartan metric $g$:
  $$\langle W_1, W_2 \rangle_g = \sum_{k=0}^{N-1} W_1[k] W_2[k] \cdot g_k, \quad g_k = \text{DynkinWeight}(k \bmod 8)$$
  $$\cos(\Omega) = \frac{\langle W_1, W_2 \rangle_g}{\|W_1\|_g \|W_2\|_g}$$
  $$\text{SLERP}(W_1, W_2, t) = \frac{\sin((1-t)\Omega)}{\sin\Omega} W_1 + \frac{\sin(t\Omega)}{\sin\Omega} W_2$$
  $$\|W_{\text{target}}\|_g = (1 - t)\|W_1\|_g + t\|W_2\|_g$$
- **Implementation**:
  - Memory-maps donor Safetensors weights via `cartan_mmap_file`.
  - Computes exact inner products, angular geodesic separation $\Omega$, and normalized interpolation factors.
  - Preserves spherical geometry and directional features without linear blending variance collapse.

---

## Phase 2: Teacher-Student KL Divergence Distillation & Masked Cloze Engine
- **Modules**: [`src/std/distill.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/distill.cl), [`Projects/geomind/cloze_engine.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/cloze_engine.cl), [`Projects/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/train.cl)
- **CLI Flags**: `geomind.exe --train-distill`, `geomind.exe --train-cloze`, `geomind.exe --train-ce`
- **Mathematical Formulation**:
  Minimizes Kullback-Leibler (KL) divergence over Softmax probability distributions at temperature $T$ alongside cross-entropy loss:
  $$P_{\text{teacher}}(i) = \frac{\exp(z_{T, i} / T)}{\sum_j \exp(z_{T, j} / T)}, \quad P_{\text{student}}(i) = \frac{\exp(z_{S, i} / T)}{\sum_j \exp(z_{S, j} / T)}$$
  $$\mathcal{L}_{\text{distill}} = (1 - \alpha) \mathcal{L}_{\text{CE}}(y, P_S) + \alpha T^2 \sum_{i} P_{\text{teacher}}(i) \log\left(\frac{P_{\text{teacher}}(i)}{P_{\text{student}}(i) + \epsilon}\right)$$
- **Implementation**:
  - `geomind_train_streaming_steady_state` runs iterative streaming token distillation.
  - In Cloze mode (`--train-cloze`), arbitrary tokens are masked, and student predictions are backpropagated along Riemannian gradient paths to recover masked vocabulary anchors.

---

## Phase 3: Supervised Fine-Tuning (SFT) & Hub Dataset Ingestion
- **Modules**: [`src/std/hub.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/hub.cl), [`Projects/geomind/sft_train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/sft_train.cl)
- **CLI Flag**: `geomind.exe --train-sft`
- **Pipeline Architecture**:
  1. **Dataset Ingestion**: `hub_load_dataset` streams conversational dialogue pairs (e.g. instruction tuning corpora) directly into CARTAN memory records.
  2. **Format Scaffolding**: Applies prompt formatting templates (`<start_of_turn>user\n...<end_of_turn>\n<start_of_turn>model\n...<end_of_turn>`).
  3. **Instruction Update Loop**: Executes multi-epoch training passes updating attention projection adapters and MLP feedforward weights, validating target loss convergence.

---

## Phase 4: Multimodal Computer Vision & Desktop Perception
- **Modules**: [`src/std/vision.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/vision.cl), [`tools/read_screen_ocr.cs`](file:///C:/Users/rich-/source/repos/CARTAN/tools/read_screen_ocr.cs), [`Projects/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/chat.cl)
- **CLI / REPL Trigger**: `/screen`, `<tool_call:read_screen/>`
- **Pipeline Architecture**:
  1. **Image Ingestion**: Loads raw pixel buffers into native CARTAN `Image` structures (`vision_create_image`).
  2. **Spatial Resizing & Normalization**: Executes hardware-accelerated bilinear spatial resizing (`vision_resize_bilinear`) and RGB tensor normalization (`vision_normalize`).
  3. **Desktop Screen Capture & OCR**:
     - Win32 GDI screen capture attaches to the active desktop session (`winsta0\default`).
     - Drives the native Windows Runtime optical character engine (`Windows.Media.Ocr.OcrEngine`) via `tools/read_screen_ocr.exe`.
     - Returns structured JSON lines containing recognized text lines, bounding boxes, and coordinates for zero-latency perceptual reasoning.

---

## Phase 5: 42-Layer Sovereign Manifold, 8 Lie Streams & Sasaki Brainstem MoE
- **Modules**: [`Projects/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/chat.cl), [`Projects/geomind/streams.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/streams.cl), [`Projects/geomind/moe.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/moe.cl), [`src/std/transformer.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/transformer.cl), [`src/std/wgpu.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/wgpu.cl)
- **Hardware Acceleration & Memory Architecture**:
  - **Manifold Shape**: 42 transformer layers, hidden dimension $D = 2560$, intermediate dimension $D_{ffn} = 10240$, 16 query heads ($D_h = 256$), 8 key/value heads (GQA), 262,144 vocabulary.
  - **WebGPU INT4 Residency**: 35 standard layers (46,711,872 bytes each) + 7 global layers (53,277,760 bytes each) = exactly 2,007,859,840 bytes ($\approx 1.87\text{ GiB}$) resident in GDDR6 VRAM across persistent bind groups.
  - **Double-Buffered GDDR6 Staging**: Asynchronous activation readback using ping-pong buffers (`g_wgpu_staging_buf_0` / `g_wgpu_staging_buf_1`) via `wgpuBufferMapAsync`.
  - **Pinned Contiguous KV Cache**: Pinned heap allocation ($24 \times L \times \text{max\_seq} \times 1024 \times 4\text{ B}$) supporting up to 128k context with zero reallocation churn.
  - **AVX2 SIMD Fallback**: 8-thread worker pool executing INT8/INT4 SIMD dot products (`cartan_simd_dot_i8_f32`).
- **Mathematical Formulations**:
  1. **8 Lie Subgroup Streams**:
     Token representations are projected through 8 maximal Lie subgroups with rank-64 SVD adapters:
     - Stream 0: $\text{SO}(16)$ Orthogonal Metric: $y_i = x_i / \sqrt{k_w(0)}$
     - Stream 1: $E_7 \times \text{SU}(2)$ SSM Memory Recurrence: $s_i^{(t)} = s_i^{(t-1)} e^{-0.05 k_w} + x_i (1 - e^{-0.05 k_w})$
     - Stream 2: $E_6 \times \text{SU}(3)$ Spectral DCT: $y_i = x_i (0.5 + 0.5 \cos(\omega k_w))$
     - Stream 3: $\text{SU}(9)$ Hyperbolic Poincaré Metric: $y_i = \tanh(x_i) \left(0.5 + \frac{1}{1 - u^2}\right)$
     - Stream 4: $F_4 \times G_2$ Homological Laplacian: $y_i = x_i - \frac{\Delta x_i}{k_w(4)}$
     - Stream 5: $\text{SO}(10) \times \text{SU}(4)$ Eikonal Ray Retraction: $y_i = \frac{x_i}{\sqrt{1 + k_w(5) x_i^2}}$
     - Stream 6: $\text{SU}(5) \times \text{SU}(5)$ Heat Kernel Diffusion: $y_i = x_i + \frac{0.1}{k_w(6)} \Delta x_i$
     - Stream 7: $\text{SU}(3)^3$ Triality Cyclic Rotation: $y_i = x_i \cos(\pi/3) - x_{i+1} \sin(\pi/3)$
  2. **Sasaki Phase-Space Dynamic MoE Routing**:
     Evaluated at Layer 24 tangent bundle $T\mathcal{M} = (h_{24}, \dot{h}_{24}) \in \mathbb{R}^{5120}$ using Finsler-Randers metric distance:
     $$d_{\text{Sasaki}}^2 = \sum_{d=0}^{D-1} (h_{24, d}^2 + \dot{h}_{24, d}^2) \cdot k_w(d \bmod 8)$$
     $$\text{Gate}_e = \exp\left(-0.05 \cdot \frac{d_{\text{Sasaki}}^2}{D}\right)$$
     Routes tokens across the 16 Freudenthal Magic Square experts ($(\mathbb{R}, \mathbb{C}, \mathbb{H}, \mathbb{O}) \times (\mathbb{R}, \mathbb{C}, \mathbb{H}, \mathbb{O})$) with Fast Path single-expert bypass whenever peak weight $w^* \ge 0.35$.
  3. **Continuous Hopfield Associative Memory**:
     Associative energy relaxation retrieves stable cognitive memories:
     $$E(h) = -\beta^{-1} \log \sum_i \exp(\beta h^T \xi_i) + \frac{1}{2} \|h\|^2$$

---

## Phase 6: Pure-CARTAN SentencePiece BPE Trie Engine (Zero-C Runtime)
- **Module**: [`src/std/tokenizer.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/tokenizer.cl)
- **Zero-C Replacement**:
  Completely eliminates historical C runtime JSON parsers (`c_runtime.c#L1310-L1380`). The tokenizer is 100% self-hosted CARTAN, executing over contiguous memory buffers.
- **Binary Arena Physical Layout (`Projects/geomind/trainingdata/geomind_vocab_262k.bin`)**:
  - **Total File Size**: **12,957,193 bytes (~12.36 MiB / 12.96 MB)**
  - **Vocabulary Size**: **262,144 tokens**
  - **Node Count**: **600,386 nodes**
  - **Header (16 bytes)**:
    - `0..3`: Magic `0x47454D41` (`GEMA`)
    - `4..7`: `vocab_size: u32` (262,144)
    - `8..11`: `node_count: u32` (600,386)
    - `12..15`: Reserved padding
  - **Trie Nodes Arena (Offset `16`, Size: $600,386 \times 16\text{ B} = 9,606,176\text{ B}$)**:
    Each node occupies **16 bytes (32-bit aligned)**:
    - `+0.0`: `byte_val: u8` (with 3 bytes alignment padding)
    - `+4.0`: `token_id: i32`
    - `+8.0`: `child_head: i32` (`first_child`)
    - `+12.0`: `next_sibling: i32`
  - **Offset Table Arena (Offset `16 + 9,606,176`, Size: $262,144 \times 4\text{ B} = 1,048,576\text{ B}$)**:
    Direct `u32` byte offsets pointing to token strings in the string pool.
  - **String Pool Base (Offset `10,654,768`, Size: 2,302,425 bytes)**:
    Contiguous null-terminated UTF-8 strings.
  - **Execution Characteristics**:
  - **Ingress Encoding (`bpe_encode`)**: Traverses binary Trie child pointers per UTF-8 byte using greedy longest-match prefix matching, with seamless fallback to byte-fallback tokens (`<0xXX>`). Zero heap allocations during node traversal.
  - **Egress Decoding (`bpe_decode_token`)**: Direct $\mathcal{O}(1)$ array lookup into `g_bpe_offsets_base`, dereferencing the string pointer directly from the pre-loaded string pool.

---

## Phase 7: Tier 2 Cognitive Memory & Relational Entity Graph (NSES)
- **Modules**: [`src/std/sqlite_vec.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/sqlite_vec.cl), [`src/std/cargraph.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/cargraph.cl), [`src/std/nses_pipeline.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/nses_pipeline.cl), [`Projects/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/chat.cl)
- **Architecture**:
  - **10 Cognitive Domains**: Stored in SQLite WAL mode (`geometry_registry.db`):
    1. `CORE_IDENTITY`
    2. `WORLD_TOPOLOGY`
    3. `MATH_PHYSICS`
    4. `TOOLS_AND_CAPABILITIES`
    5. `EPISODIC_EXPERIENCES`
    6. `WORKING_CONTEXT`
    7. `BELIEFS_AND_VALUES`
    8. `AFFECTIVE_STATE`
    9. `LANGUAGE_AND_STYLE`
    10. `USERS_AND_RELATIONSHIPS`
  - **Dynamic JIT Context Grounding**:
    - Startup prefill constrained to $\le 30$ tokens (19 tokens for recognized interlocutors, 25 tokens for unverified guests), dropping prompt bloat by >85%.
    - Point queries retrieve personal attributes (pet, birthday, occupation, location) on-demand only when personal keywords are present.
    - Tool schemas (176 tokens) are suppressed on pure conversational turns and loaded JIT only when tool execution intent is detected.

---

## Phase 8: Interactive REPL, Non-Blocking Async Polling & Agentic Tool Execution
- **Modules**: [`Projects/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/main.car), [`Projects/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/chat.cl)
- **CLI Flag**: `geomind.exe --chat`
- **Execution Architecture**:
  1. **Non-Blocking CRT Polling**: During autoregressive decode, the engine checks CRT `_kbhit()` every step ($< 1\ \mu\text{s}$ overhead). Pressing `/` triggers immediate asynchronous generation abort, resets transient buffers, and returns control to the REPL.
  2. **15-Command Interactive REPL**:
     Full slash command catalog (`/help`, `/think`, `/telemetry`, `/stream`, `/color`, `/anim`, `/whoami`, `/register-face`, `/screen`, `/browse`, `/read`, `/write`, `/exec`, `/ls`, `/exit`).
  3. **Agentic Tool Dispatch Loop**:
     When generation produces `<tool_call:name args.../>`, the CARTAN runtime parses arguments, dispatches genuine OS operations (reading files, writing files, browsing web via curl, executing shell commands, capturing screen OCR), and injects `<tool_response>` back into the manifold for immediate reasoning without leaving the session.

---

## Summary Matrix of Pipeline Modes

| Mode / Action | CLI Flag | Source Engine | Primary Routine | Acceleration |
| :--- | :--- | :--- | :--- | :--- |
| **Interactive Chat** | `geomind.exe --chat` | [`Projects/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/main.car), [`chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/chat.cl) | `geomind_chat_interactive_loop` | WebGPU INT4 / AVX2 SIMD |
| **SLERP Weight Merging** | `geomind.exe --merge-slerp` | [`src/std/fusion.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/fusion.cl), [`merge_model_weights.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/merge_model_weights.cl) | `fusion_slerp_tensors` | AVX2 SIMD / Zero-Copy Mmap |
| **Teacher Distill** | `geomind.exe --train-distill` | [`src/std/distill.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/distill.cl), [`train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/train.cl) | `geomind_distill_train_run` | AVX2 Thread Pool |
| **Cloze Distill** | `geomind.exe --train-cloze` | [`Projects/geomind/cloze_engine.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/cloze_engine.cl), [`train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/train.cl) | `geomind_train_streaming_steady_state` | WebGPU WGSL / AVX2 |
| **Supervised Fine-Tuning**| `geomind.exe --train-sft` | [`src/std/hub.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/hub.cl), [`sft_train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/sft_train.cl) | `geomind_sft_train_step` | AVX2 Thread Pool |
| **Pre-Training (CE)** | `geomind.exe --train-ce` | [`Projects/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/train.cl) | `geomind_train_streaming_steady_state` | WebGPU WGSL / AVX2 |
| **WebGPU Causal Train** | `geomind.exe --train-webgpu` | [`Projects/geomind/webgpu_causal_engine.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/webgpu_causal_engine.cl) | `webgpu_run_causal_training_pipeline`| WebGPU Compute Shaders |
| **Metacognitive Sleep** | `geomind.exe --sleep` | [`Projects/geomind/sleep.car`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/sleep.car) | `cartan_sleep_consolidate_cycle` | AVX2 Thread Pool |
| **AZR Self-Play** | `geomind.exe --azr-selfplay` | [`Projects/geomind/azr_engine.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/azr_engine.cl) | `geomind_azr_run_selfplay` | Subprocess `cartanc.exe` AST |
