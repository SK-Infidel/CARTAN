# Sprint 378 Implementation Plan: Synchronized Dynamic Divergence Controllers

## Objective
Resolve `[ISSUE-128]`: Fix divergence controller desynchronization where training loss ($TL$) and temperature ($T$) stay pinned at their floors while generalization divergence increases.

## Root Cause Analysis
1. **Unrealistic Divergence Gap Threshold**: Divergence detection checked `val_gap > 1.20`. Real-world text baseline gap is $0.20 - 0.40$ nats; divergence begins at $0.50$ nats. In live training, $val\_gap \approx 1.13$ nats ($VPPL \approx 517$ vs $TPPL \approx 221$), so `val_gap > 1.20` failed, cooling $T \to 1.0$.
2. **Velocity Divergence Blinding**: $excess\_vel = v\_growth - t\_growth$ became negative whenever noisy training chunks had temporary positive $t\_growth$, resetting divergence flags.
3. **Unresponsive Learning Rate Controller**: Checked `ema_val_loss > atl * 1.35 && (ema_val_loss - atl) > 1.20`, which failed to trigger when $atl = 5.12$ (required $VL > 6.91$). LR remained pegged at $0.0024$, continuously hammering overfit weights.
4. **Standalone Action Logs**: `printf("[Adaptive LR] ...")` prints violated the required clean 3-line telemetry format.

## Implementation Steps
1. **Dynamic Divergence Threshold (`test/geomind/train.cl`)**:
   - Continuous scaling: $val\_gap = ema\_val\_loss - atl$.
   - Baseline normal gap: $\le 0.50\text{ nats}$.
   - Excess divergence scale: $excess\_scale = val\_gap - 0.50$ when $val\_gap > 0.50$.
   - Target temperature: $target\_temp = 1.0 + excess\_scale \times 0.35$ (bounded by ceiling $1.45$).
   - Velocity tracking: If $v\_growth > 0.001$, compute $excess\_vel = v\_growth - \min(t\_growth, 0.0)$, ensuring positive training spikes cannot mask rising validation loss.
   - Smooth 15% momentum update during active divergence; smooth 5% cooling when $val\_gap \le 0.50$.
2. **Synchronized Learning Rate Braking (`test/geomind/train.cl`)**:
   - Flag $val\_divergent = 1.0$ whenever $val\_gap > 0.60$ or $T > 1.02$, immediately freezing target-loss progress annealing from boosting LR.
   - Smoothly brake LR when $val\_gap > 0.70$ ($lr = lr \times 0.97$) and $val\_gap > 1.00$ ($lr = lr \times 0.94$), bounded by $eff\_floor$.
   - Couple effective ceiling: $eff\_ceiling = stage\_ceiling\_lr \times \sqrt{base\_train\_temp / g\_train\_temperature}$.
3. **Telemetry Layout Enforcement (`test/geomind/train.cl`)**:
   - Remove standalone `[Adaptive LR]` print statements to keep the 3-line format strictly intact.
4. **Compile & Empirical QA**:
   - Compile cleanly via `cartanc.exe`.
   - Verify bit-for-bit SHA-256 binary match across deployment paths.
   - Run `--eval-analogy` to verify 4/4 semantic analogies pass at Rank 1.
   - Document in `ISSUES.md`, `CHANGELOG.md`, and `docs/archive/`.
