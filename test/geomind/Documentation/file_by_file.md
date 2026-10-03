# GeoMind File Reference

## Root Directory

| File | Purpose |
|------|---------|
| `geomind.py` | Main entry point: training, generation, REPL |
| `config.py` | All architecture + training hyperparameters |
| `rif_assimilator.py` | Phase 1+2 RIF alignment training (live or cache mode) |
| `rif_cache_teacher.py` | Pre-computes and caches teacher hidden states |
| `migrate_checkpoint_v2.py` | Migrates v1 (248D) checkpoint to v2 (992D, 4-stream) |
| `count_params.py` | Prints full parameter count breakdown by component |
| `setup.py` | Builds optional C++ E8 SSM extension for JIT speedup |

---

## `scripts/` — Pipeline Scripts

> [!WARNING]
> **DEPRECATED**: The `scripts/` directory structure has been completely deprecated in favor of categorized `utils/` subfolders (e.g., `utils/training/`, `utils/initialization/`, etc.). This table is preserved for historical reference only.

| File | Purpose |
|------|---------|
| `scripts/master_init.py` | Executes the 7-phase Master Initialization pipeline (wipes DB) |
| `scripts/resume_init.py` | Safely resumes Master Initialization from Phase 3 (no wipe) |
| `scripts/graft_modifiers.py` | Extracts and grafts Adjectives and Adverbs into the geometry registry |
| `scripts/igo_tree_walk.py` | Phase 5: Bulk level-order IGO manifold coordinate generation |
| `scripts/derive_bce_weights.py` | Phase 6: Inverse volumetric scaling for PosWeights |
| `scripts/sft_train.py` | Phase 7: Initial Supervised Fine-Tuning |

---

## `core/` — Model Code

| File | Contents |
|------|---------|
| `core/agent_core.py` | `AgentCore`: wraps `GeoMindHybridEngine`, adds loss calculation and generation |
| `core/e8_engine.py` | All block types + both v1 and v2 engines |
| `core/rif_engine.py` | `RIFAssimilatorEngine`: multi-sector alignment projectors + decomp math |

### `core/e8_engine.py` — Key Classes

| Class | Role |
|-------|-----|
| `E8LatticeConfig` | Constants: `TOTAL_DIM=248`, `CARTAN_DIM=8`, `INTEGER_DIM=112`, `HALF_INTEGER_DIM=128` |
| `E8SasakiEmbedding` | Lifts tokens to 15D Sasaki phase space → 248D via fiber connection |
| `E8CosformerAttention` | O(N) linear attention over E8 integer/half-integer root sectors |
| `E8LatticeWaveSSM` | Wave propagation on E8 root graph using graph Laplacian |
| `SO16SpectralMemoryHybrid` | FNet-style DFT mixing + 4096D FFN expansion |
| `E8DualRoutedAttention` | Hardcoded dual-sector routing with KV cache |
| `E8DecompSplitter` | **v2**: 248D → 4×248D learnable basis changes (identity init) |
| `E8StreamHerald` | **v2**: cross-stream attention every `HERALD_EVERY` blocks (zero init) |
| `E8MultiDecompEngine` | **v2**: 4-stream parallel engine with heralds + fusion |
| `GeoMindHybridEngine` | Top-level engine: embedding + blocks/multi_engine + output head |

### `core/rif_engine.py` — Key Symbols

| Symbol | Role |
|--------|-----|
| `E8_DECOMPOSITIONS` | Dict of E7×SU(2), E6×SU(3), SU(9) sub-sector dimensions |
| `STREAM_DECOMP_MAP` | Maps stream index (0-3) to decomposition name |
| `RIFAssimilatorEngine` | Full-spectrum alignment projectors (embedding + blocks + decomps + output head) |
| `.compute_embedding_loss()` | Aligns embedding internals (root_weights, tangent, sasaki, drift, fiber, b) |
| `.compute_block_loss()` | Aligns one block: 248D full + SO(16) sub-sectors + block-specific internals |
| `.compute_stream_alignment_loss()` | **v2**: dispatches per-stream to correct decomposition alignment |
| `.get_active_blocks()` | Returns correct block list for hook registration (v1 or v2) |
| `.get_all_stream_blocks()` | Returns all stream block lists (v2: list of 4 ModuleLists) |

---

## `Documentation/`

| File | Contents |
|------|---------|
| `architecture.md` | E8 geometry, v2 stream design, block types, parameter tables |
| `training.md` | RIF phases, cache workflow, v2 migration, loss targets, cloud scaling |
| `user_guide.md` | Command reference for all scripts and flags |
| `file_by_file.md` | This file |

---

## `trainingdata/`

| File | Contents |
|------|---------|
| `ohsuz_tiny-textbooks-edu_train.txt` | Primary training data: Tiny Textbooks educational dataset |
| `Milton_Minor Poems.txt` | Supplementary literary data for style validation |

---

## `checkpoints/`

| File | Contents |
|------|---------|
| `e8_agent_model.pt` | Main GeoMind checkpoint (active) |
| `e8_agent_model_v2.pt` | Output of `migrate_checkpoint_v2.py` — v2 warm start |
| `rif_engine.pt` | RIF projector weights (saved separately during Phase 1) |
| `teacher_cache.pt` | Pre-computed teacher hidden states for cache-mode training |

---

## `csrc/`

| File | Contents |
|------|---------|
| `e8_ssm.cpp` | Optional C++ extension: JIT-compiled E8 wave propagation loop |

Build with: `python setup.py build_ext --inplace`

---

## Config Reference (`config.py`)

| Key | Default | Description |
|-----|---------|-------------|
| `LATENT_DIM` | 248 | E8 manifold dimensionality (fixed) |
| `HIDDEN_DIM` | 4096 | FFN expansion in spectral memory blocks |
| `MAX_CONTEXT` | 131072 | Cosformer position encoding period |
| `BLOCK_TYPES` | 24-element list | Sequence of block types per stream |
| `NUM_DECOMP_STREAMS` | 4 | 1=v1 (248D), 4=v2 (992D native) |
| `HERALD_EVERY` | 6 | Cross-stream communication interval (blocks) |
| `LEARNING_RATE` | 0.0005 | Base LR for standard training |
| `BATCH_SIZE` | 2 | Chunks per batch |