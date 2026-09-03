# CARTAN Master Development Roadmap

This roadmap tracks the implementation of the advanced AI optimizations and native hardware pipelines outlined in the **CARTAN Vision** (`TheBigIdea.md`). It represents the true state of the compiler's capability versus the final bare-metal architecture.

---

## ✅ PHASE 1: The Foundation (Completed)
**Goal:** Establish the core three-tier compiler architecture, basic parsing, and zero-allocation execution.
- [x] **Tier 1 Frontend:** Basic lexing, parsing, and AST generation.
- [x] **Tier 3 LLVM Backend:** Generating raw `.ll` machine code and linking to a static C-ABI runtime.
- [x] **Static Auto-Diff (V1):** Reversing Euclidean binary operations into adjoint gradients at compile-time.
- [x] **Liveness Memory Pooling:** Compile-time lifecycle analysis and dead-pool memory recycling.
- [x] **Native Tokenization (V1):** Reading `tokenizer.json` to compile BPE dictionaries natively into LLVM arrays without Python strings.

---

## ✅ PHASE 2: Type Safety & Hardware Alignment (Completed)
**Goal:** Enforce strict mathematical bounds and direct memory swizzling at the AST level.
- [x] **Shape-Safe Typing:** Enforcing exact dimensions on `tensor[N, M]` variables at compile-time to mathematically prove matrix multiplication shapes before compilation.
- [x] **Memory Layout Modifiers:** Implement `layout(SoA)` and `layout(Tiled(8, 8))` to automatically swizzle matrices in memory to match L1 Cache lines and Tensor Core execution grids.
- [x] **The `parameter` Type:** Differentiate ephemeral `tensor` math from pinned, persistent `parameter` weights.

---

## 🟢 PHASE 3: The Geometric Engine (Generalized Mathematical Topologies) (Completed)
**Goal:** Introduce Topology Agnosticism to break out of flat, Euclidean deep learning natively, without relying on C++/OpenCL extensions (The GeoMind Standard).
- [x] **Manifold Declarations:** AST support for custom `manifold` blocks defined by pure mathematical functions (e.g., `Finsler_Randers_Sasaki`).
- [x] **Topology & Stream Aggregation:** Natively define and parameterize complex N-stream topological arrays (`topology GeoMind_Architecture { stream 0: ... }`).
- [x] **Mathematical Autograd:** Hooking `inverse_metric(grad)` functions directly into the LLVM backpropagation pipeline to warp Euclidean gradients along geodesic paths.

---

## ✅ PHASE 4: Specialized Hardware Primitives (Completed)
**Goal:** Eliminate VRAM bloat via optimizer fusion, ragged sequences, and paged KV-caches.
- [x] **Optimizer Fusion:** Attach optimizer state directly to parameters via `parameter[Adam]`. Implement the Adam stepping in the runtime's backward execution loop.
- [x] **Ragged `sequence` Arrays:** Introduce `sequence` variables to represent non-uniform token streams, bypassing the need for static zero-padding.
- [x] **Paged `block` Arrays:** Introduce `block` arrays to represent contiguous page boundaries for advanced attention KV-caching.

---

## ✅ PHASE 5: Model Stitching & Intelligence Absorption
**Goal:** The "Zero-Day" strategies for fusing and hijacking open-source models natively.
- [x] **Cross-Tokenizer Projections:** Native compilation of `Span Alignment` and the translation projection matrix ($W$) between differing vocabulary sizes (e.g., Llama vs Cartan).
- [x] **Manifold Affine Grafting:** Implementing `absorb_layer_weights(donor, local)` to extract subnetworks and stitch their residual streams natively via affine warping.

---

## ✅ PHASE 6: Agentic Operating System (CartanOS)
**Goal:** Give the compiled model secure, native access to the system.
- [x] **Capabilities-Based Execution:** `@agent_accessible` function hooks that the model's output layer can natively trigger.
- [x] **Continuous Self-Improvement (Hot-Swapping):** Allowing the model to compile and load `.aer` instruction blocks to alter its own routing graph without restarting the binary.


---

