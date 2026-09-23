# Sprint 398 Implementation Plan: Decoupled Temperature Architecture

## Core Mission & Objectives
Resolve `[ISSUE-148]` by decoupling validation evaluation temperature (`VTemp`) from training optimization temperature (`TTemp`):
1. **Lock VTemp Invariant at Standard $T = 1.0$**:
   - Guarantee out-of-sample holdout cross-entropy and perplexity are evaluated strictly at standard $T=1.0$.
   - Quench the positive feedback loop completely: $Loss_{\text{val}}$ cannot be artificially inflated by temperature.
2. **Re-Enable Dynamic TTemp Gradient Softening**:
   - Compute the genuine, uncorrupted generalization gap: $val\_gap = ema\_val\_loss - atl$.
   - When $val\_gap > 0.10\text{ nats}$, softly scale target training temperature:
     $$target\_ttemp = base\_train\_temp + \text{clamp}((val\_gap - 0.10) \times 0.50, 0.0, 0.35)$$
   - When divergence velocity climbs ($\Delta AVL > 0.005$), add $+0.05$ dynamic softening.
   - Smooth `g_train_temperature` with $0.85/0.15$ momentum clamped in $[base\_train\_temp, 1.35]$.
   - When generalization is tight ($val\_gap \le 0.10$), dynamically anneal `TTemp` back down to $base\_train\_temp$ ($1.0$).
3. **Verify Complete Decoupling**:
   - Validation passes (`lr <= 0.0`) use `g_val_temperature = 1.0` exclusively.
   - Training passes (`lr > 0.0`) use dynamic `g_train_temperature`.
   - Dynamic `TTemp` changes never touch or distort validation holdout loss.

---

## Detailed Technical Design

### Modifications to `test/geomind/train.cl`
In `geomind_train_streaming_steady_state` (lines 2298–2301):
Replace:
```cartan
// Temperature Controller: Locked strictly to 1.0 to eliminate runaway evaluation divergence and noise oscillators
g_train_temperature = 1.0;
g_val_temperature = 1.0;
```
With:
```cartan
// Decoupled Temperature Controller:
// 1. Lock VTemp strictly to base evaluation temperature (1.0) for invariant cross-entropy
g_val_temperature = base_val_temp;
if (g_val_temperature <= 0.05) { g_val_temperature = 1.0; }

// 2. Dynamic TTemp: Adaptive training gradient softening driven by clean generalization gap
if (ema_val_loss > 0.0 && atl > 0.0) {
    let val_gap = ema_val_loss - atl;
    let val_vel = ema_val_loss - prev_ema_val_loss;

    var target_ttemp = base_train_temp;
    if (val_gap > 0.10) {
        var gap_calib = (val_gap - 0.10) * 0.50;
        if (gap_calib > 0.35) { gap_calib = 0.35; }
        target_ttemp = base_train_temp + gap_calib;
    }
    if (val_vel > 0.005) {
        target_ttemp = target_ttemp + 0.05;
    }
    if (target_ttemp > 1.35) { target_ttemp = 1.35; }
    if (target_ttemp < base_train_temp) { target_ttemp = base_train_temp; }
    g_train_temperature = g_train_temperature * 0.85 + target_ttemp * 0.15;
} else {
    g_train_temperature = base_train_temp;
}
```

---

## Verification & Acceptance Criteria
- [ ] Clean compilation via `cartanc.exe` with Zig/Clang `-O3` LTO.
- [ ] SHA-256 hash parity verified across `./geomind.exe`, `test/geomind/geomind.exe`, and `bin/geomind.exe`.
- [ ] 4/4 semantic vector analogies verified passing cleanly at Rank 1.
- [ ] `corpus.json` remains cleanly zeroed at dataset 0, offset 0.0.
- [ ] Walkthrough archived in `docs/archive/sprint_398_walkthrough.md`.
- [ ] `CHANGELOG.md` updated and `[ISSUE-148]` marked `[RESOLVED]` in `ISSUES.md`.
