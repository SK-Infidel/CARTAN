# Sprint 349 Walkthrough: Perplexity-Based Adaptive Learning Rate & Post-Scale-Up Spike Probation

## 1. Problem Statement
Cross-entropy loss is logarithmic, meaning significant exponential uncertainty surges (perplexity $\text{PPL} = \exp(\text{Loss})$ spiking $+30\%$ to $+60\%$) correspond to small numerical changes in loss ($+0.25$ to $+0.50$).
When scaling up learning rate during warm recovery or saddle-point escape, the optimizer previously lacked a feedback mechanism to detect if the scale-up was premature and destabilizing the model. Furthermore, any sensitivity check needed to be non-instantaneous to avoid triggering when encountering harder material in the corpus.

## 2. Technical Implementation
1. **Holdout Perplexity Integration (`train.cl:1397-1402`)**:
   - `VPPL` is calculated directly on the fixed holdout evaluation set (`cloze_validation_holdout.txt`):
     $$\text{VPPL} = \exp(\text{AVL})$$
   - This isolates generalization quality from the varying linguistic difficulty of current training chunks.

2. **Post-Scale-Up Probation Window (`train.cl:1439-1470`)**:
   - Upon triggering saddle point escape (`lr = initial_stage_lr * 0.70`), the system stores:
     - `boost_base_vppl = vppl`
     - `boost_base_lr = old_lr`
     - `boost_probation_active = 1.0`
   - Over a 6-interval probation period (600 lines), if `VPPL` spikes $\ge 18\%$ above `boost_base_vppl` for 2 consecutive evaluation intervals, the scale-up is flagged as premature:
     - Damps `lr` back down to `boost_base_lr`.
     - Logs the exact spike percentage and interval count.
     - Resets probation and stagnation counts cleanly.
   - If `VPPL` remains stable ($\le 1.02\times$), `boost_spike_count` resets.
   - Once 6 intervals pass without sustained spike, the scale-up is finalized as stable.

3. **General Sustained Perplexity Surge Brake (`train.cl:1472-1493`)**:
   - Across general training, if `VPPL` exceeds the best historical validation perplexity by $> 30\%$ for 3 consecutive intervals (300 lines), brakes `lr = lr * 0.90` to arrest representational drift.

## 3. Verification & Parity
1. **Compiler**: Rebuilt via self-hosting `cartanc.exe`.
2. **Binary Parity**: Verified 4-way SHA-256 match across all production binaries (`66D2CD12E5B11211E6883DB77E484D681CB1480F77D853EBD65292600D8509E8`):
   - `test/geomind/geomind.exe`
   - `./geomind.exe`
   - `bin/geomind.exe`
   - `build/geomind.exe`
3. **Smoke Test Execution**:
   - Ran `./geomind.exe --train-cloze` for 6 seconds.
   - Telemetry verified: `TL: 4.03139`, `ATL: 4.45424`, `AVL: 4.57146`, `VPPL: 94.29 -> 96.68`, `LR: 0.030`.
   - Process cleanly terminated; ready for user interactive execution.