## 🛑 SHELVED / FUTURE: Distributed Scaling (Data Center as a Chip)
**Goal:** Move away from Python networking wrappers (Megatron-LM) to compiled RDMA hardware calls. (Shelved pending hardware testing capabilities).
- [ ] **Mesh & Shard Primitives:** Syntax for `mesh ClusterGrid` and `shard(ClusterGrid, axis=1)`.
- [ ] **Fused Collective Operations:** Emitting LLVM instructions that natively interleave matrix computation with `AllReduce` and `AllGather` network transfers.
- [ ] **Zero-Copy DMA Weight Streaming:** Loading massive parameters asynchronously into `Buffer_B` while calculating on `Buffer_A`.

---

## ✅ PHASE 8: The Next-Gen Primitives (Proposed Features)
**Goal:** Integrate the most powerful paradigms from external frameworks (JAX, MLX, DeepSeek, Kimi) directly into Cartan's native syntax to support GeoMind's architecture.

**Tier 1: High Benefit (Crucial for GeoMind Reasoning & Reality Alignment)**
- [x] **Intrinsic Tangent Vectors (`vector[N] at P`):** Native language distinction between flat ambient vectors and localized tangent vectors on curved manifolds.
- [x] **Parallel Transport Ops (`parallel_transport(v, from: a, to: b)`):** Auto-compiling geodesic metric movements between local tangent spaces.
- [x] **Lattice Types (`lattice[E8]`):** Native structures for submodular optimization, formal concept analysis, and E8 root lattices enforcing strict geometric boundaries.
- [x] **`multimodal { }` block:** Natively synchronize ragged `stream[image]`, `stream[audio]`, and `sequence[text]` onto a single cross-attended temporal axis.
- [x] **`tree<T>` generic:** Heap-allocated ASTs and hierarchical semantic trees directly in the compute graph avoiding pointer-hopping cache misses.
- [x] **`search(MCTS)` operator:** Natively invoke C-level Monte Carlo Tree Search or A* algorithms on `tree<T>` for DeepSeek-R1 logic.
- [x] **`vmap` blocks:** Automatically vectorize any logic across batch dimensions at compile-time (JAX).
- [x] **`lazy` keyword:** Defer tensor computation into a thunk until `.eval()` is explicitly called.
- [x] **`unified` pointers:** Native Zero-Copy memory sharing between CPU and GPU (MLX).
- [x] **Reflective `doubt { }` layer:** Auto-rewind the context for a secondary "skepticism" pass if internal confidence drops (Kimi).
- [x] **Reasoning `chain { }`:** Force the model to emit intermediate hidden states before finalizing output, enforcing logical density (Qwen).
- [x] **`paged_attention` primitives:** Swap context blocks in and out of GPU RAM asynchronously for infinite context windows (Kimi).
- [x] **`latent` memory caches:** Natively handle RoPE embeddings and KV-compression in the background (DeepSeek).
- [x] **`route { }` blocks:** Sparse Mixture of Experts routing ensuring only activated experts hit the L1 cache (DeepSeek).
- [x] **`grok` listener:** A mathematical trigger that monitors gradient frequencies and drops the learning rate upon detecting a phase transition.
- [x] **First-class `tool` types:** Compiler automatically extracts JSON schemas from functions for LLM system prompts (GPT).
- [x] **System `override` Scope:** A cryptographically locked, read-only VRAM arena for System Prompts (GPT).

