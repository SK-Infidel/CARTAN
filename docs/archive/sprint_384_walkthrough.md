# Sprint 384 Walkthrough: Exact-Match Chunk Convergence Gate & Anti-Dethrottling Regularization

## 1. Problem & Root Cause Analysis
During live training testing of the interleaved convergence mechanism, the generalization gap contracted from $25.8 \to 19.59\text{ PPL}$ ($val\_gap \approx 0.204\text{ nats}$), plateaued just above 18, and then turned around and diverged upward again.
The root causes were:
1. **Convergence Loop Exit at 18 PPL**: The gate released the chunk as soon as $\Delta PPL \le 18.0$, returning immediately to standard stream training while a substantial gap remained.
2. **Premature Progress Annealing Surge**: The progress annealing threshold was gated at $val\_gap > 0.20\text{ nats}$. The moment $val\_gap$ dropped to $0.20$, `val_divergent` became $0.0$, blending $10\%$ of ceiling LR ($0.0024$) per interval and surging nominal LR from $0.00127 \to 0.00180$.
3. **Premature Temperature Cooling**: Temperature scaling was gated above $val\_gap > 0.15\text{ nats}$ with weak gain, causing $T$ to collapse from $1.15 \to 1.01$ when $val\_gap$ touched $0.20$.
4. **Resumed Memorization**: High LR ($0.0018$) combined with cold temperature ($1.01$) accelerated single-chunk memorization ($TL \to 4.07$), re-opening validation divergence ($VPPL \to 108.3$).

---

## 2. Implemented Changes

### A. Exact-Match Chunk Convergence Gate (`test/geomind/train.cl`, lines 1806-1846)
- Lowered activation threshold to $\Delta PPL = (VPPL - cur\_tppl) > 2.5\text{ PPL}$ ($val\_gap \approx 0.03\text{ nats}$).
- Increased maximum convergence passes to 8.
- Set retraining rate to disciplined $\eta_{\text{conv}} = 0.70 \times \eta$.
- Applied adaptive temperature softening during convergence passes:
  $$T_{\text{conv}} = \text{clamp}\left(1.0 + \frac{VPPL - cur\_tppl}{cur\_tppl} \times 1.50, [1.08, 1.35]\right)$$
- Added per-chunk plateau detection: if $(prev\_pass\_gap - new\_gap) < 0.05\text{ PPL}$ after 3 passes, the loop exits gracefully to avoid local minimum lock.
- Clamped post-convergence learning rate to $\le 0.0010$ upon resuming stream advancement.

### B. Anti-Dethrottling Progress Annealing Gating (`test/geomind/train.cl`, lines 1967-1978)
- Tightened $val\_divergent$ threshold from $0.20 \to 0.05\text{ nats}$ ($\Delta PPL > 3.0$).
- Strictly blocks upward LR progress annealing towards $0.0024$ until validation parity is attained.

### C. Continuous Overfitting Braking & Dynamic Temperature Control (`test/geomind/train.cl`, lines 1994-2063)
- Calibrated braking tiers: $0.970\times$ ($> 0.50$), $0.980\times$ ($> 0.30$), $0.988\times$ ($> 0.15$), and $0.995\times$ down to $0.05\text{ nats}$.
- Re-scaled temperature controller to activate continuously at $val\_gap > 0.03\text{ nats}$ with high gain ($1.50\times$), keeping $T \approx 1.25$ until exact match is attained.

---

## 3. Empirical Verification Results

1. **Compilation**:
   `cartanc.exe build test/geomind/main.car -o test/geomind/geomind.exe` succeeded with 0 errors.
2. **Binary Synchronization**:
   Bit-for-bit SHA-256 match `08785997FBD20F0AD0314B71C81D48020EBD2739D4F6525BC59F967C194BCB48` verified across:
   - `test/geomind/geomind.exe`
   - `bin/geomind.exe`
   - `./geomind.exe`
3. **Semantic Vector Analogies (`.\geomind.exe --eval-analogy`)**:
   - `King - man + woman = queen` : Rank 1 (Margin: +0.0990) -> PASS
   - `he - him + her = she` : Rank 1 (Margin: +0.1134) -> PASS
   - `father - man + woman = mother` : Rank 1 (Margin: +0.0857) -> PASS
   - `boy - man + woman = girl` : Rank 1 (Margin: +0.2033) -> PASS
4. **Weights Integrity**:
   Baseline weights were strictly preserved; the overfit checkpoint (`geomind_steady_state_weights.bin`) was kept intact for in-place convergence testing.
