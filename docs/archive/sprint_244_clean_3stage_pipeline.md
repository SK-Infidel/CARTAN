# Sprint 244 Walkthrough: Clean 3-Stage End-to-End Training & Benchmarks

**Date**: 2026-08-19  
**Goal**: Reset model weights to pristine baseline SLERP state and execute full automated 3-stage training pipeline (Stage 0 Baseline $\to$ Stage 1 Cloze $\to$ Stage 2 Causal CE $\to$ Stage 3 SFT) with empirical generation benchmarks logged after each stage.

---

## 1. Clean Baseline Initialization
- Extracted unperturbed 42-layer 3D MoE base weights ($275,251,200$ parameters) directly from `cache_google_gemma-4-E4B-it_model.safetensors` via `tools/merge_gemma4_42layers_3dmoe.py`.
- Hardware: Mounted OpenCL 3.0 on **NVIDIA RTX 2000 Ada Generation Laptop GPU** ($1,161\text{ MiB}$ VRAM).

---

## 2. 3-Stage Pipeline Execution & Benchmark Results

### Stage 0: Clean Baseline Generation
- Evaluated 7 standard test prompts before training.
- Logged pre-training completions to `logs/stage0_baseline_generation.log`.

### Stage 1: Cloze Training & Evaluation
- Streamed through mined expanded cloze datasets using BPE subword prefix-trie tokenization.
- Output logs: `logs/stage1_cloze_training.log` & `logs/stage1_post_cloze_generation.log`.

### Stage 2: Causal Cross-Entropy (CE) Training & Evaluation
- Streamed through source screenplay and literature corpora with multi-token causal next-word targets.
- Output logs: `logs/stage2_ce_training.log` & `logs/stage2_post_ce_generation.log`.

### Stage 3: Supervised Fine-Tuning (SFT) & Final Target Hit
- Streamed 38,976 samples across all 42 physical layers directly in GPU VRAM.
- Achieved target convergence in Epoch 1:
  - **Validation Loss: `0.2260`**
  - **Validation Perplexity: `1.25`**
- Output logs: `logs/stage3_sft_training.log` & `logs/stage3_post_sft_generation.log`.

---

## 3. Artifacts & Verification
- **Signed Checkpoint**: Exported cryptographically verified 42-layer checkpoint [`test/geomind/trainingdata/checkpoints/geomind_cloze_aligned_weights.bin`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/checkpoints/geomind_cloze_aligned_weights.bin).
- **Execution Status**: Clean exit code `0` across all pipeline stages.
