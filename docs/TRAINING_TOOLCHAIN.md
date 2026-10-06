# CARTAN Sovereign Manifold Training Toolchain Architecture

This document provides a comprehensive technical reference for the 42-layer sovereign manifold training toolchain, WebGPU acceleration, Continuous Hopfield memory ingestion, and metacognitive adaptation pathways in CARTAN.

---

## 1. Toolchain Overview & End-to-End Pipeline

```
 ┌─────────────────────────────────────────────────────────────────────────┐
 │       Corpus Ingestion & Sovereign 262k SentencePiece BPE Trie          │
 │                 (geomind_vocab_262k.bin | 12.96 MB Arena)               │
 └────────────────────────────────────┬────────────────────────────────────┘
                                      │ 262,144 BPE Token IDs (0..262143)
                                      ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │               1. 42-Layer Sovereign Manifold Training Engine            │
 │     (D=2560, GQA 16/8 Heads, SwiGLU 10240, WebGPU / AVX2 Multithreading)│
 ├─────────────────────────────────────────────────────────────────────────┤
 │  • Causal Cross-Entropy Pre-training  (`--train-ce` / `--train-pre`)   │
 │  • Anchored Cloze Curriculum          (`--train-cloze`)                 │
 │  • Teacher-Student KL Distillation   (`--train-distill`)               │
 │  • Supervised Fine-Tuning (SFT)       (`--train-sft`)                   │
 │  • WebGPU Causal Compute Shaders      (`--train-webgpu`)                │
 └────────────────────────────────────┬────────────────────────────────────┘
                                      │ Calibrated Checkpoints (.safetensors / .bin)
                                      ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │        2. Continuous Hopfield & Metacognitive Memory Pathways           │
 │  • One-Shot Semantic Memory Ingestion (`--ingest <text_file>`)          │
 │  • Offline Metacognitive Consolidation (`--sleep`)                      │
 │  • AZR Compiler Self-Play             (`--azr-selfplay`)                │
 └────────────────────────────────────┬────────────────────────────────────┘
                                      │ Memory Basins (`hopfield_basins.bin`)
                                      ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │            3. Dynamic Inference & Conversational REPL Engine            │
 │  • Non-blocking CRT `_kbhit` generation interrupt via `/` key           │
 │  • Pinned Contiguous KV Cache Arena (up to 131,072 Context Horizon)     │
 │  • StreamingLLM Attention Sinks (t in [0..3]) + 256 Local Window        │
 │  • Sasaki Brainstem Tangent Bundle Dynamic MoE Routing (Layer 24)       │
 │  • 8 Lie Subgroup Stream Projections with Calibrated SVD Adapters       │
 └─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Core Toolchain Components

### 2.1 Pure-CARTAN SentencePiece 262k BPE Trie Tokenization
- **Binary Arena Architecture**: 16-byte aligned binary Trie node layout (`geomind_vocab_262k.bin`, 12.96 MB, 600,386 nodes, 262,144 vocabulary entries).
- **Longest-Match Traversal**: Greedy prefix traversal in native CARTAN (`src/std/tokenizer.cl`) without external C runtime dependencies or string heap thrashing.
- **$\mathcal{O}(1)$ String Pool Dereferencing**: Token ID decoding resolves directly into in-memory string slices.
- **Zipfian Logit Adjustment & Information Content Loss Scaling**:
  $$\mathcal{L}_{\text{scaled}}(w) = \mathcal{L}_{\text{CE}}(w) \cdot \left(1.0 + \alpha \cdot \text{IC}(w)\right)$$
  $$\text{logits}_{\text{adjusted}}(w) = \text{logits}(w) - \gamma \cdot \text{IC}(w)$$
  where $\text{IC}(w) = -\log_2 P(w)$ penalizes morphological token salad while preserving essential English syntax.

### 2.2 Sovereign 42-Layer Manifold Architecture (`src/std/transformer.cl`)
- **Model Geometry**: Hidden dimension $D = 2560$, 42 continuous transformer layers, Grouped-Query Attention (GQA, 16 query heads, 8 key/value heads, $d_{\text{head}} = 256$), SwiGLU MLP ($d_{\text{ffn}} = 10240$), RoPE rotary embeddings ($\theta = 10000.0$), and softcap LM head ($30.0$).
- **Pinned Contiguous KV Cache Arena**: Pre-allocated physical memory buffers ($24 \times L \times 1024 \times 4\text{ B}$), supporting configurable horizons up to 131,072 context tokens. Shared KV layers 24..41 reference source layers 22/23 with zero copy.
- **StreamingLLM Sinks & Local Sliding Window**: Attention evaluates 4 initial sink tokens ($t \in [0, 3]$) and a 256-token sliding window ($t \in [\text{win\_start}, \text{max\_seq}-1]$), bounding attention compute to $\le 260$ tokens indefinitely.
- **AVX2 256-Bit SIMD Acceleration**: Hardware-accelerated INT8 (`@cartan_simd_dot_i8_f32`) and INT4 (`@cartan_simd_dot_i4_f32`) vector dot products with full 256-bit register saturation.

### 2.3 WebGPU Hardware Acceleration (`src/std/wgpu.cl`)
- **Direct GPU VRAM Residency**: All 42 INT4 manifold layers (1.87 GB resident) pinned directly in GPU GDDR6 VRAM.
- **Double-Buffered Asynchronous Staging**: Dedicated double-buffered ping-pong staging buffers (`g_wgpu_staging_buf_0` / `g_wgpu_staging_buf_1`, $\ge 1\text{ MB}$ each, `WGPUBufferUsage_MapRead | WGPUBufferUsage_CopyDst`) for non-blocking GPU readback.
- **Branchless INT4 WGSL Compute Shaders**: Unpacks 4-bit nibbles via `unpack4x8unorm` + `select` with zero branching divergence.

### 2.4 Tangent Bundle Dynamic MoE Routing & Lie Streams
- **Layer 24 Sasaki Brainstem Router**: Routes on the phase-space tangent bundle $T\mathcal{M} = (h_{24}, \dot{h}_{24}) \in \mathbb{R}^{5120}$ with velocity $\dot{h}_{24} = h_{24} - h_{23}$ under the Finsler-Randers metric:
  $$F(x, v) = \sqrt{g_{ij}(x) v^i v^j} + \beta_i(x) v^i$$
- **Freudenthal Magic Square $4 \times 4$ MoE**: 16 division algebra pairings $(\mathbb{R}, \mathbb{C}, \mathbb{H}, \mathbb{O})$ mapping to 16 specialized experts. Fast Path bypasses complex intermediate layers when routing confidence $w^* \ge 0.35$.
- **8 Lie Subgroup Streams**: Decomposes representations into 8 maximal Lie subgroups ($SO(16)$, $E_7 \times SU(2)$, $SU(9)$, $SU(3) \times E_6$, $F_4 \times G_2$, $SU(5) \times SU(5)$, $SO(10) \times SU(4)$, and $SU(3)^3$ Triality Cyclic Rotation) with calibrated orthonormal SVD projection adapters ($W_{\text{in}} \in \mathbb{R}^{d_s \times 2560}, W_{\text{out}} = W_{\text{in}}^T$).

---

## 3. Production Training & Adaptation Modes

The CARTAN training suite is implemented in [`Projects/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/train.cl) and executed via `geomind.exe`:

