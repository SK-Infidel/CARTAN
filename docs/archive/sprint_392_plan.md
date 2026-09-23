# Sprint 392 Implementation Plan

## Objective
1. Diagnose and eliminate `ATPPL` moving average oscillations across interleaved domain rotations by replacing single-stream 0.70 EMA with a balanced 10-domain mixture tracker.
2. Reformat live telemetry into the requested clean 4-line structure, surfacing `TTemp` and `VTemp` alongside completion percentage and learning rate.
3. Synchronize `train.cl`, compile with `cartanc.exe`, verify zero regressions via analogy evaluation, and update documentation.

---

## Technical Details

### 1. Multi-Domain Mixture Moving Average (`domain_losses`)
- **Problem**: With 10 interleaved datasets rotating every 50 chunks, a 0.70 EMA (`$\alpha = 0.30$`) only has an effective memory of ~3 slices. When alternating between structured cloze ($TL \approx 4.25$) and rich web prose ($TL \approx 4.85$), `ATPPL` oscillates between ~83 and ~109.
- **Solution**:
  - Allocate a `domain_losses` vector for the registered datasets.
  - When a 50-chunk slice completes on domain `d_idx`, update `domain_losses[d_idx] = tl`.
  - Compute `atl = mean(domain_losses)` across all observed domains:
    $$\bar{L}_{\text{mix}} = \frac{1}{M} \sum_{k=0}^{M-1} L_k$$
  - Compute `ATPPL = exp(atl)` as the genuine expected perplexity of the curriculum mixture.

### 2. Four-Line Telemetry Layout
- **Line 1 (Domain Header)**: Everything up to dataset name:
  `[GeoMind %s Stream] Ep %s/%s | D[%s/%s: %s]`
- **Line 2 (Progress & Hyperparameters)**:
  `  Progress -> %s%% (%s / %s KB) | LR: %s | TTemp: %s | VTemp: %s`
- **Line 3 (Train Metrics)**:
  `  Train -> TL: %s | ATL: %s | ITPPL: %s | ATPPL: %s | ENT: %sb | CERT: %s%%`
- **Line 4 (Validation Metrics)**:
  `  Val   -> VL: %s | AVL: %s | IVPPL: %s | AVPPL: %s | VENT: %sb | VCERT: %s%%\n`

### 3. Engine Banner & Epoch Completion Synchronization
- Update engine initialization banner to display both `TTemp` and `VTemp`.
- Update epoch summary printout to report `TTemp` and `VTemp`.

---

## Verification Plan
1. Compile via `cartanc.exe` + Zig/Clang `-O3` LTO.
2. Verify binary SHA-256 parity across distribution paths.
3. Run `./geomind.exe --eval-analogies` to guarantee zero model regression.
4. Verify dry-run output formatting.
5. Record in `CHANGELOG.md`, `ISSUES.md`, and `docs/archive/`.
