# Sprint 392 Walkthrough: Telemetry Modernization & Multi-Domain Mixture Moving Average

## Overview
Sprint 392 addressed two key user observations:
1. `ATPPL` previously fluctuated between 83 and 109 because a fast single-stream 0.70 EMA was heavily swayed by alternating between cloze and web text slices.
2. The user requested surfacing `TTemp` and `VTemp` alongside the learning rate, and organizing the live telemetry into a clean 4-line format.

---

## Changes Implemented

### 1. Multi-Domain Mixture Moving Average (`domain_losses`)
- **Root Cause**: An EMA with $\alpha = 0.30$ ($0.70$ retention) retains only $2.8\%$ of context over 10 slices, causing it to bounce with each domain rotation.
- **Resolution**: Implemented a 10-domain loss memory buffer (`domain_losses`). On each 50-chunk slice completion, `domain_losses[d_idx]` is updated. `atl` is calculated as the balanced mean over all active observed domains:
  $$\bar{L}_{\text{mix}} = \frac{1}{M} \sum_{k=0}^{M-1} L_k$$
  `ATPPL = exp(atl)` now reflects the genuine expected perplexity of the entire curriculum mixture without artificial slice-to-slice oscillations.

### 2. Four-Line Live Telemetry Layout
Re-architected both stdout and `logs/stage2_ce_training.log` into the exact requested 4-line structure:
```text
[GeoMind CAUSAL CE Stream] Ep 1.0/Inf | D[9.0/10.0: test/geomind/trainingdata/mined_expanded_corpus_cloze_part05.txt]
  Progress -> 1.68228% (2085.41 / 123964 KB) | LR: 0.00137618 | TTemp: 1.0 | VTemp: 1.0
  Train -> TL: 4.47316 | ATL: 4.47316 | ITPPL: 87.6334 | ATPPL: 87.6334 | ENT: 7.10548b | CERT: 7.52235%
  Val   -> VL: 4.79543 | AVL: 4.79543 | IVPPL: 120.957 | AVPPL: 120.957 | VENT: 7.15961b | VCERT: 7.23345%
```

### 3. Hyperparameter Visibility
- Displayed `TTemp` (`g_train_temperature`) and `VTemp` (`g_val_temperature`) on Line 2 of live streaming telemetry.
- Updated the engine startup banner and epoch completion logs to report `TTemp` and `VTemp`.

---

## Verification
- Built native binary with self-hosting compiler `cartanc.exe` and Zig/Clang `-O3` LTO.
- Verified bit-for-bit SHA-256 parity:
  - `19870FBA4D596EC4BF2C89B4A1DC6E216C2923775CCAA43EBE30A0A26E0B4ED5` across `./geomind.exe`, `test/geomind/geomind.exe`, and `bin/geomind.exe`.
- Verified 4/4 semantic vector analogies passing at Rank 1:
  - King - man + woman = queen (Rank 1, Margin +0.108693)
  - he - him + her = she (Rank 1, Margin +0.14094)
  - father - man + woman = mother (Rank 1, Margin +0.0931411)
  - boy - man + woman = girl (Rank 1, Margin +0.260986)
- Verified dry-run telemetry execution and reset `checkpoint_status.txt` to `SUCCESS`.
