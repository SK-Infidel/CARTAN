# Sprint 430 Plan: Scale-Invariant Adaptive Domain Focus & Hard-Dataset Plateau Prevention

## Objective
Eliminate the multi-domain training plateau across both Stage 2 CE Pre-training and Stage 3 SFT by upgrading the Dynamic Adaptive Domain Focus scheduler in [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl) from an uncalibrated legacy threshold (`ppl_delta > 150.0`) to a **Scale-Invariant Perplexity Ratio & Calibrated Gap Scheduler**.

---

## Root Cause Analysis
1. In Sprint 415, the focus engagement trigger was set to `ppl_delta > 150.0` when losses were $> 5.5$ (PPLs in the 200s–300s).
2. At converged loss levels (CE loss ~4.04, SFT loss ~3.0–4.5), all domain perplexities sit between 20 and 95:
   - Top-3 anchor baseline: $\text{PPL} \approx 44.5$
   - Hardest lagging domains (`fineweb_edu`, `openwebtext`, `storytelling`): $\text{PPL} \approx 80 - 94$
   - Actual delta: $\Delta \text{PPL} \approx 35 - 50$ (ratio $\approx 1.8\times - 2.1\times$).
3. Because $50 < 150.0$, the scheduler never engaged focused training in late CE or SFT, leaving hard datasets to plateau without dedicated compute.

---

## Implementation Design
1. **Configurable Sensitivity Globals**:
   - `g_focus_ppl_delta: float = 25.0;`
   - `g_focus_ppl_ratio: float = 1.35;`
   - `g_focus_exit_delta: float = 15.0;`
   - `g_focus_exit_ratio: float = 1.20;`
   - `g_focus_max_session_chunks: float = 24.0;`
2. **Scale-Invariant Engagement Trigger**:
   - Flag any domain where `(ppl_ratio > g_focus_ppl_ratio || ppl_delta > g_focus_ppl_delta) && ppl_delta > max_lag_ppl_delta`.
3. **Parity Catch-Up Disengagement**:
   - Disengage when `cur_ppl_delta <= g_focus_exit_delta || cur_ppl_ratio <= g_focus_exit_ratio`.
4. **Session Chunk Budget Guardrail**:
   - If a domain receives 24 focused chunks in a single session without reaching parity, yield focus to permit fleet rotation before re-evaluating.
5. **CLI Parameter Support**:
   - Add `-focus-delta`, `-focus-ratio`, `-focus-budget` CLI parameters in [`test/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car).

---

## Verification Gates
- **TS-17.1**: Scale-Invariant Lag Detection (triggers on delta > 25 or ratio > 1.35).
- **TS-17.2**: Anti-Forgetting Rehearsal Cadence (4 focused chunks followed by 1 fleet sweep).
- **TS-17.3**: Parity Disengagement (smoothly releases at delta <= 15 or ratio <= 1.20).
- **TS-17.4**: Session Budget Guardrail (yields at 24 chunks preventing infinite focus).
