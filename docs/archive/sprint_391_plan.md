# Sprint 391 Implementation Plan: Benchmark Holdout Stability, Temperature Invariance & Controller Decoupling

## Diagnostics: Why the Stats Were Jumping
1. **Single-Sentence Validation Noise ($N=1$)**:
   - In Sprint 389, the 100-chunk validation holdout was replaced by probing chunk 0 of each domain slice (`slice_chunks == 0.0`).
   - A single sentence is an extreme point sample. In `cloze_part01`, an easy sentence yielded $VL = 3.66$ ($IVPPL = 38.9$). In `cloze_part05`, a dense academic sentence yielded $VL = 7.49$ ($IVPPL = 1806.5$).
   - This 46-fold perplexity fluctuation ($38 \to 1806$) was pure sample variance between individual sentences across disparate datasets—not model instability.
2. **Controller Feedback Loop / Instability Cascade**:
   - Because $VL$ swung wildly on single sentences, the validation velocity controller registered $\Delta AVL > 0.005$ on every hard sentence, misinterpreting natural variance as "divergence".
   - The controller repeatedly slashed the learning rate and inflated the training temperature ($TEMP \to 1.20$).
   - Inflating training temperature to $1.20$ flattened output logits, degraded the gradient signal $\frac{p - y}{T}$, lowered certainty, increased entropy, and caused the model to struggle.
3. **Log Formatting Corrupted String**:
   - In `train.cl` lines 2185-2186, `cartan_string_concat(ema_val_loss)` omitted `cartan_float_to_string()`, causing `AVL: .49917` and `AVPPL: .54` to print with missing integer digits in the log file.
4. **Is Learning Actually Happening?**:
   - YES. In the training log, mean training loss $ATL$ descended cleanly from $7.53 \to 4.55$ ($ATPPL: 1872 \to 94.9$), and semantic vector analogies passed with even higher margins (Analogy 2 margin expanded from $+0.110 \to +0.141$).
   - However, the noisy validation probe and dynamic temperature inflation created the appearance and symptoms of chaotic instability.

## Proposed Modifications
1. [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl):
   - **Re-anchor Validation to Multi-Sample Benchmark**:
     - Remove the noisy single-sentence slice probe on chunk 0.
     - Evaluate the fixed, balanced 100-chunk holdout cache via `geomind_compute_validation_loss()` at engine start and every full round-robin cycle across the 10 datasets (every 500 chunks).
     - Result: Validation loss will be evaluated on the EXACT SAME 100 sentences every cycle, producing a smooth, monotonic, rock-solid generalization curve.
   - **Lock Training Temperature ($T=1.0$)**:
     - Disable dynamic temperature inflation. Training temperature must remain fixed at $T=1.0$ (or user-specified base temperature), standard for autoregressive language models.
   - **Stabilize Learning Rate**:
     - Preserve smooth Target-Loss Progress Annealing ($atl \to t\_loss$).
     - Remove the twitchy micro-velocity and gap spring braking on validation deltas. Retain emergency divergence braking only for true loss blowups ($TL > 10.0$).
   - **Fix Log String Formatting**:
     - Wrap `ema_val_loss` and `vppl` with `cartan_float_to_string()` in `l3_a` and `l3_b`.
2. Compilation & Verification:
   - Build `geomind.exe` with `cartanc.exe` and Zig `-O3` LTO.
   - Verify SHA-256 parity across all 3 paths.
   - Run `--eval-analogy` to confirm semantic vector arithmetic integrity.
   - Reset `corpus.json` and `checkpoint_status.txt` for clean user start.
