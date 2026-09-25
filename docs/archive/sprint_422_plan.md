# Sprint 422 Implementation Plan: Saliency Attractor Selection

## 1. Context & Objectives
- **Context**: In Sprint 419, authentic Hopfield attractor synchronization to GPU VRAM was implemented (`train_sync_hopfield_attractors_host_to_gpu`), but it naively sliced the first 8 attractors sequentially from storage without regard to the active training domain. When rotating across datasets (physics, topology, logic, biology, web taxonomy), the GPU was burdened with irrelevant attractors or missing domain-specific axiomatic invariants.
- **Goal**:
  1. Implement authentic **Saliency Attractor Selection** in [`src/std/saliency_attractor.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/saliency_attractor.cl).
  2. Implement multi-tier domain-aware saliency ranking: Tier 1 (Universal Domain 0 strict invariants), Tier 2 (Active domain strict invariants), Tier 3 (Active domain factual axioms), Tier 4 (Epistemic resonance ranking).
  3. Implement `train_sync_salient_attractors_to_gpu(active_domain, cg)` in [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl) with zero-cost domain caching.
  4. Implement `resonator_select_salient_attractors` in [`src/std/resonator.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/resonator.cl) for fast $O(K \cdot D)$ continuous Hopfield relaxation.
  5. Empirically verify 100% test pass on new suite `test_sprint9_saliency_attractors.car` and clean streaming training execution.

---

## 2. Architecture & Design

### A. Saliency Attractor Selection Core (`src/std/saliency_attractor.cl`)
1. **`saliency_select_domain_attractor_indices(cg: CarGraphFile, target_domain: float, max_attractors: float) -> ptr`**:
   - Extracts rule indices satisfying domain priority:
     - Tier 1: Domain 0 strict invariants ($domain == 0.0 \land is\_strict == 1.0$).
     - Tier 2: Target domain strict invariants ($domain == target\_domain \land is\_strict == 1.0$).
     - Tier 3: Target domain factual rules ($domain == target\_domain \land is\_strict == 0.0$).
     - Tier 4: Adjacent domain strict invariants.
   - Enforces $K \le max\_attractors$ ceiling (default 8 for GPU).
2. **`saliency_format_attractor_buffer(cg: CarGraphFile, rule_indices: ptr, out_buf: ptr, dim: float, max_attractors: float) -> float`**:
   - Zero-alloc DMA formatting: reads 1536-D embeddings, pads to 2560-D, applies $L_2$ unit-normalization, and writes to `out_buf[slot * dim + d]`.
3. **`saliency_select_resonant_attractors(bank: ptr, query_vec: ptr, dim: float, max_attractors: float) -> ptr`**:
   - Ranks attractors by cosine resonance against `query_vec`.

### B. Resonator Integration (`src/std/resonator.cl`)
1. Implement `resonator_salient_hopfield_relax(bank, state_vec, dim, beta, steps, top_k) -> float`:
   - Filters memory bank to Top-K salient attractors before iterative relaxation, reducing complexity from $O(N \cdot D)$ to $O(K \cdot D)$.

### C. Training Pipeline Integration (`test/geomind/train.cl`)
1. Track `g_synced_gpu_domain: float = -1.0;`.
2. Implement `train_sync_salient_attractors_to_gpu(active_domain: float, cg: CarGraphFile) -> float`:
   - Checks `if (active_domain == g_synced_gpu_domain) return count;` for instantaneous $O(1)$ cache hits.
   - On domain switch: formats Top-8 salient attractors, DMA writes to `g_buf_hopfield_attractors` on GPU, binds pipeline arguments, updates `g_synced_gpu_domain`.
3. Call right before GPU chunk execution in `geomind_train_streaming_steady_state`.

---

## 3. Verification Plan
- Build native `geomind.exe` with Zig `-O3 LTO Vectorized Pass Pipeline`.
- Create and run `test/geomind/nses/test_sprint9_saliency_attractors.car`.
- Verify `geomind.exe --verify` and `geomind.exe --sleep`.
- Run live streaming training `geomind.exe --train-ce` verifying dynamic domain-switched attractor synchronization.
