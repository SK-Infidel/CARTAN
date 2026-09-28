# Sprint 429 Walkthrough: Stage 3 SFT Target-Loss Annealing & Manifest Calibration

## Overview & Executive Summary

In Sprint 429, we wired all architecture enhancements and convergence controls into Stage 3 Supervised Fine-Tuning (`--train-sft`):
1. **Target-Loss Progress Annealing**: Extended monotonic learning rate decay to `stage_mode == 3.0` with `initial_loss_ref = 4.20`, allowing smooth interpolation from `stage_ceiling_lr = 0.0015` down to `lr_floor = 0.0003` as `atl` approaches `t_loss` (default: 2.00).
2. **SFT Hyperparameter Calibration**: Calibrated the fine-tuning envelope to prevent catastrophic forgetting of Stage 2 CE foundational knowledge (ceiling `0.0015`, floor `0.0003`, starting rate `0.0012`).
3. **Resumed LR Precision**: Lowered manifest saved learning rate restoration threshold from `0.0005` to `0.0001`, enabling resumed SFT runs to preserve annealed rates near floor without spurious resets.
4. **Manifest State Initialization**: Refreshed [`test/geomind/trainingdata/sft_manifest.json`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/sft_manifest.json) under the Sprint 428 schema with 17 verified datasets, all offsets at `0.0`, starting LR `0.0012`, epoch `1.0`, and zeroed domain loss vectors.

---

## Key Changes

### 1. Engine Core ([`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl))
- **Lines 1828–1833**: Lowered saved LR restoration threshold to `>= 0.0001` so fine-tuning rates approaching `0.0003` are preserved across restarts.
- **Lines 1903–1906**: Preferred `storytelling_corpus_clean.txt` with fallback to `storytelling_corpus.txt` in SFT dataset resolution.
- **Lines 1928–1936**: Configured `stage_mode == 3.0` bounds (`lr_floor = 0.0003`, `stage_ceiling_lr = 0.0015`, default starting `lr = 0.0012`).
- **Lines 2632–2646**: Enabled Target-Loss Progress Annealing for `stage_mode == 3.0` using `initial_loss_ref = 4.20`.

### 2. Multi-Dataset Manifest ([`test/geomind/trainingdata/sft_manifest.json`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/sft_manifest.json))
- Configured 17 verified datasets:
  - 4 dialogue / instruction corpora (`reddit_casual`, `reddit_qa`, `oasst1`, `alpaca`)
  - 5 text corpora (`fineweb`, `openwebtext`, `wikitext103`, `arxiv`, `tinystories`)
  - 6 cloze curriculum parts (`mined_expanded_corpus_cloze_part01..06`)
  - 2 narrative corpora (`storytelling_corpus_clean`, `hf_alpaca_stories`)
- All 17 dataset offsets reset to `0.0`, `bytes_ingested_epoch` reset to `0.0`, `current_dataset_index` reset to `0.0`, and `domain_losses` / `val_domain_losses` zeroed for a clean start.

### 3. Binary Synchronization
- Rebuilt native [`bin/geomind.exe`](file:///C:/Users/rich-/source/repos/CARTAN/bin/geomind.exe) via Zig `-O3 LTO Vectorized Pass Pipeline`.
- Synchronized across all 4 repository locations (`bin/`, `build/`, root, and `test/geomind/`).

---

## Empirical Verification (100% Pass)

### Regression Suite: [`test/geomind/nses/test_sprint16_sft_annealing.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/nses/test_sprint16_sft_annealing.car)
```
=================================================================================
  SPRINT 429 QA HARNESS: STAGE 3 SFT ANNEALING & MANIFEST VALIDATION
  Verification of Target-Loss Progress Annealing & 17-Dataset Verification
=================================================================================

[TS-16.1] Validating sft_manifest.json Schema & Dataset Existence...
  -> Manifest Dataset Index: 0 (Expected: 0)
  -> Manifest Current Offset: 0 (Expected: 0)
  -> Manifest Current Epoch: 1 (Expected: 1)
  -> Manifest Starting LR: 0.0012 (Expected: 0.0012)
  -> Manifest Bytes Ingested: 0 (Expected: 0)
  -> Total SFT Datasets Configured: 17 (Expected: 17)
  -> All 17 datasets verified present on disk.
[PASS] TS-16.1: SFT manifest initialized cleanly with 17 verified datasets.

[TS-16.2] Verifying Stage 3 SFT Learning Rate Boundaries...
  -> SFT LR Floor: 0.0003 | Ceiling: 0.0015 | Start: 0.0012
[PASS] TS-16.2: SFT learning rate boundary specifications validated.

[TS-16.3] Simulating SFT Target-Loss Annealing Trajectory (4.20 -> 2.00)...
  -> ATL 4.20 (Start)   Target LR: 0.001500 (Expected: 0.001500)
  -> ATL 3.65 (75%)     Target LR: 0.001200 (Expected: 0.001200)
  -> ATL 3.10 (Midpoint) Target LR: 0.000900 (Expected: 0.000900)
  -> ATL 2.55 (25%)     Target LR: 0.000600 (Expected: 0.000600)
  -> ATL 2.00 (Target)   Target LR: 0.000300 (Expected: 0.000300)
[PASS] TS-16.3: Strict monotonic learning rate descent empirically verified.

[TS-16.4] Verifying EMA Smoothing Step Dynamics & Clamping Bounds...
  -> Sim LR after 20 EMA steps toward target: 0.000623 (Smooth gradual convergence)
[PASS] TS-16.4: Clamping guardrails and EMA step smoothing validated.

=================================================================================
  ALL SPRINT 429 REGRESSION GATES PASSED (100% EMPIRICAL VERIFICATION)
=================================================================================
```

### Full Subsystem Verification: `bin/geomind.exe --verify`
```
[GeoMind Main] Running E8 Riemannian & Hopfield Physics Solvers Verification...
[GeoMind Main] RKF45 Integration Step Complete. Next Y: 1.64844
[GeoMind Main] Hopfield Spin Relaxation Step Complete.
[GeoMind RLHF] Human Reward (+1.0 Received): Reinforcing Hopfield attractor basin trajectory (CE Loss: 3.92525)...
[GeoMind NSES Plasticity] Reinforced active semantic graph pathways for Domain 0.0 (+0.10 weight boost).
[GeoMind SFT Online] Human Correction Received: "CARTAN lang"
[GeoMind SFT Online] Executing online SFT natural gradient update over user correction...
[GeoMind SFT Online] Real SFT gradient update executed over correction (Final Loss: 1.9375).
[GeoMind NSES Plasticity] Consolidated correction target into resident semantic graph memory.
[GeoMind Main] 8-Stream Lie Cortical Submanifold Dispatch Verified Cleanly.
[GeoMind Main] All GeoMind Subsystems Verified Cleanly.
```

---

## How to Launch Stage 3 SFT Training

Rick can now launch Stage 3 SFT fine-tuning with full state continuity, gated sleep, double-buffering, and Target-Loss Progress Annealing:

```powershell
.\bin\geomind.exe --train-sft
```

Optional CLI overrides:
- `-target-loss 2.00` (default target stopping loss is 2.00)
- `-lr 0.0012` (default starting learning rate ceiling is 0.0012)
- `-epochs <n>` (default is unlimited continuous epochs until target loss reached)
