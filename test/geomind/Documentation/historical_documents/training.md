# GeoMind Training Guide

## Overview

GeoMind training uses a two-phase **RIF (Representation Ingest and Fusion)** pipeline to align GeoMind's geometry with a teacher model's knowledge, followed by standard supervised fine-tuning.

---

## Phase 0: Stabilization (SFT Only)

Before any alignment, run a pure SFT stabilization pass to ensure the model produces meaningful gradients:

```bash
python geomind.py --train trainingdata/ohsuz_tiny-textbooks-edu_train.txt --epochs 1
```

Or use the assimilator in stabilize-only mode:

```bash
python rif_assimilator.py \
    --data trainingdata/ohsuz_tiny-textbooks-edu_train.txt \
    --stabilize-only --stabilize 5000
```

**Loss target:** SFT loss < 8.0 before proceeding to Phase 1.

---

## Phase 0: BCEN Open-Vocabulary Pretraining

Before any hybrid LM blocks are trained, the **Byte Coordinate Encoder (BCEN)** must be stabilized. This establishes the continuous coordinate E8 geometry for all byte-sequences (words).

### Phase 1: Deep Autoencoding Pretraining (Isolation)

Trains BCEN and InverseBCEN in isolation using pure reconstruction loss (NLL on raw bytes) + E8 lattice regularization. The main LM blocks are **FROZEN**.

```bash
python bcen_pretrain.py --phase 1 --steps 3000 --data trainingdata/wordnet/definitions_corpus.txt
```
**Goal:** Establish a stable coordinate field where structural distances mirror byte-level similarities.

### Phase 2: Frozen BCEN + Finsler-Randers LM Training

The BCEN embedding is now **FROZEN**. The 24 main hybrid blocks (SSM, Spectral, Dual-Routed) learn to predict E8 coordinates using the Finsler-Randers manifold distance loss.

```bash
python bcen_pretrain.py --phase 2 --steps 100000 --data trainingdata/wordnet/syntactic_corpus.txt --batch-size 32
```
**Goal:** The model learns grammatical and mathematical reasoning by predicting paths across the rigid, frozen geometric space.

### Phase 3: Full Fine-Tuning (Joint)

The BCEN embedding is unfrozen but trained at a drastically reduced learning rate (0.1× base LR). Target coordinates come from a detached `BCEN_frozen` pass to prevent mode collapse.

```bash
python bcen_pretrain.py --phase 3 --steps 20000 --data trainingdata/wordnet/syntactic_corpus.txt --batch-size 32
```
**Goal:** Gently warp the coordinate space to match the model's emergent internal logic.

---

## Phase 1: RIF Alignment (Projector Training)

In Phase 1, both GeoMind **and** the RIF projection heads are trained simultaneously. The RIF engine learns to project teacher hidden states into GeoMind's E8 geometry.

### Option A: Live Mode (teacher model loaded in memory)

```bash
python rif_assimilator.py \
    --data trainingdata/ohsuz_tiny-textbooks-edu_train.txt \
    --teacher google/gemma-4-E4B-it \
    --max-steps 10000 \
    --lr 0.0001
```

**VRAM requirement:** GeoMind v2 (~90M) + teacher (E4B = ~4B effective) = ~8GB+ needed.

### Option B: Cache Mode (recommended — teacher loaded separately)

Pre-compute and cache teacher hidden states to eliminate teacher VRAM overhead during training:

```bash
# Step 1: Build the teacher cache (run once)
python rif_cache_teacher.py \
    --data trainingdata/ohsuz_tiny-textbooks-edu_train.txt \
    --teacher google/gemma-4-E4B-it \
    --output checkpoints/teacher_cache.pt

# Step 2: Train with cached states (~8× faster, no teacher in memory)
python rif_assimilator.py \
    --data trainingdata/ohsuz_tiny-textbooks-edu_train.txt \
    --use-cache checkpoints/teacher_cache.pt \
    --max-steps 10000 \
    --lr 0.0001
```

**Loss target:** Alignment loss < 0.5 before proceeding to Phase 2.

---

## Phase 2: RIF Import (GeoMind Update Only)

In Phase 2, the RIF projectors are **frozen** and only GeoMind's weights are updated. The projectors act as fixed alignment targets, pulling GeoMind's geometry toward the teacher's representation space.

