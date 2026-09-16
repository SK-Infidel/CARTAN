# Sprint 349 Implementation Plan: Perplexity-Based Adaptive Learning Rate & Post-Scale-Up Spike Probation

## Objectives
1. Couple learning rate adaptation directly to perplexity (`VPPL = exp(ema_val_loss)`).
2. Protect against premature scale-up / LR boost by monitoring post-boost holdout perplexity across a probation window.
3. Dampen LR back to baseline if perplexity spikes across consecutive evaluation intervals.
4. Detect general sustained perplexity divergence across training.
5. Provide non-instantaneous multi-interval filtering to prevent false triggers when hitting difficult material.
6. Recompile via `cartanc.exe` and synchronize 4 production binaries.

## Architectural Design
- **Validation Perplexity (`VPPL`)**: Calculated directly from holdout validation loss (`ema_val_loss`), isolating model generalization from current training batch difficulty.
- **Probation Mechanism**: On saddle point escape / boost, record `boost_base_vppl` and activate probation for 6 intervals. If `VPPL > boost_base_vppl * 1.18` for 2 consecutive intervals, damp LR to baseline (`boost_base_lr`).
- **General Surge Brake**: If `VPPL > best_ppl * 1.30` for 3 consecutive intervals, apply `lr = lr * 0.90`.
- **Zero-False-Positive Filter**: Requiring 2-3 consecutive intervals (200-300 lines) ensures transient passages of harder material do not cause premature rollbacks.

## Execution Checklist
- [x] Add tracking variables to `train.cl` (`boost_probation_active`, `boost_base_vppl`, `boost_spike_count`, `ppl_surge_count`).
- [x] Compute `vppl` before adaptive LR evaluations.
- [x] Implement post-scale-up perplexity probation check.
- [x] Implement general sustained perplexity surge brake.
- [x] Record pre-boost state on saddle point escape.
- [x] Compile via `cartanc.exe` and synchronize all 4 production binaries.
- [x] Perform smoke test and verify telemetry (`TL: 4.03`, `VPPL: 94-96`).
- [x] Update `ISSUES.md` (`[ISSUE-100]`), `CHANGELOG.md` (`[8.306.0]`), and archive documentation.