### 3.1 Causal Cross-Entropy Narrative Pre-training (`--train-ce` / `--train-pre`)
- **Command**: `geomind.exe --train-ce [-target <file.txt>] [-epochs <N>] [-lr <rate>]`
- **Default Target Loss**: **`3.00`** (Perplexity $\approx 20.1$).
- **Objective**: Standard causal next-token cross-entropy over sliding-window text chunks, optimizing syntactic coherence, grammatical fluency, and long-range narrative continuity.

### 3.2 Anchored Cloze Curriculum (`--train-cloze`)
- **Command**: `geomind.exe --train-cloze [-target <file.jsonl>] [-epochs <N>]`
- **Default Target Loss**: **`4.20`** (Perplexity $\approx 66.7$).
- **Objective**: Rapidly grounds lexical taxonomy units, non-reversible binomials, discourse markers, and transition bridges out of random entropy by masking target tokens within structured contexts.

### 3.3 Teacher-Student KL Distillation (`--train-distill`)
- **Command**: `geomind.exe --train-distill [-target <file>] [-epochs <N>]`
- **Objective**: Minimizes Kullback-Leibler divergence between a teacher distribution and the sovereign manifold student model:
  $$\mathcal{L}_{\text{distill}} = (1 - \alpha) \mathcal{L}_{\text{CE}} + \alpha \cdot T^2 \cdot D_{\text{KL}}\left(\sigma\left(\frac{z_{\text{teacher}}}{T}\right) \parallel \sigma\left(\frac{z_{\text{student}}}{T}\right)\right)$$

