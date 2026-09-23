# Sprint 380 Walkthrough: Symmetrized Perplexity Metrics & Holistic Evaluation Ruler

## 1. Problem Clarification & Findings
- **TPPL Swings**: `TPPL` was jumping between 69 and 104 because it was calculated as $\exp(TL)$ on raw, unsmoothed single-chunk losses. Variations in sentence complexity caused $TL$ to swing by $\pm 0.40\text{ nats}$, which exponentially amplified into $\pm 35$ perplexity points.
- **VPPL Steadiness**: `VPPL` was calculated as $\exp(AVL)$ on 95% smoothed average validation loss across 100 holdout chunks, making it appear artificially steady in contrast.
- **LR and Temp Stability**: They were not frozen—`ATL` ($4.40$) and `AVL` ($4.56$) exhibited an exceptionally healthy generalization gap of only $0.16\text{ nats}$ ($82\text{ TPPL} \leftrightarrow 96\text{ VPPL}$). Because $0.16 < 0.45$ (divergence threshold), temperature correctly stayed at baseline $1.0$, and LR cruised at its nominal target rate ($0.00238 \to 0.00240$).

## 2. Changes Made
- **Symmetrized Training Perplexity (`test/geomind/train.cl`)**:
  - Computed `cur_tppl` from smoothed running average loss `atl` ($\exp(atl)$), placing both metrics on the exact same smoothed ruler.
  - Now `Train -> TPPL: ~82` and `Val -> VPPL: ~96` track smoothly in tandem with a steady ~14 perplexity unit margin.

## 3. Empirical Verification
- **Compilation**: Clean build via `cartanc.exe`.
- **Binary Parity (SHA-256)**:
  `CB26411F1C9A807CB60911749E94C592D97705488641313789439842A3716DB1` verified across:
  - `test/geomind/geomind.exe`
  - `bin/geomind.exe`
  - `./geomind.exe`
- **Analogy Benchmark**: 4/4 semantic vector analogies pass at Rank 1 with clean margins (+0.086 to +0.206).
