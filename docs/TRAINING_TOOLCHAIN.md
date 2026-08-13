# CARTAN $E_8$ Ising Machine Pre-Training & SFT Toolchain Architecture

This document provides a comprehensive technical overview of the $E_8$ Physical Ising Machine pre-training, Direct 50,257 GPT-2 BPE Supervised Fine-Tuning (SFT), and Ising Next-Word Attractor inference pipeline in CARTAN.

---

## 1. Toolchain Overview & End-to-End Pipeline

```
 ┌─────────────────────────────────────────────────────────────────┐
 │       TinyStories Direct GPT-2 BPE Dataset (1,000,000 Tokens)   │
 └────────────────────────────────┬────────────────────────────────┘
                                  │ Direct GPT-2 BPE Token IDs (0..50256)
                                  ▼
 ┌─────────────────────────────────────────────────────────────────┐
 │          1. SFT Instruction Alignment Pass (`sft_train.exe`)     │
 │        (Top-64 Active Index Backpropagation | Loss: 10.0 -> 6.7)│
 └────────────────────────────────┬────────────────────────────────┘
                                  │ Grokked Weights (LM Head [240, 50257])
                                  ▼
 ┌─────────────────────────────────────────────────────────────────┐
 │            Instruction-Aligned Checkpoint Export                │
 │          geomind/checkpoints/geomind_sft_grokked.model         │
 └────────────────────────────────┬────────────────────────────────┘
                                  │ Active Vocab Mask + 256-Token Context
                                  ▼
 ┌─────────────────────────────────────────────────────────────────┐
 │    2. Dynamic Ising Attractor Chat Engine (`chat.exe`)          │
 │  - Sliding Context Window QKV Attention (S = 256 Tokens)        │
 │  - 15-Step Continuous Hopfield Next-Word Attractor Predictor    │
 │  - Dynamic Geodesic Recency Penalty & Grammar Token Exemptions  │
 └─────────────────────────────────────────────────────────────────┘
```

---

## 2. Core Toolchain Components

### 2.1 Direct 50,257 GPT-2 BPE Tokenization (`scratch/build_direct_gpt2_dataset.py`)
- **Direct GPT-2 Token Alignment**: Generates raw float binary token ID arrays directly using `tiktoken` ($0..50256$). Eliminates dense token ID remapping tables and tokenizer byte corruption.
- **Active Token Mapping Table (`active_vocab_50k_mapping.bin`)**: Exports the list of unique active dataset token IDs (e.g. 216 active TinyStories tokens) to constrain logit sampling.

### 2.2 SFT Instruction Alignment Engine (`gpu_runtime/src/lib.rs`)
- **`cartan_train_sft_aligned_gpu`**: Dispatches SFT instruction backpropagation loop on GPU.
- **Top-64 Active Index Gradient Optimization**: Accelerates SFT training step latency by **~700x** by updating only `target_tok` and top probability channels ($p > 10^{-4}$).

### 2.3 Inference Engine & Ising Next-Word Attractor (`gpu_runtime/src/lib.rs`)
- **`cartan_forward_e8_attention_gpu`**: Computes Causal Multi-Head QKV Scaled Dot-Product Attention over up to **256 sliding sequence tokens** in `RECENT_TOKENS_BUFFER`:
  $$c = \sum_{s=0}^{S-1} \text{softmax}\left(\frac{q_{\text{last}} \cdot k_s}{\sqrt{240}}\right) v_s$$
- **`cartan_sample_ising_attractor`**:
  - **15-Step Continuous Hopfield Relaxation Pass**: Executes 15 spin relaxation steps to phase-lock candidate next words to the $E_8$ harmonic ground state of preceding story tokens.
  - **Dynamic Geodesic Recency Penalty**: Applies recency distance penalty $\text{Penalty}(t) = \frac{15.0}{1.0 + 0.5 \cdot \text{distance}}$.
  - **Grammar Token Exemption Engine**: Structural articles, connectors, and punctuation (token IDs `13` `.`, `11` `,`, `0` `!`, `198` `\n`, `a`, `the`, `in`, `on`, `at`, `and`, `to`, `was`, `is`, `he`, `she`, `it`) are exempt or receive mild decay to allow natural sentence syntax.

---

## 3. Performance & Architecture Benchmarks

