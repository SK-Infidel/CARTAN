# Sprint 527 Plan: CPU Thread-Pool Optimization & Cortical Stream Calibration

**Sprint Goal**: Optimize CPU thread pool synchronization to eliminate Win32 `Sleep` timer quantum stalls during active inference, and calibrate the 8 Lie subgroup cortical streams with authentic SVD linear projection adapters ($W_{\text{in}}, W_{\text{out}}$) to enable semantic preservation and genuine speculative drafting.

---

## 1. User Stories

1. **User Story 1 (Runtime Performance)**:
   As an engineer, I want the CPU worker thread pool to synchronize via zero-sleep active spin-waits during causal decode, so that per-layer latency approaches memory bandwidth limits rather than suffering $15.6\text{ ms}$ timer quantization stalls.

2. **User Story 2 (Geometric Stream Calibration)**:
   As an architecture lead, I want each of the 8 Lie subgroup cortical streams to project into its exact canonical Lie algebra dimension via orthonormal singular vectors ($W_{\text{in}} \in \mathbb{R}^{d_s \times 2560}, W_{\text{out}} \in \mathbb{R}^{2560 \times d_s}$) computed from authentic domain embeddings, so that geometric transformations map back into valid semantic embeddings without channel distortion.

3. **User Story 3 (Speculative Drafting & Verification)**:
   As a QA tester, I want the calibrated cortical streams to draft candidate tokens that preserve semantic coherence, verified against live canary prompts and the 16 compiler regression targets.

---

## 2. Technical Approach

### Phase A: Tooling & Adapter Calibration
1. Create [`tools/calibrate_stream_adapters.py`](file:///C:/Users/rich-/source/repos/CARTAN/tools/calibrate_stream_adapters.py):
   - Ingest authentic 262k embedding matrix from `test/geomind/trainingdata/checkpoints/geomind_embeddings_full_262k.bin` (or `cache_model.safetensors`).
   - For each stream $s \in [0..7]$, extract embedding vectors of domain tokens defined in `geomind_stream_masks.bin`.
   - Compute the top $d_s$ singular vectors using truncated SVD (`numpy.linalg.svd` / `scipy.sparse.linalg.svds`).
   - Orthonormal basis guarantees: $W_{\text{in}} W_{\text{in}}^T = I_{d_s}$, $W_{\text{out}} = W_{\text{in}}^T$.
   - Serialize into `test/geomind/trainingdata/checkpoints/geomind_stream_adapters.bin`.

### Phase B: Runtime Stream Adapter Integration (`test/geomind/streams.cl`, `test/geomind/chat.cl`)
1. Implement binary loader for `geomind_stream_adapters.bin` with offset table for stream dimensions $d_s \in [24..136]$.
2. In `geomind_single_stream_forward(cur_h, dom_stream)`:
   - Project $y = W_{\text{in}} \cdot cur\_h$ ($2560 \to d_s$).
   - Apply Lie transformation on $y \in \mathbb{R}^{d_s}$.
   - Project back $x_{\text{out}} = W_{\text{out}} \cdot y$ ($d_s \to 2560$).
   - Return clean, calibrated embedding state.

### Phase C: CPU Thread-Pool Spinlock Optimization (`src/std/transformer.cl`)
1. In `cartan_trans_pool_worker_main`:
   - Replace `if (spin > 500000.0) { Sleep(2.0); }` with active pause/spin loop. Only sleep when `g_trans_pool_standby == 1.0`.
   - In `cartan_trans_pool_dispatch`:
   - Optimize master barrier wait loop: tight spin before yielding to prevent context switch latency.

### Phase D: Empirical Benchmarks & QA
1. Measure decode tok/s improvement on `geomind.exe -cpu`.
2. Measure speculative draft candidate acceptance with calibrated streams.
3. Validate 16 compiler targets in `tools/run_affected_tests.ps1 -Sprint 527`.
