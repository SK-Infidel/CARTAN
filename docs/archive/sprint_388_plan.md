# Sprint 388 Plan: Evaluation Symmetry & Calibration: Pure Unweighted Cross-Entropy, Validation Context Continuity & Independent Evaluation Temperature

## Objectives
1. **Pure Unweighted Cross-Entropy for Perplexity Parity**:
   - Decouple SGD gradient weighting (`eff_ic`) from reported loss and perplexity.
   - Compute `ce_loss = -log(tgt_p)` purely without arbitrary IC multipliers, ensuring authentic mathematical cross-entropy and unbiased perplexity comparison across all datasets.
2. **Temperature-Aware Evaluation & Independent Evaluation Temperature ($T_{\text{eval}}$)**:
   - Fix `tgt_p` in `geomind_softmax_loss_delta` to respect temperature scaling (`inv_temp`, `inv_sum_t`) when `temp > 1.0`.
   - Add dedicated `g_val_temperature` (default $1.0$, CLI `-val-temp <float>`) for calibrated out-of-domain holdout evaluation.
3. **Validation Context Continuity (Eliminating 100 Cold Starts)**:
   - Preserve recurrent hidden state across validation chunks during holdout evaluation, giving validation the same continuous sequential context that training enjoys.
   - Reliably save and restore training's active recurrent hidden state before and after validation.
4. **Symmetric Instantaneous & Smoothed Reporting**:
   - Align reported metrics to display instantaneous `ITPPL = exp(tl)` and `IVPPL = exp(vl)` alongside smoothed `ATPPL = exp(atl)` and `AVPPL = exp(avl)`.
   - Fix EMA initialization so validation does not drag step-0 untrained loss for 100 intervals.
5. **Empirical Verification**:
   - Clean native compilation via `cartanc.exe`.
   - Verify bit-for-bit binary parity across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
   - Verify 4/4 semantic vector analogies pass at Rank 1.
