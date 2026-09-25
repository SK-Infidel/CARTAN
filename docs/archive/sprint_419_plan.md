# Sprint 419 Implementation Plan: Authentic GPU Hopfield Attractor Synchronization & Context-Aware Domain Routing

## 1. Objectives & Architectural Context
- **Self-Hosting Intelligence Architecture**: Replace synthetic sine wave mock attractors in GPU VRAM with authentic continuous Hopfield attractors loaded from `hopfield_basins.bin` and consolidated during metacognitive sleep.
- **Race Condition Elimination**: Fix the OpenCL workgroup race condition on `__local float s_sim[8];` inside `geomind_hopfield_inject` by decoupling Softmax probabilities into `s_p[8]`, gating reduction behind `lid == 0`, and placing proper workgroup memory fences.
- **Context-Aware NSES Domain Routing**: Stop misrouting web and educational corpora (`openwebtext_curated.txt`, `fineweb_edu_curated.txt`, `wikitext103_structural.txt`) into Domain 1 (`PHYSICS_SIM`). Route educational text to Domain 3 (`COMPLEXITY_THEORY` / Logic), and default general web prose to Domain 5 (`CAUSAL_TAXONOMY`).
- **Strict Zero-Mock / Zero-Simulation Rule**: 100% genuine vector transfers and authentic domain constraints with zero placeholders.

---

## 2. Dependency Tree & Impact Analysis
```
hopfield_basins.bin (3 canonical attractors, 2560-D)
       │
       ▼ (cartan_hopfield_load_basins)
g_hopfield_key_bank
       │
       ▼ (train_sync_hopfield_attractors_host_to_gpu)
g_host_hopfield_attractors (8 x 2560 float buffer)
       │
       ▼ (gpu_write DMA)
g_buf_hopfield_attractors (GPU VRAM buffer)
       │
       ├─────────────────────────────────┐
       ▼                                 ▼
geomind_hopfield_inject          geomind_hopfield_backward
(Forward Attractor Resonance)    (Backward Coherence Gradient)
```

- **Dependencies**:
  - `src/std/resonator.cl`: `cartan_hopfield_load_basins`, `cartan_hopfield_get_basin`, `cartan_tree_len_f`.
  - `src/std/sleep.cl`: `sleep_run_axiomatic_consolidation`, `cartan_sleep_consolidate_cycle`.
  - `test/geomind/train.cl`: GPU pipeline configurations, chunk execution loops, domain routing, sleep triggers.

---

## 3. Concrete Implementation Steps
1. **Define `train_sync_hopfield_attractors_host_to_gpu()` in `test/geomind/train.cl`**:
   - Query `g_hopfield_key_bank` / load `hopfield_basins.bin`.
   - Copy up to 8 active attractors into `g_host_hopfield_attractors` and zero remaining slots.
   - Perform `gpu_write` into `g_buf_hopfield_attractors`.
   - Update `num_attractors` pipeline arguments on `g_pipe_hopfield_inject` and `g_pipe_hopfield_backward`.
   - Set `g_num_active_hopfield_attractors`.
2. **Fix `geomind_hopfield_inject` Kernel Race Condition**:
   - Allocate `__local float s_p[8];`.
   - Gate reduction and Softmax exponentiation behind `if (lid == 0)`.
   - Insert memory barrier before retrieval loop.
3. **Purge Synthetic Sine Initializations**:
   - Replace lines 345-355 in `train_mount_gpu()` with zero-init.
   - Purge dead synthetic bank creation (lines 525-539).
   - Call `train_sync_hopfield_attractors_host_to_gpu()` in `train_mount_gpu()` and after sleep consolidation (line 2318).
4. **Correct Pre-Step Active Domain Routing**:
   - Update lines 2035-2046 to route `edu`, `logic` -> Domain 3.0, and default to Domain 5.0 (`CAUSAL_TAXONOMY`).
5. **Compile & Empirically Verify**:
   - Build native `geomind.exe` with `./cartanc.exe build test/geomind/main.car -o geomind.exe`.
   - Sync binaries to `test/geomind/geomind.exe` and `bin/geomind.exe`.
   - Run short test execution and NSES regression suite to confirm clean performance.
