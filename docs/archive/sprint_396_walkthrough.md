# Sprint 396 Walkthrough: Corpus Manifest Clean Zero-Reset & Continuous Multi-Domain ATL Moving Average

## Executive Summary
Sprint 396 addressed two critical user-identified operational defects:
1. **Corpus Not Reset**: `test/geomind/trainingdata/corpus.json` was resuming an old run mid-corpus (dataset 3, offset 954KB). It has now been cleanly reset to dataset 0, byte offset 0.0 across all 10 datasets, epoch 1.0, and base learning rate $0.0022$.
2. **ATL Stagnation Bug**: In 1-chunk interleaved streaming (`slice_limit = 1.0`), `domain_losses` was only being set inside the 50-chunk interval check on `d_idx`. Because 50 is a multiple of 10, only slot 9 was ever updated. Slots 0 through 8 remained 0.0, causing `count_dl` to evaluate to 1.0 and `ATL` to identically equal `TL` on every report.

---

## Technical Implementations

### 1. Corpus Manifest Clean Zero-Reset
* **File**: [`test/geomind/trainingdata/corpus.json`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/corpus.json)
* Zeroed all dataset offsets:
  - `current_dataset_index`: 0.0
  - `current_offset`: 0.0
  - `current_epoch`: 1.0
  - `current_lr`: 0.0022
  - `offsets`: `[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]`

### 2. Continuous Multi-Domain ATL Moving Average
* **File**: [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L2162-L2215)
* Moved per-domain loss tracking out of the 50-chunk interval check and into the per-chunk completion block:
  - On every chunk, computes `c_loss = chunk_loss / g_last_chunk_valid_steps`.
  - Updates `domain_losses[d_idx]` via an exponential moving average ($0.85$ retention, $0.15$ step).
* On 50-chunk telemetry intervals:
  - Aggregates `sum_dl / count_dl` across all 10 active domains to form `mix_loss`.
  - Smooths `ema_train_loss` via a continuous mixture EMA ($0.80$ retention, $0.20$ step).
  - Assigns `atl = ema_train_loss`.
* Completely separates instantaneous training loss `TL` from multi-domain mixture moving average `ATL`.

---

## Verification & Empirical Proof
1. **Compilation**: Clean build via `cartanc.exe` with native Zig/Clang `-O3` LTO.
2. **Binary Parity**: SHA-256 `BBBF64CD4774E2DE1B5F3DA8BE9B6EECDD523A7279530C8C1766212234761E25` synchronized across `geomind.exe`, `test/geomind/geomind.exe`, and `bin/geomind.exe`.
3. **Analogy Verification**: 4/4 semantic vector analogies passing at Rank 1:
   - King - man + woman = queen (+0.107 margin)
   - he - him + her = she (+0.151 margin)
   - father - man + woman = mother (+0.093 margin)
   - boy - man + woman = girl (+0.260 margin)
4. **Live Verification on GPU**:
   - Resumed cleanly from dataset 0, offset 0.0 at `LR: 0.0022`.
   - Verified genuine distinction and smooth moving average between `TL` and `ATL`:
     - Step 50: `TL: 4.85002 | ATL: 5.02931 | ITPPL: 127.743 | ATPPL: 152.827`
     - Step 100: `TL: 4.70127 | ATL: 4.98134 | ITPPL: 110.087 | ATPPL: 145.669`