### 3.4 Supervised Fine-Tuning & Alignment (`--train-sft`)
- **Command**: `geomind.exe --train-sft [-target <file.txt>] [-epochs <N>]`
- **Default Target Loss**: **`2.00`** (Perplexity $\approx 7.4$).
- **Objective**: Aligns conversational responses, persona boundaries, and multi-turn instruction following.

### 3.5 WebGPU Causal Training (`--train-webgpu`)
- **Command**: `geomind.exe --train-webgpu [-target <file>] [-epochs <N>]`
- **Objective**: Dispatches causal transformer forward and backward compute passes directly across GPU workgroups via WebGPU native pipelines.

### 3.6 Continuous Hopfield Episodic Memory Ingestion (`--ingest`)
- **Command**: `geomind.exe --ingest <document.txt>`
- **Objective**: Instantaneous zero-backpropagation semantic memory storage. Encodes text via SentencePiece BPE, generates 2560D hidden state embeddings via forward pass, pools centroids, pairs them with candidate token bursts, and appends new attractor basins directly to `hopfield_basins.bin` on disk.

### 3.7 Metacognitive Sleep Consolidation (`--sleep`)
- **Command**: `geomind.exe --sleep`
- **Objective**: Offline memory maintenance pass that relaxes memory manifolds, merges overlapping attractor basins, prunes redundant memory centroids, and reinforces invariant semantic trajectories.

### 3.8 Absolute Zero Reasoning (AZR) Compiler Self-Play (`--azr-selfplay`)
- **Command**: `geomind.exe --azr-selfplay`
- **Objective**: Generates autonomous compiler test cases and algorithms, executing them through `cartanc.exe` and rewarding non-trivial passing programs with binary execution rewards ($R \in \{0, 1\}$) without synthetic reward models.

---

## 4. CLI Optimization Flags & Learning Rate Mechanics

All flags feature calibrated defaults for stable convergence:

| CLI Flag | Type | Default Value | Description & Mechanics |
| :--- | :--- | :--- | :--- |
| `-epochs` | Float | `500.0` | Maximum number of training epochs to execute. |
| `-target-loss` | Float | Stage-calibrated | Convergence threshold triggering early stopping (`ep >= 10.0`). |
| `-lr` | Float | `0.001` | **Starting Base Learning Rate Ceiling**. Omitting `-lr` uses calibrated schedule: starts at `0.001`, decays by factor `0.995` each epoch, and clamps at the `0.0001` floor. |
| `-target` | String | Curated stage path | Custom dataset filepath. |
| `-cpu` | Flag | Off | Forces CPU multithreaded AVX2 execution, bypassing GPU. |
| `-tokens` | Float | `128.0` | Maximum token generation length per response during evaluation. |
| `-context` | Float | `8192.0` | Active context window capacity (dynamically resizable up to `131072.0`). |

---

## 5. Checkpoint Safety & Interruption Rollback Protocol

Training state is strictly protected against corruption from aborted runs, system crashes, or manual `Ctrl-C` breaks using an out-of-band marker (`checkpoint_status.txt`):

1. **Clean-Run Safety Backup**:
   - When training initializes, the engine inspects `checkpoint_status.txt`.
   - If the previous run concluded cleanly (`SUCCESS`), a verified safety snapshot is created:
     `geomind_steady_state_weights.bin.bak`.
2. **Interruption (Ctrl-C / Break) Detection**:
   - Status is marked `IN_PROGRESS` immediately before entering the training loop.
   - If the process is halted via `Ctrl-C` or terminated unexpectedly, status remains `IN_PROGRESS`.
3. **Automatic Safe Rollback**:
   - On the next launch, the engine detects `IN_PROGRESS`.
   - It refuses to overwrite the safety backup with half-baked weights.
   - It automatically restores `geomind_steady_state_weights.bin.bak` over `geomind_steady_state_weights.bin`, ensuring zero weight degradation.
   - Checkpoint status updates to `SUCCESS` only when all requested epochs complete or target loss is achieved.

---

## 6. Strict Zero-Mock Verification Rule

In accordance with core system directives:
- **No Synthetic Training Loops**: All forward passes, gradient backward steps, cross-entropy evaluations, and Hopfield energy relaxations execute genuine mathematical operations on physical memory buffers.
- **Empirical Validation**: Model metrics, losses, perplexities, and generation benchmarks must be verified empirically using native binaries compiled with `cartanc.exe`.
