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

## ⏳ PHASE 5: Model Stitching & Intelligence Absorption
**Goal:** The "Zero-Day" strategies for fusing and hijacking open-source models natively.
- [ ] **Cross-Tokenizer Projections:** Native compilation of `Span Alignment` and the translation projection matrix ($W$) between differing vocabulary sizes (e.g., Llama vs Cartan).
- [ ] **Manifold Affine Grafting:** Implementing `absorb_layer_weights(donor, local)` to extract subnetworks and stitch their residual streams natively via affine warping.

---

## ⏳ PHASE 6: Agentic Operating System (CartanOS)
**Goal:** Give the compiled model secure, native access to the system.
- [ ] **Capabilities-Based Execution:** `@agent_accessible` function hooks that the model's output layer can natively trigger.
- [ ] **Continuous Self-Improvement (Hot-Swapping):** Allowing the model to compile and load `.aer` instruction blocks to alter its own routing graph without restarting the binary.

---

## 🛑 SHELVED / FUTURE: Distributed Scaling (Data Center as a Chip)
**Goal:** Move away from Python networking wrappers (Megatron-LM) to compiled RDMA hardware calls. (Shelved pending hardware testing capabilities).
- [ ] **Mesh & Shard Primitives:** Syntax for `mesh ClusterGrid` and `shard(ClusterGrid, axis=1)`.
- [ ] **Fused Collective Operations:** Emitting LLVM instructions that natively interleave matrix computation with `AllReduce` and `AllGather` network transfers.
- [ ] **Zero-Copy DMA Weight Streaming:** Loading massive parameters asynchronously into `Buffer_B` while calculating on `Buffer_A`.