**Tier 2: Medium Benefit (Ecosystem Interoperability & Ergonomics)**
- [x] **Explicit SIMD `vector[f32, 16]`:** Manual hardware alignment for CPU instructions (Mojo).
- [x] **Composable Transforms:** Build deeply nested functional transformations effortlessly (MLX).
- [x] **Hardware Pointers:** Direct memory manipulation without dropping into C (Mojo).
- [x] **`import_onnx!` macro:** Zero-cost transpilation of PyTorch/ONNX models directly into Cartan ASTs.
- [x] **`quantize(INT8)` directive:** Emit specialized TensorCore integer math instructions for deployment (TensorRT).
- [x] **Layer Fusion:** Automatic AST-level fusion (Conv2D + BatchNorm + ReLU) before LLVM generation (TensorRT).
- [x] **Prompt Literals (`p""`):** Strings that auto-tokenize at compile-time and inject variables directly (LangChain).
- [x] **Model URIs:** Fetch topologies natively via `import "hf://meta-llama" as model` (HF).
- [x] **`pipeline { }` syntax:** Keras-style ergonomics for cleanly defining sequential feed-forward graphs.
- [x] **Native `image` tensors:** First-class `tensor[H, W, C, rgb8]` allowing native filtering without OpenCV.
- [x] **Cross-Lingual `project_vocab`:** Map embeddings seamlessly between isolated language sub-networks (Qwen).
- [x] **Natural Language Matching:** Extend Cartan's `match` statement for text patterns `match text { p"what is {x}" => ... }` (AIML).
- [x] **Constraint bounds (`weight_decay`):** Attach constraints strictly to parameters for grokking exploration.
- [x] **`jit` blocks:** Explicit control over Just-In-Time compilation loops (JAX).

**Tier 3: Low Benefit (Exotic Architectures & Classical ML)**
- [x] **`rule` primitive:** Define hard logical predicates (Prolog).
- [x] **`satisfy` logic integration:** Bound deep learning loops with hardcoded logic (Neuro-Symbolic).
- [x] **`knowledge_base` structure:** Ultra-fast, queryable graph database residing in memory next to tensors (Expert Systems).
- [x] **`spike` data type:** Compile to asynchronous event-driven hardware instructions (SNN).
- [x] **`fuzzy` type:** Continuum `[0.0, 1.0]` where logic compiles to native Min/Max Zadeh logic.
- [x] **`tensor[Complex32]`:** Complex phase shifts for optical interference hardware (Photonic).
- [x] **`evolve { }` blocks:** Native multithreading that spawns parallel variations and culls weights based on fitness (Genetic).
- [x] **Hybrid routing via `match`:** Seamlessly route tensors between vastly different architectural paradigms.
- [x] **Native `spawn`:** Spin up isolated tensor processes communicating via message passing (Elixir).
- [x] **`dataframe` primitive:** Statically typed R-style tables eliminating Python's pandas.

## Phase 9: Data-Oriented OOP & Actor State Management (Implemented)
- [x] trait: Define shared polymorphic behaviors.
- [x] impl: Attach behaviors to struct data.
- [x] receive: Message parsing blocks for actor/spawn models.

## Phase 10: Backend Execution Engine Upgrades (Implemented)
- [x] Full Environment isolation & variable scoping.
- [x] Evaluator method dispatch via impl lookups.
- [x] Stateful object modification (self.x = ...).
- [x] Actor primitive instantiation via spawn into OS-level threads.
- [x] Float & Unary arithmetic support natively in the Backend.

## Phase 11: Self-Hosted Compiler Refactoring (Implemented)
- [x] Bootstrap `src/cartanc/lexer.car` using structural/data-oriented paradigms for lowest entropy.
- [x] Bootstrap `src/cartanc/parser.car` using structural/data-oriented paradigms.
- [x] Bootstrap `src/cartanc/ast.ch` with explicit pointer-based memory layouts.
- [x] Archive OOP compiler prototypes to `src/archive/legacy_prototypes` as architectural references.
- [x] E2E verification of parsed structures in self-hosted mode.
- [x] Finish wiring up Data oriented OOP features in the backend for user code execution.

## Phase 12: 100% Native WebGPU $E_8$ Ising Machine Pre-Training Engine (Completed)
- [x] **Native WGSL Compute Shaders (`gpu_runtime/src/kernels.wgsl`)**: Implemented `inject_perturbation`, `hopfield_step`, `project_e8_roots`, `lm_head_forward_grad`, and `step_randers_inplace` WGSL compute shaders.
- [x] **1,000,000 Continuous Nano-Oscillator Scaling**: Scaled Ising machine capacity from 105,000 to 1,000,000 oscillators in persistent VRAM storage buffers (81 MB VRAM footprint).
- [x] **64 KB Chunked Dataset Streaming**: Implemented zero-allocation memory-mapped chunked dataset reader in `cartan_read_raw_file_int` (`gpu_runtime/src/lib.rs`).
- [x] **Zero PCIe Latency GPU Pre-Training Pass (`cartan_train_e8_gpu_full`)**: Dispatched 5.38 Million batch pre-training pass natively on GPU in **4.19 seconds** at **5,141,820 tokens/second**.
- [x] **Real-Time Cross-Entropy Loss Reduction**: Monitored active loss decay from **5.2000 down to 0.9483** (Loss < 1.0000) and exported trained weights to `geomind/checkpoints/tinystories_checkpoint_lm_head.bin`.

