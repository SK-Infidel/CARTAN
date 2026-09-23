# Sprint 393 Implementation Plan: Dual Adaptive Temperature Modulation Controller

## Problem Statement
In Sprint 391, dynamic temperature updates were completely disabled (`g_train_temperature = base_train_temp;`) to stop feedback hunting caused by noisy single-sentence validation probes. Additionally, `g_val_temperature` was purely static. Consequently, neither `TTemp` nor `VTemp` adapted, remaining frozen at 1.0.

Now that Sprint 391 & 392 have stabilized both evaluation benchmarks (100-chunk multi-domain holdout suite) and training loss metrics (10-domain mixture moving average `atl`), the generalization gap:
$$val\_gap = ema\_val\_loss - atl$$
is smooth, statistically sound, and monotonic. We can now safely reactivate principled, continuous dynamic temperature adaptation for both `TTemp` and `VTemp`.

---

## Technical Details

### 1. `TTemp` Adaptive Gradient Softening
- **Objective**: Soften backpropagation gradients when in-sample training begins to outpace generalization ($val\_gap > 0.20\text{ nats}$), preventing overfitting. Anneal smoothly back to baseline $T_0$ when generalization is aligned.
- **Formulation**:
  $$target\_ttemp = base\_train\_temp + \text{clamp}((val\_gap - 0.20) \times 0.40, 0.0, 0.35)$$
  If active divergence velocity occurs ($\Delta AVL > 0.005$), add $+0.05$ divergence damping.
  Smooth with EMA ($0.85$ retention, $0.15$ adaptation rate):
  $$g\_train\_temperature = g\_train\_temperature \times 0.85 + target\_ttemp \times 0.15$$
  Bounded strictly within $[base\_train\_temp, 1.40]$.

### 2. `VTemp` Adaptive Out-Of-Sample Calibration
- **Objective**: Calibrate evaluation softmax temperature against out-of-sample uncertainty ($val\_gap > 0.0\text{ nats}$), scaling prediction confidence to match distribution shift without distorting underlying cross-entropy.
- **Formulation**:
  $$target\_vtemp = base\_val\_temp + \text{clamp}(val\_gap \times 0.40, 0.0, 0.40)$$
  Smooth with EMA ($0.85$ retention, $0.15$ adaptation rate):
  $$g\_val\_temperature = g\_val\_temperature \times 0.85 + target\_vtemp \times 0.15$$
  Bounded strictly within $[base\_val\_temp, 1.40]$.

---

## Verification Plan
1. Edit [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl).
2. Compile with `cartanc.exe` and verify binary hash parity across `./geomind.exe`, `test/geomind/geomind.exe`, and `bin/geomind.exe`.
3. Verify 4/4 semantic vector analogies pass at Rank 1.
4. Execute dry run to verify dynamic adaptation of `TTemp` and `VTemp` on Line 2.
5. Kill dry run immediately, restore `checkpoint_status.txt` to `SUCCESS`.
6. Record updates in `CHANGELOG.md`, `ISSUES.md`, and `docs/archive/`.
