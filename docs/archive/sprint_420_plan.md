# Sprint 420 Implementation Plan: Asynchronous Double-Buffered BPE Chunk Slicing

## Objective
Eliminate the 30–40% GPU idle bubble between round-robin dataset rotations in [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl) by implementing an asynchronous double-buffered BPE chunk slicing engine that overlaps CPU tokenization of chunk $T+1$ while the GPU executes the training pass of chunk $T$.

---

## Architectural Analysis & Dependency Tree
- **Current Flow**:
  1. CPU sequentially scans lines and BPE encodes 2,048 tokens into `train_tokens` (~1.0–1.5s). GPU is 100% idle.
  2. GPU executes out-of-sample validation pass (~0.6s).
  3. GPU executes backprop and SGD training pass (~1.0s).
  4. CPU loops to step 1. GPU starves for ~1.2s on every rotation.
- **Double-Buffered Overlapped Flow**:
  1. `active_tokens` is pre-sliced and primed before epoch streaming starts.
  2. On each chunk cycle:
     - GPU executes prequential validation pass on `active_tokens` (`geomind_train_chunk_gpu_pipelined(active_tokens, 0.0)`).
     - Focus scheduler determines `next_d_idx` from freshly updated `val_domain_losses`.
     - GPU training pass is launched asynchronously (`geomind_train_chunk_gpu_launch_pass(active_tokens, lr)`).
     - **Concurrent Execution**: While GPU executes 2,047 GEMV + RMSNorm + Attention + FFN + Hopfield + Backprop passes in VRAM, the host CPU slices lines and BPE-encodes chunk $T+1$ from `next_d_idx` into `standby_tokens` via [`geomind_slice_and_tokenize_chunk`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl).
     - GPU finishes training pass and metrics are collected (`geomind_train_chunk_gpu_finish_pass(lr, active_tokens[0])`).
     - Swap `active_tokens` $\leftrightarrow$ `standby_tokens` using zero-copy pointer exchange.
  3. Net result: CPU tokenization latency (~1.2s) is completely hidden inside GPU execution time (~1.6s). GPU idle bubbles drop to 0.0s.

---

## Proposed Changes
1. [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl):
   - Refactor [`geomind_train_chunk_gpu_pipelined`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L913) into:
     - [`geomind_train_chunk_gpu_launch_pass(tokens: ptr, lr: float) -> float`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl): non-blocking OpenCL kernel enqueue loop.
     - [`geomind_train_chunk_gpu_finish_pass(lr: float, n_tokens: float) -> float`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl): DMA loss readback, sync, metrics accumulation, and terminal context copy.
     - [`geomind_train_chunk_gpu_pipelined`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L913): backwards-compatible wrapper calling `launch_pass` then `finish_pass`.
   - Add [`geomind_slice_and_tokenize_chunk(file_content: ptr, content_len: float, start_offset: float, out_tokens: ptr) -> float`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl): reusable chunk slicer and SentencePiece BPE encoder with wrap-around guard.
   - Upgrade [`geomind_train_streaming_steady_state`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L1970) with `active_tokens` / `standby_tokens` double-buffer management and overlapped slicing during GPU training passes.

---

## Verification Criteria
- [ ] Clean compilation via `cartanc.exe build test/geomind/main.car -o geomind.exe`.
- [ ] Empirical test execution via `geomind.exe --train-ce`: verify telemetry reporting, continuous loss progression, and zero pause between dataset domain transitions.
- [ ] NSES loss shaping regression verification (`cartanc.exe run test/geomind/nses/test_sprint7_loss_shaping.car`).
- [ ] Model architecture verification via `geomind.exe --verify`.