```bash
python rif_assimilator.py \
    --data trainingdata/ohsuz_tiny-textbooks-edu_train.txt \
    --use-cache checkpoints/teacher_cache.pt \
    --phase2 \
    --max-steps 20000
```

Phase 2 automatically increases `--lr` to 0.0005 and `--weight-align` to 3.0 unless overridden.

**Loss target:** Alignment loss < 0.3 (plateau). SFT loss should be improving simultaneously.

---

## v1 → v2 Migration

If upgrading from GeoMind v1 (single-stream 248D) to v2 (4-stream 992D):

```bash
# 1. Set NUM_DECOMP_STREAMS = 4 in config.py (already done)

# 2. Migrate checkpoint (copies v1 weights to all 4 streams as warm start)
python migrate_checkpoint_v2.py --verify

# 3. Copy migrated checkpoint over the main checkpoint
copy checkpoints\e8_agent_model_v2.pt checkpoints\e8_agent_model.pt

# 4. Resume training — all 4 streams start from v1 weights and diverge gradually
python rif_assimilator.py --data trainingdata/... --stabilize-only --stabilize 2000
```

**Migration guarantees:**
- Stream 0 (SO(16)) weights = v1 checkpoint exactly — no regression
- Streams 1-3 = copies of stream 0 (warm start, not random)
- Basis change matrices = identity (streams start identical, diverge through training)
- Herald modules = zero (no cross-stream noise at start)

---

## v2 Alignment Strategy

In v2 mode, the RIF engine aligns each stream against its corresponding E8 decomposition:

| Stream | Decomposition | Alignment Target |
|--------|--------------|-----------------|
| 0 | SO(16) | Full 248D + Cartan/Integer/Half-integer sub-sectors + block internals |
| 1 | E7 × SU(2) | E7 adjoint (133D) + SU(2) adjoint (3D) + fundamental (112D) |
| 2 | E6 × SU(3) | E6 adjoint (78D) + SU(3) adjoint (8D) + fund (81D) + conj (81D) |
| 3 | SU(9) | Adjoint (80D) + antisymmetric (84D) + conjugate (84D) |

Total alignment surface per layer: **992D** (4 × 248D).

---

## Scaling to Cloud (v2 Medium / Large / Billion)

To scale beyond what local hardware supports, change `HIDDEN_DIM` in `config.py` before migrating:

| Target | HIDDEN_DIM | Total Params | Cloud GPU |
|--------|-----------|--------------|-----------|
| v2 Small (local) | 4,096 | ~90M | RTX 2000 Ada (8GB) |
| v2 Medium | 16,384 | ~205M | A100 40GB |
| v2 Large | 32,768 | ~357M | A100 80GB |
| v2 Billion | 131,072 | ~1.15B | 2× A100 80GB |

**Recommended cloud:** RunPod or Vast.ai with A100 40GB at ~$1.50/hr.

Estimated training cost (50k steps Phase 1+2 with cache):
- v2 Medium: ~$7.50 overnight
- v2 Large: ~$15 overnight

---

## Teacher Model

**Chosen teacher:** `google/gemma-4-E4B-it`

Why E4B specifically:
- Visual and audio modality capabilities (not available in 12B/27B)
- Efficient: ~4B effective parameters despite multimodal capacity
- Fits in ~4GB VRAM (quantized), leaving room for GeoMind v2 (~2GB) + optimizer

Login before cache building:
```bash
huggingface-cli login
```

---

## Loss Targets & Checkpointing

| Stage | Loss Target | Action |
|-------|------------|--------|
| Stabilization | SFT < 8.0 | Proceed to Phase 1 |
| Phase 1 end | Alignment < 0.5 | Proceed to Phase 2 |
| Phase 2 plateau | Alignment < 0.3 | Training complete |

Checkpoints are saved to `checkpoints/e8_agent_model.pt` every `--save-every` steps (default 100).
RIF projector checkpoint: `checkpoints/rif_engine.pt`

---

## Hyperparameters

| Parameter | Phase 1 | Phase 2 |
|-----------|---------|---------|
| Learning rate | 0.0001 | 0.0005 |
| Alignment weight | 1.0 | 3.0 |
| Batch size | 1 chunk | 1 chunk |
| Grad clip | AGC (0.05x norm) | AGC (0.05x norm) |
| Optimizer | FinslerIGO (wd=0.0) | FinslerIGO (wd=0.0) |

These are set automatically — override with `--lr` and `--weight-align` if needed.
