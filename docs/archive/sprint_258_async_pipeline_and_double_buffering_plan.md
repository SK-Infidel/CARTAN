# Implementation Plan - Sprint 258: Asynchronous Double-Buffering & High-Throughput GPU Pipeline

## Sprint Goal
Accelerate GeoMind 42-layer model training throughput from **$29.5\text{ s/s}$ to $>60\text{–}80\text{ s/s}$** on the NVIDIA RTX 2000 Ada GPU by eliminating CPU/GPU serialization bubbles, enabling non-blocking PCIe transfers, scaling micro-batches ($mbs=224$), and removing duplicate checkpoint I/O.

---

## User Stories
1. **As an AI Engineer**, I want the CPU data ingestion and GPU tensor execution to run in parallel via double-buffering so the GPU never waits for sentence tokenization.
2. **As a Model Trainer**, I want host-to-device transfers to be asynchronous (`CL_FALSE`) and 42-layer weight updates to execute in larger micro-batches ($mbs=224$) so VRAM memory traffic is minimized.
3. **As a System Developer**, I want checkpoint snapshots to write once and copy asynchronously so disk I/O does not freeze the training loop.

---

## Technical Architecture & Changes

### 1. Asynchronous Non-Blocking PCIe Transfers (`src/cartanc/c_runtime.c`)
- Update `clEnqueueWriteBuffer` calls for batch inputs, targets, and IC weights to `CL_FALSE`.
- Maintain single synchronization barrier at `clEnqueueReadBuffer` for batch loss extraction.

### 2. Double-Buffered Ping-Pong Ingestion (`test/geomind/geomind_driver.c`)
- Allocate dual slice buffers:
  - `slice_hidden_A`, `slice_targets_A`, `slice_weights_A`
  - `slice_hidden_B`, `slice_targets_B`, `slice_weights_B`
- Worker pipeline:
  - Background thread / OpenMP fills Buffer $B$ while GPU executes Buffer $A$.
  - Atomic pointer swap upon GPU batch completion.

### 3. Scaled Micro-Batch Size ($mbs = 224$)
- Increase micro-batch from $112 \to 224$ (2 sub-batches per 448-sample slice).
- Reduces 42-layer reverse-mode weight matrix writes from $4\times \to 2\times$ per slice, cutting VRAM bandwidth by $4.4\text{ GB}$ per slice.

### 4. Fast Single-Write Checkpoint Snapshot
- Replace duplicate `save_signed_checkpoint` calls on record-low validation loss with a single disk save + Windows `CopyFileA(best_path, ckpt_path, FALSE)`.

---

## Verification & Definition of Done (DoD)
- [ ] Clean compilation with `zig cc` producing `bin/geomind.exe`.
- [ ] Empirical throughput verified at $\mathbf{>60\text{ samples/second}}$ on the physical RTX 2000 Ada GPU.
- [ ] Loss values monotonically decrease from `geomind_CLOZE_best.bin` foundation.
- [ ] Zero mock, stub, or simulated routines.
- [ ] `CHANGELOG.md` updated and sprint walkthrough saved to `docs/archive/`.
