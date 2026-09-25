# Sprint 416 Plan: Axiomatic Sleep Consolidation & Neocortical Gradient Imprinting

## Objective
Connect the Neuro-Symbolic Expert System (NSES) knowledge graph into GeoMind's autonomous sleep consolidation engine (`src/std/sleep.cl`, `test/geomind/sleep.car`, `test/geomind/train.cl`). Instead of placeholder sine vectors or lost RAM updates, sleep consolidation will load verified 42-rule axiomatic embeddings, relax them through continuous Hopfield dynamics, imprint clean structural gradients into the slow cortical weights ($W_{2560 \times 2560}$), and serialize updated weights to disk.

---

## Architecture & Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. NSES Grounded Knowledge Graph (nses_knowledge.car_graph) │
│    42 SAT-Verified Rules (12 Strict Invariants)             │
└──────────────────────────────┬──────────────────────────────┘
                               │ cargraph_get_rule_embedding()
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Continuous Hopfield Relaxation (sleep_replay_basin)      │
│    Energy Minima Projection: \xi^* = softmax(\beta X^T \xi) │
└──────────────────────────────┬──────────────────────────────┘
                               │ Resonance Gate (\rho > 0.40)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Synthetic Hebbian Imprinting (cartan_tensor_hebbian_...)  │
│    \Delta W = \eta_sleep * (\xi^* (\xi^*)^T - \alpha W)     │
└──────────────────────────────┬──────────────────────────────┘
                               │
               ┌───────────────┴───────────────┐
               ▼                               ▼
┌───────────────────────────────┐ ┌───────────────────────────┐
│ Offline Sleep Daemon          │ │ Online Steady-State Train │
│ (test/geomind/sleep.car)      │ │ (test/geomind/train.cl)   │
│ - Save to steady_state.bin    │ │ - Replay every 500 chunks │
│ - Atomic backup of .bin.bak   │ │ - Host-to-GPU sync        │
└───────────────────────────────┘ └───────────────────────────┘
```

---

## Tasks
1. Add `cartan_hopfield_get_basin(idx)` in `src/std/resonator.cl` to access real loaded Hopfield attractors.
2. Upgrade `src/std/sleep.cl`:
   - Replace synthetic sine vectors in `sleep_run_consolidation_cycle` with real loaded basins.
   - Implement `sleep_run_axiomatic_consolidation(nses_graph, basins_file, dim, lr)` extracting 42 genuine rule embeddings from `nses_knowledge.car_graph`.
3. Upgrade `test/geomind/sleep.car`:
   - Load baseline `geomind_steady_state_weights.bin`.
   - Run axiomatic rule replay phase.
   - Serialize consolidated cortical weights to disk via `cartan_safetensors_save_tensor_f32`.
4. Connect periodic axiomatic rule replay into `test/geomind/train.cl` every 500 chunks and sync to GPU.
5. Recompile and empirically verify with `cartanc.exe`.