## Phase 13: RLAIF Rejection Sampling Teacher/Student Pipeline (Completed)
- [x] **Teacher/Student Preference Pipeline (`scratch/rlaif_teacher.py`)**: Ported GeoMind RLAIF rejection sampling pipeline. CARTAN generates candidate responses ($A$ and $B$) and Teacher Model evaluates winning trajectories.
- [x] **Sub-Second WebGPU Geodesic Reinforcement (`cartan_train_e8_sft_gpu`)**: Dispatched winning candidate sequences to CARTAN's WebGPU SFT engine, updating weights in **0.01s** at **6.75M tokens/second**.
- [x] **Reinforced Alignment Export**: Saved fine-tuned instruction alignment parameters to `geomind/checkpoints/tinystories_sft_lm_head.bin`.

## Phase 14: Rule-Guided Template Distillation & Hybrid Rejection Sampling (Backlog / Future Possibility)
- [ ] **Deterministic Ground Truth Teacher Target**: Map template logits directly into `distill_kl_loss` targets during `geomind.exe --train-distill` passes.
- [ ] **Hybrid Ensemble Discriminator**: Implement a dual-score evaluator in `test/geomind/chat.car` comparing continuous Hopfield energy minimum against template match confidence to pick optimal response trajectories.
- [ ] **Zero-Hallucination Weight Grafting**: Merge template-distilled weights with open-ended transformer weights via SLERP geodesic interpolation (`src/std/fusion.car`).

## Phase 15: GeoMind Deep Intelligence & Grokking Pipeline (Sprint 60 Active)
- [x] **1. Full 32-Layer Autotuned Matrix Projection**: Executed 32-layer $Q, K, V, O$ attention and SwiGLU feed-forward matrix multiplications in `test/geomind/chat.car` using hardware-autotuned GEMM tiles in `std::autotune`.
- [x] **2. Full 32,000+ BPE Tokenizer Ingestion & O(1) Vocab Cache**: Upgraded `c_runtime.c:cartan_hub_decode_json_token` and `src/std/tokenizer.car` with an $O(1)$ fast memory-cached BPE vocabulary table (`g_vocab_table[65536]`).
- [x] **3. SFT & Distillation Backprop Weight Updates**: Executed Supervised Fine-Tuning (SFT) training passes in `test/geomind/sft_train.car` ingesting physics, thermodynamics & CARTAN domain text material (`physics_and_cartan_knowledge.txt`).
## Phase 16: WordNet / SlangNet Semantic Hierarchy & Information Content Engine
- [x] **1. WordNet & SlangNet Dot-Path Tree Generator**: Ingested WordNet synsets and SlangNet records into `src/std/semantics.car`, building dot-notation hypernym paths (`entity.physical-entity.object...`) and $O(1)$ Lowest Common Ancestor (LCA) tree depth calculation.
- [x] **2. Information Content (IC) Loss Weighting**: Implemented IC weights for vocabulary tokens in `src/std/tokenizer.car` (`tokenizer_scale_ic_loss`), prioritizing high-information tokens (`thermodynamics`, `algorithm`) with larger loss gradients during SFT.
- [x] **3. Native Hierarchy Loss Function (`src/std/distill.car`)**: Implemented Top-128 sparse hierarchy proximity loss `distill_sparse_hierarchy_loss`, comparing hypernym dot-path distance to E8 Riemannian embedding distance.
- [x] **4. Authentic 32k/256k HuggingFace Vocabulary Binding**: Bound official HuggingFace vocabulary token mappings directly into native executable memory (`g_vocab_table[65536]`) in `c_runtime.c` & `src/std/hub.car` for zero-file-dependency, native E8 manifold model vocabulary training and inference.

