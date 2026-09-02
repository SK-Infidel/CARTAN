# Archived Brainstorming: Biological Architecture, Inference Learning, and Zero-Day Multimodal Ingestion

- **Source Document**: [`docs/Vision/BIOLOGICAL_ARCHITECTURE_AND_INFERENCE_LEARNING.md`](file:///C:/Users/rich-/source/repos/CARTAN/docs/Vision/BIOLOGICAL_ARCHITECTURE_AND_INFERENCE_LEARNING.md)
- **Date**: September 2, 2026
- **Status**: Captured & Registered into Project Roadmap

---

## 1. Context & Motivation
Traditional LLMs depend on Backpropagation Through Time (BPTT) with small learning rates ($\eta \approx 10^{-4}$), causing catastrophic forgetting and requiring millions of iterations to learn simple associations. Biological brains learn from 1-3 exposures by:
1. Using **Dual-Memory (Complementary Learning Systems)**: Hippocampus (fast episodic attractor memory) + Neocortex (slow semantic memory).
2. Applying **Three-Factor Hebbian Plasticity**: $\Delta W = \eta \cdot \text{Pre} \cdot \text{Post} \cdot M$, where $M$ is neuromodulation (dopamine/reward, norepinephrine/surprise).
3. Utilizing **Cross-Modal Grounding**: Shared Lie group manifold coordinate space for vision, audition, and text.
4. Practicing **Sleep & Replay Consolidation**: Offline transfer of episodic attractors to structural cortical weights.

---

## 2. Identified Dormant Components in GeoMind
- **Continuous Hopfield Resonator**: [`src/std/resonator.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/resonator.cl) & [`test/geomind/ising_state_machine.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/ising_state_machine.cl) (disconnected from `--ingest` and generation).
- **8 Lie Subgroup Streams**: [`test/geomind/streams.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/streams.cl) (`SpectralStream`, `EikonalStream`, `PoincareStream`, `SSMStream`, etc., currently bypassed by dense GEMM).
- **Sasaki Phase-Space Router**: [`test/geomind/moe.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/moe.cl) & [`src/cartanc/c_runtime.c:4217`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/c_runtime.c#L4217-L4239) (gating calculated but discarded).
- **Sleep Consolidation Loop**: `sleep.ctn` (archived, omitted from current CARTAN runner).
- **Multimodal Vision**: [`test/geomind/chat.cl:54`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl#L54) (stubbed `return 1.0;`).

---

## 3. Four-Phase Action Blueprint
1. **Phase A (Memory & Streams)**: Connect online Hopfield memory basins to `--ingest` and autoregressive generation; wire the 8 specialized streams into the 42-layer manifold.
2. **Phase B (Inference Plasticity)**: Implement local three-factor Hebbian synaptic update operators for test-time learning.
3. **Phase C (Multimodal Grounding)**: Wire SigLIP/vision patch encoders to `EikonalStream` and audio spectrogram features to `SpectralStream`.
4. **Phase D (Metacognitive Sleep)**: Implement an idle background daemon that replays episodic memories into the cortical manifold.