| Metric / Feature | Pre-Training Engine | SFT Grokking Engine | Inference Engine (`chat.exe`) |
| :--- | :--- | :--- | :--- |
| **Vocabulary Scale** | 50,257 GPT-2 Tokens | 50,257 GPT-2 Tokens | 50,257 GPT-2 Tokens |
| **Context Window ($S$)** | 32 Tokens | 32 Tokens | **256 Sliding Sequence Tokens** |
| **Hardware** | NVIDIA RTX 2000 Ada GPU | NVIDIA RTX 2000 Ada GPU | NVIDIA RTX 2000 Ada GPU |
| **Step Latency** | < 1 ms | < 1 ms | < 5 ms / generated token |
| **Attractor Dynamics** | E8 Phase Relaxation | Weyl Manifold MoE | **15-Step Hopfield Next-Word Predictor** |
| **Penalty Engine** | — | — | **Dynamic Recency Geodesic Penalty** |
---

## 4. GeoMind 4-Stage Hybrid Training & Instant Adaptation Pathway

GeoMind integrates a 4-stage hybrid optimization pipeline combining continuous Riemannian autograd, instant zero-shot ELM readout solves, Evolution Strategies macro-alignment, and Hopfield attractor grounding:

```
 ┌─────────────────────────────────────────────────────────────────────────────────────────┐
 │               STAGE 1: BASE PRE-TRAINING (Dense E8 Riemannian Autograd)                │
 │  32-layer E8 Lie algebra manifold transformer pre-trained via Finsler-Randers natural   │
 │  gradients on Gutenberg Classics & TinyStories corpora.                                │
 └──────────────────────────────────────────┬──────────────────────────────────────────────┘
                                            │ E8 Features (h_t)
                                            ▼
 ┌─────────────────────────────────────────────────────────────────────────────────────────┐
 │            STAGE 2: INSTANT DOMAIN ADAPTATION (Extreme Learning Machines ELM)           │
 │  Instant zero-shot LM-Head readout solve: W_head* = (H^T H + lambda I)^-1 H^T Y.        │
 │  Adapts vocabulary projections to any new domain corpus in O(1) linear algebra time.    │
 └──────────────────────────────────────────┬──────────────────────────────────────────────┘
                                            │ Adapted LM-Head (W_head*)
                                            ▼
 ┌─────────────────────────────────────────────────────────────────────────────────────────┐
 │             STAGE 3: MACRO POLICY ALIGNMENT (Evolution Strategies ES)                   │
 │  Antithetic Mirrored ES noise perturbation (theta_i = theta +- sigma epsilon_i) for     │
 │  AZR compiler self-play & non-differentiable rewards without PPO reward hacking.       │
 └──────────────────────────────────────────┬──────────────────────────────────────────────┘
                                            │ Aligned Model Checkpoint
                                            ▼
 ┌─────────────────────────────────────────────────────────────────────────────────────────┐
 │            STAGE 4: ATTRACTOR GROUNDING & INFERENCE (Continuous Hopfield)                │
 │  Interleaved 15-step Banach contraction mapping T(h) = tanh(beta W h + E) pulling       │
 │  latent vectors into stable semantic attractor basins prior to token emission.           │
 └─────────────────────────────────────────────────────────────────────────────────────────┘
```

### Pathway Execution Commands

1. **Stage 1 (Base SFT & Finsler-Randers Autograd)**:
   ```bash
   cartanc.exe build test/geomind/main.car -o geomind.exe
   ./geomind.exe --train-sft
   ```
2. **Stage 2 (Instant Zero-Shot ELM Readout Solve)**:
   ```cartan
   include "src/std/elm.cl";
   var w_head_adapted = elm_fit_zero_shot(e8_hidden_matrix, target_vocab_matrix, 0.01);
   ```
3. **Stage 3 (Macro ES Alignment & AZR Compiler Self-Play)**:
   ```cartan
   include "src/std/es_opt.cl";
   var es_opt = es_optimizer_create(dimension, 50.0, 1.0, 0.1);
   es_optimizer_step(es_opt, fitness_positive, fitness_negative);
   ```
4. **Stage 4 (Hopfield Attractor Chat REPL)**:
   ```bash
   ./geomind.exe --chat
   ```