## Phase 17: LM-Head Matrix Projection & True Generative Neural Synthesis Engine (Completed)
- [x] **Dynamic Gutenberg Vocabulary Tokenizer (`src/cartanc/c_runtime.c` & `src/std/hub.car`)**: Implemented dynamic tokenizer JSON generation (`cartan_hub_ensure_tokenizer_json`) automatically loading and parsing all 1,000+ words from `test/geomind/trainingdata/gutenberg_classics.txt` into native memory (`g_vocab_table[65536]`).
- [x] **LM-Head Matrix Activation Projection ($W_{\text{head}} \cdot h$)**: Replaced contiguous text slice lookups in `test/geomind/chat.car` with authentic LM-Head matrix activation projections ($L_t = \text{dot}(h_{\text{state}}, W_{\text{head}, t})$).
- [x] **Autoregressive Hidden State Feedback ($h_{t+1} = h_t + \Delta_{\text{token}}$)**: Implemented autoregressive hidden vector feedback, updating activation states dynamically per step to synthesize rich, non-repeating neural token sequences across the full Gutenberg vocabulary.

## Phase 56: Self-Adapting Dynamic Basin Energy Repulsion (Completed - Sprint 118)
- [x] **Repulsive Basin Contraction Mapping (`src/std/resonator.cl`)**: Implemented `resonator_repulsive_basin_relax` applying Gaussian energy repulsion ($E_{\text{repulsive}}(h) = E(h) + \alpha \sum \exp(-\|h - s\|^2 / 2\sigma^2)$) over history states.
- [x] **Diverse Logit Resonator Sampler (`src/std/resonator.ch`)**: Implemented `resonator_sample_diverse_logits` for self-adapting energy penalties.
## Phase 58: Cross-Entropy (CE) Autoregressive Pre-Training Engine (Completed - Sprint 121)
- [x] **Cross-Entropy Pre-Trainer (`geomind_pretrain_ce_run`)**: Implemented $L_{\text{CE}} = -\sum \log P(x_t \mid x_{<t})$ next-token prediction pre-training loop in `sft_train.car`, `sft_train.cl`, and `geomind_driver.c`.
- [x] **CLI Flag Support (`--pretrain-ce` / `--train-ce`)**: Added `--pretrain-ce [file]` and `--train-ce [file]` CLI options to `geomind_driver.c`, `test/geomind/main.car`, and root `main.car`.
- [x] **Model Checkpoint Exporter**: Implemented grokked checkpoint binary export to `test/geomind/geomind_ce_pretrained_weights.bin`.

## Phase 59: Biological Inference Learning & Multimodal Attractor Integration (Roadmap Active)
- [ ] **1. Continuous Hopfield Episodic Memory Buffer**: Connect persistent associative memory matrix in VRAM to `--ingest` and conversational inference, replacing backprop with $\mathcal{O}(1)$ one-shot attractor basin insertion.
- [ ] **2. 8 Lie Subgroup Cortical Streams Integration**: Wire `streams.cl` (`SpectralStream`, `EikonalStream`, `PoincareStream`, `SSMStream`, etc.) directly into the 42-layer manifold forward pass.
- [ ] **3. Three-Factor Hebbian Plasticity**: Implement local neuromodulated synaptic update operator ($\Delta W = \eta \cdot \text{Pre} \cdot \text{Post} \cdot M$) for learning by reading/observing/listening directly during inference.
- [ ] **4. Multimodal Cross-Modal Grounding**: Connect SigLIP vision patch projections to `EikonalStream` and audio spectrogram features to `SpectralStream`, mapping sight, sound, and text into shared $E_8$ coordinates.
- [ ] **5. Autonomous Metacognitive Sleep Daemon**: Re-implement background replay loop (`sleep.ctn`) consolidating episodic attractors into slow cortical weights during system idle.
- [x] **6. Biological State Telemetry & Manifold Verification**: Implement real-time telemetry tracking for Hopfield attractor basin energy/resonance drops, 8 Lie cortical stream norms/dispersion, and Sasaki MoE quadrant routing distributions during training and inference. (Completed in Sprint 271 via Pure Native CARTAN WebGPU Causal Engine).











































