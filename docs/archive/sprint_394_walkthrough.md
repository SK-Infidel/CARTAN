# Sprint 394 Walkthrough: Training Pipeline & Architectural Decoupling (Phase 1)

## Executive Summary
Sprint 394 addressed four systemic training pipeline issues identified in `[ISSUE-142]`:
1. Cross-domain recurrent context bleed (`g_has_prev_chunk_h` poisoning context across domain shifts).
2. Coarse pseudo-interleaving (`slice_limit = 50.0` clumping 12,800 tokens per domain).
3. Active temperature resonant oscillator (`TTemp` oscillating between $1.02$ and $1.09$ via single-slice $val\_gap$).
4. Tied-weight representation bottleneck ($W \in \mathbb{R}^{2560 \times 2560}$ tied across token embeddings and LM head).

---

## Changes Implemented

### 1. Multi-Stream Persistent Context Memory
* **File**: [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L292)
* Allocated `g_buf_domain_h` ($16 \times 2560 \times 4\text{ bytes} = 163.8\text{ KB}$) in VRAM and `domain_has_prev` tracker.
* Added `geomind_copy_domain_h` OpenCL kernel (`g_pipe_copy_domain_h`) to swap recurrent hidden states on domain transitions.
* Intra-domain sequence continuity is fully preserved across cycles while cross-domain context contamination is strictly zeroed.

### 2. True 1-Chunk Interleaved Mixture Streaming
* **File**: [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L2073)
* Set `slice_limit = 1.0` so domain rotations occur every chunk ($256$ tokens).
* Preloaded in-memory buffers eliminate disk I/O overhead.
* 50-chunk telemetry reports now reflect a genuine, balanced mixture composite (5 chunks from each of 10 domains).

### 3. Temperature Oscillator Quenching
* **File**: [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L2235)
* Locked `g_train_temperature = 1.0` during training passes, eliminating the $1/T$ gradient noise feedback loop.
* Confined `g_val_temperature` calibration strictly to the multi-sample holdout validation pass on full cycle boundaries.

### 4. Input Embedding & LM Head Decoupling (Weight Decoupling Phase 1)
* **Files**: [`src/std/hebbian.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/hebbian.cl#L138), [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L291), [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl), [`test/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car)
* Allocated `g_buf_embedding_weights` ($2560 \times 2560$) alongside `g_buf_cortical_weights`.
* Bound `g_buf_embedding_weights` to `g_pipe_autoregressive` and `g_pipe_streams_backward`.
* Bound `g_buf_cortical_weights` exclusively to `g_pipe_gemv` (forward LM head) and `g_pipe_sgd` (head backprop).
* Enabled dual-tensor checkpointing (`geomind_embedding_weights.bin` and `geomind_steady_state_weights.bin`) with backwards-compatible fallback loading.

---

## Verification & Empirical Proof
1. **Compilation**: Built with `cartanc.exe` targeting native Zig/Clang `-O3` LTO with zero errors.
2. **Binary Parity**: SHA-256 `6CFA59BEA2D3EF5713382946905705268529B9E0AE0AEB9B00084BBA6B831EB6` synchronized across `geomind.exe`, `test/geomind/geomind.exe`, and `bin/geomind.exe`.
3. **Analogy Arithmetic**: Verified 4/4 semantic vector analogies passing at Rank 1:
   - King - man + woman = queen (+0.107 margin)
   - he - him + her = she (+0.151 margin)
   - father - man + woman = mother (+0.093 margin)
   - boy - man + woman = girl (+0.260 margin)
