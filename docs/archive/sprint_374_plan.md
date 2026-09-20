# Sprint 374 Implementation Plan: Target-Loss Progress Annealing & Domain Transition Stabilization

## Problem Statement & Root Cause
In Stage 2 causal pretraining (`geomind --train-pre -tl 3.5`), the optimizer experienced recurring learning rate starvation when transitioning between diverse corpora (e.g. from formulaic syntactic cloze into narrative fiction prose):
1. **Perplexity Shock on Domain Boundaries**: In cloze datasets, predictability is high ($TL \approx 3.2 - 3.6$, $\text{TPPL} \approx 25 - 45$). When transitioning into natural prose fiction (`storytelling_corpus_clean.txt`), the vocabulary and dialogue diversity naturally raises entropy to the standard bigram baseline of English ($TL \approx 4.25 - 4.45$, $\text{TPPL} \approx 70 - 100$).
2. **Reactive Delta-TPPL Panic**: The controller had a reactive condition `delta_tppl > 4.0` with a 4-interval trigger that misinterpreted this cross-dataset entropy shift as "overshooting", repeatedly decaying `lr * 0.95` until the step size was starved down to `0.00105`.
3. **Late-Stage Overshoot Risk**: If fixed at a static rate like `0.002`, the learning rate would be too fast as the model approaches the target loss valley ($TL \to 3.50$), causing oscillation and loss instability near the optimum.

## Proposed Changes
1. **Implement Target-Loss Progress Annealing (`test/geomind/train.cl`)**:
   - Tie the active learning rate smoothly to global progress toward target loss ($t\_loss = 3.50$):
     $$\eta(ATL) = \eta_{\text{floor}} + (\eta_{\text{max}} - \eta_{\text{floor}}) \times \min\left(1.0, \max\left(0.0, \frac{ATL - t\_loss}{4.40 - t\_loss}\right)\right)$$
   - When $ATL \approx 4.30$ (current): $\eta \approx 0.00220$, maintaining high velocity through bigram plateaus.
   - When $ATL \approx 3.75$: $\eta \approx 0.00110$, cooling down to protect learned semantic geometry.
   - When $ATL \to 3.50$: $\eta \approx 0.00060$, fine-tuning delicately without overshooting.
2. **Eliminate Reactive Delta-TPPL Decays (`test/geomind/train.cl`)**:
   - Remove single-interval `delta_tppl` oscillation and surge penalties. Text difficulty fluctuations no longer penalize optimizer step size.
3. **Preserve True Validation Overshoot Braking**:
   - Maintain safety braking exclusively on genuine validation holdout divergence ($AVL > ATL \times 1.35$ with absolute gap $> 1.20$, and rising validation trend $d(AVL)/dt > 0.05$).
4. **Compile & Verification**:
   - Compile `test/geomind/geomind.exe` and `bin/geomind.exe` via `cartanc.exe`.
   - Verify all 4 semantic analogies pass at Rank 1.

## Verification Criteria
- [x] Code passes static type checking and LLVM IR codegen via `cartanc.exe`.
- [x] 4/4 semantic vector analogies remain at Rank 1 (`geomind --eval-analogy`).
- [x] Target-Loss Progress Annealing smoothly steers learning rate from $0.0024 \to 0.0006$ as $ATL \to 3.50$.
- [x] Cross-dataset domain transitions no longer trigger false-alarm decays.
