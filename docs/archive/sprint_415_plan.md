# Sprint 415 Plan: Top-3 Anchor Perplexity (IVPPL) Dynamic Focus Scheduler

## Objective
Upgrade the Dynamic Adaptive Domain Focus scheduler in [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl) from linear cross-entropy loss gaps ($\Delta VL$) to Top-3 Anchor Validation Perplexity ($\Delta \text{IVPPL}$). This prevents false focus triggers on naturally diverse web corpora (`fineweb_edu`, `openwebtext`) while aggressively prioritizing severe outliers (`storytelling_corpus_clean.txt`) until parity is reached.

---

## Metric Specification

1. **Top-3 Mastered Anchor Baseline ($P_{\text{anchor}}$)**:
   - Identify the 3 lowest validation losses ($VL_{\min 1}, VL_{\min 2}, VL_{\min 3}$) among active initialized domains.
   - Convert to perplexity: $P_k = \exp(VL_k)$.
   - Compute anchor mean:
     $$P_{\text{anchor}} = \frac{1}{K}\sum_{k=1}^K \exp(VL_{\min k}) \quad (K = \min(3, N_{\text{valid}}))$$

2. **Per-Domain PPL Delta**:
   $$\Delta \text{IVPPL}_d = \exp(VL_d) - P_{\text{anchor}}$$

3. **Engagement Condition**:
   - $\Delta \text{IVPPL}_d > 150.0$
   - Ignored on natural web corpora ($\Delta \text{IVPPL} \approx 40 - 45$).
   - Triggers immediately on lagging outliers like storytelling ($\Delta \text{IVPPL} \approx 1630$).

4. **Disengagement Condition**:
   - $\Delta \text{IVPPL}_{\text{focus}} \le 50.0$
   - Releases focus once the domain's perplexity aligns with the fleet baseline ($P \le P_{\text{anchor}} + 50.0$).

5. **Anti-Forgetting Guard**:
   - Retain 4-chunk burst limit with 1-pass fleet rehearsal sweep.
