# Sprint 391 Walkthrough: Benchmark Holdout Stability, Temperature Invariance & Controller Decoupling

## Diagnostics & Root Cause
1. **Validation Stat Volatility ($IVPPL: 38 \to 1806$)**:
   - In Sprint 389, the 100-chunk holdout set was replaced by a single-sentence probe on chunk 0 of each incoming domain slice (`slice_chunks == 0.0`).
   - A single sentence is an extreme point sample. In `cloze_part01`, a simple sentence gave $VL = 3.66$ ($IVPPL = 38.9$). In `cloze_part05`, a dense academic sentence gave $VL = 7.49$ ($IVPPL = 1806.5$).
   - This 46-fold perplexity fluctuation was pure sample variance between individual sentences across disparate datasets—not model divergence.
2. **Controller Feedback Loop**:
   - Because $VL$ swung wildly on single sentences, the validation velocity controller registered $\Delta AVL > 0.005$ on every hard sentence, misinterpreting natural variance as "divergence".
   - The controller repeatedly slashed the learning rate and inflated the training temperature ($TEMP \to 1.20$).
   - Inflating training temperature to $1.20$ flattened output logits, degraded the gradient signal $\frac{p - y}{T}$, lowered certainty, increased entropy, and caused the model to struggle.
3. **Log Formatting Corrupted String**:
   - In `train.cl`, `cartan_string_concat(ema_val_loss)` omitted `cartan_float_to_string()`, causing `AVL: .49917` and `AVPPL: .54` to print with missing integer digits in the log file.

## Resolutions Implemented
1. **Multi-Sample Holdout Benchmark Re-anchored**:
   - In [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L1940), evaluated the full 100-chunk pre-tokenized holdout suite (`geomind_compute_validation_loss(holdout_init_path, cur_h_val)`) at engine startup, establishing an authentic baseline ($VL = 4.83863, IVPPL = 126.297, VENT = 6.41b, VCERT = 9.56\%$).
   - In [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L2075), scheduled periodic benchmark passes every 500 chunks (every full 10-domain round-robin cycle) across the fixed 100 holdout chunks.
   - Result: Validation metrics are evaluated on the exact same multi-sample benchmark suite, eliminating single-sentence volatility ($1806 \to 126$).
2. **Temperature Invariance Locked ($T=1.0$)**:
   - In [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L2100), disabled dynamic temperature inflation. Training temperature is strictly locked to $T=1.0$ (or user-specified base temperature), preserving sharp gradient dynamics.
3. **Stabilized Learning Rate Schedule**:
   - Removed twitchy micro-velocity and gap spring braking on validation deltas.
   - Preserved smooth Target-Loss Progress Annealing toward $lr\_floor$ ($0.0005$).
4. **Log Formatting Fixed**:
   - Wrapped `ema_val_loss` and `vppl` with `cartan_float_to_string()` in `l3_a` and `l3_b`.
5. **Pristine State Reset**:
   - Reset `corpus.json` offsets to 0.0 and `checkpoint_status.txt` to `SUCCESS`.

## Verification
- Built native binary with `cartanc.exe` + Zig `-O3` LTO:
  - SHA-256: `9A97892B4C98A0AD607557D4DE131AD2692321402C0D78155D41EC5B549B9731` across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
- `--eval-analogy`: Verified all 4/4 semantic vector analogies pass at Rank 1.
- `--train-ce` dry run verified:
  - Baseline Holdout Loss: 4.83863 | Baseline VPPL: 126.297 | VENT: 6.41684b | VCERT: 9.55922%
  - D[1.0/10.0: fineweb]: TL: 4.954 | ATL: 4.954 | ITPPL: 141.76 | VL: 4.838 | IVPPL: 126.297 | TEMP: 1.0
  - D[2.0/10.0: cloze_part01]: TL: 4.448 | ATL: 4.802 | ITPPL: 85.50 | VL: 4.838 | IVPPL: 126.297 | TEMP: 1.0
  - D[3.0/10.0: openwebtext]: TL: 4.826 | ATL: 4.809 | ITPPL: 124.81 | VL: 4.838 | IVPPL: 126.297 | TEMP: 1.0
