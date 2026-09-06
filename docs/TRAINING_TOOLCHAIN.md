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

---

## 5. Unified 3-Stage Training Pipeline & CLI Reference (`geomind.exe`)

The modern GeoMind training engine consolidates all training pipelines into [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl) under a pure Cartan architecture, providing continuous multi-stage weight inheritance, sliding-window full corpus traversal, automatic checkpoint safety backups, and Ctrl-C interruption rollback.

### 5.1 Training Stages & Default Target Losses

1. **Stage 1: Anchored Cloze Curriculum (`--train-cloze`)**:
   - **Corpus**: `conversational_storytelling_dataset.jsonl` (1.98 MB, 4,279 records).
   - **Default Target Loss**: **`4.20`** (Perplexity $\approx 66.7$).
   - **Purpose**: Rapidly grounds lexical taxonomy units (Noun-Noun pairs, non-reversible binomials, discourse markers, transition bridges) out of random entropy.
2. **Stage 2: Causal Cross-Entropy Narrative Pre-training (`--train-ce` / `--train-pre`)**:
   - **Corpus**: `storytelling_corpus.txt` (7.05 MB multi-genre prose).
   - **Default Target Loss**: **`3.00`** (Perplexity $\approx 20.1$).
   - **Purpose**: Learns rich English grammar, multi-clause syntactic dependencies, and continuous narrative flow.
3. **Stage 3: Supervised Fine-Tuning & Alignment (`--train-sft`)**:
   - **Corpus**: `hf_alpaca_stories.txt` (163 KB dialogue pairs).
   - **Default Target Loss**: **`2.00`** (Perplexity $\approx 7.4$).
   - **Purpose**: Aligns conversational responses and sharpens question-answering focus.

### 5.2 CLI Optimization Flags & Learning Rate Mechanics

All flags are completely optional and feature calibrated defaults. Omitting `-lr` is standard and recommended:

| CLI Flag | Type | Default Value | Description & Mechanics |
| :--- | :--- | :--- | :--- |
| `-epochs` | Float | `500.0` | Maximum number of training epochs to execute. |
| `-target-loss` | Float | Stage-calibrated | Convergence threshold triggering early stopping (`ep >= 10.0`). |
| `-lr` | Float | `0.001` | **Starting Base Learning Rate Ceiling**. Omitting `-lr` uses the optimal default: starts at `0.001`, decays by factor `0.995` each epoch, and clamps at the `0.0001` floor. Learning rate never exceeds this ceiling. |
| `-target` | String | Curated stage path | Custom dataset filepath. |

### 5.3 Checkpoint Safety & Interruption Rollback Protocol

Training state is protected against corruption from aborted runs, system crashes, or manual `Ctrl-C` breaks using an out-of-band marker (`checkpoint_status.txt`):

1. **Clean-Run Safety Backup**:
   - When training initializes, the engine inspects `checkpoint_status.txt`.
   - If the previous run concluded cleanly (`SUCCESS`), a verified safety snapshot is created:
     `geomind_steady_state_weights.bin.bak` (52.4 MB).
2. **Interruption (Ctrl-C / Break) Detection**:
   - Status is marked `IN_PROGRESS` immediately before entering the training loop.
   - If the process is halted via `Ctrl-C` or terminated unexpectedly, status remains `IN_PROGRESS`.
3. **Automatic Safe Rollback**:
   - On the next launch, the engine detects `IN_PROGRESS`.
   - It refuses to overwrite the safety backup with half-baked weights.
   - It automatically copies `geomind_steady_state_weights.bin.bak` over `geomind_steady_state_weights.bin`, ensuring zero weight degradation.
   - Checkpoint status updates to `SUCCESS` only when all requested epochs complete or target loss is achieved.

