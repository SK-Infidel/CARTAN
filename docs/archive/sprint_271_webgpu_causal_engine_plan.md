# Sprint 271 Plan: Pure Native CARTAN WebGPU Causal Training & Telemetry Engine

## 1. Objective
Deliver a 100% pure native CARTAN WebGPU training engine executing on physical GPU hardware via [`src/std/gpu.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/gpu.cl). Eliminate the 98% sequence supervision waste by implementing native WGSL causal triangular masked attention, port the 8 Lie cortical submanifolds into WebGPU compute pipelines, provide persistent on-disk Hopfield attractor storage, and implement biological verification telemetry (Hopfield energy, Lie stream norms, and Sasaki MoE quadrant distributions).

---

## 2. Technical Scope & Architecture

### A. Persistent Continuous Hopfield Attractor Storage ([`src/std/resonator.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/resonator.cl))
- `resonator_save_basins(path: string, count: float) -> float`: Writes current attractor vectors to disk.
- `resonator_load_basins(path: string) -> float`: Reads attractor vectors from disk into active memory.
- Connect to `--ingest` and training startup so learned episodic context persists across sessions.

### B. Pure CARTAN WebGPU Causal Autoregressive Training Engine ([`test/geomind/webgpu_causal_engine.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/webgpu_causal_engine.cl))
- **WGSL Causal Attention Shader**:
  - Computes queries, keys, and values ($Q, K, V$).
  - Evaluates scaled dot product with strict lower-triangular causal mask ($j \le i$).
  - Accumulates weighted value vectors across all sequence positions simultaneously.
- **WGSL Cross-Entropy Sequence Loss & Backprop**:
  - Evaluates loss on every token position $t$ predicting $t+1$, weighted by dynamic WordNet Information Content (IC).
- Dispatched purely through native [`src/std/gpu.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/gpu.cl) bindings (`gpu_alloc`, `gpu_write`, `gpu_create_pipeline`, `gpu_dispatch`, `gpu_sync`, `gpu_read`).

### C. 8-Stream Lie Cortical Submanifold WGSL Shaders
- Contiguously maps 2,560 dimensions to 8 specialized submanifolds (320 dims each):
  - Stream 0: $SO(16)$ Cosformer
  - Stream 1: $E_7 \times SU(2)$ SSM
  - Stream 2: $E_6 \times SU(3)$ Spectral
  - Stream 3: $SU(9)$ Poincaré
  - Stream 4: $F_4 \times G_2$ Homology
  - Stream 5: $SO(10) \times SU(4)$ Eikonal
  - Stream 6: $SU(5) \times SU(5)$ Heat Kernel
  - Stream 7: $SU(3)^3$ Triality

### D. Biological Verification Telemetry
- **Hopfield Energy Tracking**: Active basin count, pre- and post-relaxation energy delta $\Delta E$.
- **Lie Stream Dispersion**: $L_2$ norm for each of the 8 cortical slices.
- **Sasaki MoE Routing Balance**: Gating load distribution percentages across quadrants $Q_0 \dots Q_3$.

---

## 3. Tasks & Checklist

- [ ] **Task 1**: Implement persistent Hopfield attractor saving and loading in [`src/std/resonator.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/resonator.cl).
- [ ] **Task 2**: Create [`test/geomind/webgpu_causal_engine.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/webgpu_causal_engine.cl) with native WGSL causal self-attention and 8 Lie stream shaders.
- [ ] **Task 3**: Implement biological verification telemetry logging in [`test/geomind/webgpu_causal_engine.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/webgpu_causal_engine.cl).
- [ ] **Task 4**: Integrate the WebGPU causal engine into [`test/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car) via CLI flag `--train-causal-webgpu`.
- [ ] **Task 5**: Build and compile via `cartanc_boot.exe build test/geomind/main.car -o bin/geomind_native.exe`.
- [ ] **Task 6**: Empirically verify the native WebGPU causal training pipeline on physical GPU hardware.
- [ ] **Task 7**: Complete sprint review, update `ISSUES.md`, update `CHANGELOG.md`, and record walkthrough in `docs/archive/`.
