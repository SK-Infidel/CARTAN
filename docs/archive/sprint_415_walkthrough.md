# Sprint 415 Walkthrough: Top-3 Anchor Perplexity (IVPPL) Dynamic Focus Scheduler

**Sprint**: Sprint 415  
**Release**: `[8.373.0]`  
**Status**: 100% Completed & Verified Cleanly  

---

## 1. Overview & Architecture

Sprint 415 upgraded the Dynamic Adaptive Domain Focus scheduler in [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl) from linear cross-entropy loss gaps ($\Delta VL$) to **Top-3 Anchor Validation Perplexity ($\Delta \text{IVPPL}$)**:

1. **Top-3 Mastered Anchor Baseline ($P_{\text{anchor}}$)**:
   - Evaluates active validation losses and dynamically extracts the 3 lowest domains (typically cloze and structural drills).
   - Computes anchor baseline perplexity:
     $$P_{\text{anchor}} = \frac{1}{K}\sum_{k=1}^K \exp(VL_{\min k}) \quad (K = \min(3, N_{\text{valid}}))$$

2. **Per-Domain PPL Delta**:
   $$\Delta \text{IVPPL}_d = \exp(VL_d) - P_{\text{anchor}}$$

3. **Calibrated Thresholds**:
   - **Engagement Trigger ($\Delta \text{IVPPL} > 150.0$)**:
     - Naturally diverse web corpora (`fineweb_edu`, `openwebtext`) with $\text{IVPPL} \approx 85 - 100$ sit at $\Delta \text{IVPPL} \approx 40 - 50$, safely below the trigger.
     - Outlier datasets like `storytelling_corpus_clean.txt` with $\text{IVPPL} \approx 1678$ ($\Delta \text{IVPPL} \approx 1630$) trigger focused catch-up bursts immediately.
   - **Parity Disengagement ($\Delta \text{IVPPL} \le 50.0$)**:
     - Keeps focused training engaged until the lagging domain drops to within $50.0$ PPL of the anchor baseline ($\text{IVPPL} \le 98$, $VL \le 4.58$), putting it directly in line with the web corpora before smoothly releasing back to round-robin streaming.

4. **Anti-Forgetting Rehearsal Cadence**:
   - Preserves the 4-chunk focused burst limit with 1 interleaved round-robin sweep across the other $N-1$ domains to eliminate catastrophic forgetting.

---

## 2. Empirical Verification

- **Compilation**: Compiled [`test/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car) via `cartanc.exe` with Zig `-O3 LTO Vectorized Pass Pipeline`.
- **System Integrity**: Verified `geomind.exe --verify` with all physics, Hopfield, and online SFT solvers passing.
- **Regressions**: Verified 100% pass across all 7 NSES test suites (`test_sprint1` through `test_sprint7`) with Exit Code 0.
