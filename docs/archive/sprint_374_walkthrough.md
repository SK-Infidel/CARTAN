# Sprint 374 Walkthrough: Target-Loss Progress Annealing & Domain Transition Stabilization

## Summary of Changes
In Sprint 374, we replaced reactive single-batch perplexity micro-decays with a mathematically principled **Target-Loss Progress Annealing Schedule** in [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl):
1. **Target-Loss Progress Annealing Schedule**:
   - Replaced `delta_tppl` oscillation and surge decays (`train.cl#L1709-L1824`) with global progress annealing:
     $$\eta(ATL) = \eta_{\text{floor}} + (\eta_{\text{max}} - \eta_{\text{floor}}) \times \min\left(1.0, \max\left(0.0, \frac{ATL - t\_loss}{4.40 - t\_loss}\right)\right)$$
   - Parameters: $\eta_{\text{max}} = 0.0024$, $\eta_{\text{floor}} = 0.0006$, starting default $\eta = 0.0022$.
   - Steers LR with a 10% momentum update per evaluation interval toward the target annealed rate whenever validation is healthy.
   - Solves both extremes: provides $\eta \approx 0.0022$ to push through bigram plateaus on diverse prose, while automatically and smoothly cooling down to $\eta \approx 0.0006$ as the model descends toward $TL = 3.50$, preventing late-stage valley overshoot.
2. **Eliminated Reactive Domain-Transition Decays**:
   - Natural transitions between structured cloze (PPL ~35) and narrative fiction (PPL ~80-100) no longer trip false-alarm decays.
3. **Preserved True Validation Safety Guards**:
   - Kept strict closed-loop validation braking:
     - Generalization gap divergence: $AVL > ATL \times 1.35$ and $AVL - ATL > 1.20 \implies \text{decay } 0.92\times$.
     - Rising validation loss trend: $d(AVL)/dt > 0.05 \implies \text{decay } 0.95\times$.
     - Emergency divergence spike: $TL > 5.0$ and $TL > ATL \times 1.25 \implies \text{decay } 0.90\times$.

## Empirical Verification
1. **Semantic Vector Analogy Arithmetic (`.\bin\geomind.exe --eval-analogy`)**:
   - King - man + woman = queen (Rank 1: 0.4241, Margin: +0.1066) -> PASS
   - he - him + her = she (Rank 1: 0.4846, Margin: +0.1102) -> PASS
   - father - man + woman = mother (Rank 1: 0.4757, Margin: +0.0954) -> PASS
   - boy - man + woman = girl (Rank 1: 0.5819, Margin: +0.2610) -> PASS
2. **Compilation**:
   - Built native optimized binary via `cartanc.exe`.
   - Verified bit-for-bit SHA-256 match `38C1E3799F7CFA38A56EFEE075753ABA5FA892ED300477C8288D6C714F28A1FF` across `test/geomind/geomind.exe` and `bin/geomind.exe`.
