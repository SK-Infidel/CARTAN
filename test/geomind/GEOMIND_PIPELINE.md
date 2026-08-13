# GeoMind Multimodal Architecture & End-to-End Pipeline

## Executive Overview
**GeoMind** is a high-performance, 100% self-contained neural model written entirely in **CARTAN** and compiled to native machine code via `cartanc.exe`. It eliminates two-language runtime overhead by integrating Lie group differential geometry ($E_8$ lattices), Continuous Hopfield energy relaxation, SLERP weight fusion, teacher-student KL divergence distillation, multimodal vision tensor ingestion, and HuggingFace AutoTokenizer decoding directly into CARTAN standard library primitives (`std::hub`, `std::tokenizer`, `std::vision`, `std::fusion`, `std::distill`).

---

## 1. Weight Merging & Geodesic Interpolation (SLERP)
- **Module**: [`src/std/fusion.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/fusion.car), [`test/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car#L60-L75)
- **CLI Flag**: `geomind.exe --merge-slerp`
- **Theory**: Merges separate Safetensors weight matrices along their spherical geodesic manifold:
  $$\Omega = \arccos(W_1 \cdot W_2)$$
  $$\text{SLERP}(W_1, W_2, t) = \frac{\sin((1-t)\Omega)}{\sin\Omega} W_1 + \frac{\sin(t\Omega)}{\sin\Omega} W_2$$
- **Implementation**: Computes dot products, angular distance $\Omega$, and linear vector combinations to fuse model checkpoints into a single weight vector stream.

---

## 2. Teacher-Student KL Divergence Distillation
- **Module**: [`src/std/distill.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/distill.car), [`test/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car#L40-L55)
- **CLI Flag**: `geomind.exe --train-distill`
- **Theory**: Transfers knowledge from a large teacher model to the compact GeoMind student model by minimizing Kullback-Leibler (KL) divergence over Softmax logit distributions at temperature $T$:
  $$\mathcal{L}_{\text{KL}} = T^2 \sum_{i} P_{\text{teacher}}(i) \log\left(\frac{P_{\text{teacher}}(i)}{P_{\text{student}}(i)}\right)$$
- **Implementation**: Runs iterative gradient update loops (`distill_kl_divergence_loss`), decreasing divergence over time.

---

## 3. Supervised Fine-Tuning (SFT) & Dataset Ingestion
- **Module**: [`src/std/hub.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/hub.car), [`test/geomind/sft_train.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/sft_train.car)
- **CLI Flag**: `geomind.exe --train-sft`
- **Pipeline**:
  1. Fetches dataset splits (e.g. `tatsu-lab/alpaca`) directly via HuggingFace Hub REST API (`hub_fetch_dataset`).
  2. Parses dataset JSON sample records into CARTAN memory trees (`hub_load_dataset`).
  3. Executes Supervised Fine-Tuning loops (`geomind_sft_train_step`) updating internal attention weights.

---

## 4. Multimodal Computer Vision Processing
- **Module**: [`src/std/vision.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/vision.car)
- **Pipeline**:
  1. Ingests raw multi-channel image pixels into standard `Image` structures (`vision_create_image`).
  2. Performs hardware-accelerated bilinear spatial resizing (`vision_resize_bilinear`).
  3. Converts image buffers into normalized RGB tensors (`vision_image_to_tensor`, `vision_normalize`).

---

## 5. $E_8$ Riemannian Attention & Hopfield Spin Relaxation
- **Modules**: [`test/geomind/e8_attention_engine.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/e8_attention_engine.car), [`test/geomind/ising_state_machine.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/ising_state_machine.car), [`test/geomind/geometry.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/geometry.car)
- **Theory**:
  - Maps query, key, and value vectors onto the 240-root lattice of the exceptional Lie algebra $\mathfrak{e}_8$.
  - Executes Continuous Hopfield spin relaxation:
    $$s_i^{(t+1)} = \tanh\left(\beta \sum_{j} J_{ij} s_j^{(t)}\right)$$
  - Minimizes energy to reach stable memory recall states.

---

## 6. HuggingFace BPE Tokenizer Decoding & C-Runtime Parser
- **Modules**: [`src/std/tokenizer.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/tokenizer.car), [`src/cartanc/c_runtime.c`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/c_runtime.c#L1310-L1380)
- **Pipeline**:
  1. `cartan_hub_ensure_tokenizer_json` writes/verifies HuggingFace BPE vocabulary definitions on disk (`cache_tokenizer.json`).
  2. `cartan_hub_decode_json_token` parses JSON key mappings directly from C memory, returning string tokens for generated token IDs.

---

## 7. Interactive REPL Chat Pass & Softmax Top-K Sampling
- **Modules**: [`test/geomind/chat.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.car), [`test/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car#L25-L38)
- **CLI Flag**: `geomind.exe --chat`
- **Execution Flow**:
  ```text
  [User Prompt] -> [Prompt Hash & Topic Anchor]
                -> [E8 Lattice Attention Projection]
                -> [Continuous Hopfield Spin Relaxation]
                -> [Softmax Top-K Temperature Sampling]
                -> [HuggingFace Tokenizer Decoding]
                -> [Conversational Dialogue Response]
  ```
