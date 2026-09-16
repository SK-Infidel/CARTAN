# Sprint 351 Walkthrough: Calibration of Cloze Learning Rate Floor to 0.001

## 1. Problem Statement
During Stage 1 Cloze training across epochs 65 to 67, learning rate ceased dropping, remaining locked at `LR: 0.015`. While holdout validation loss successfully dropped from $4.70+$ down to $4.295$ (within $0.095$ of the target $4.20$), the model began oscillating around $4.30 - 4.41$ and could not descend into the global minimum.

## 2. Root Cause Analysis
In `test/geomind/train.cl`, line 1148 had:
```cl
var lr_floor = 0.015;
```
Every decay trigger in the training loop was bounded by:
```cl
if (lr < lr_floor) { lr = lr_floor; }
```
As a result, as soon as `lr` reached $0.015$, all further annealing was completely blocked. With gradient scaling amplified by $4.0\times$ and weight decay eliminated, step sizes at $\text{LR} = 0.015$ were too coarse to resolve the fine parameter manifold adjustments needed to break below $4.20$.

## 3. Technical Implementation
- Lowered `lr_floor` from $0.015$ to $0.001$ in `test/geomind/train.cl`.
- Lowered manifest resumption floor check from $0.005$ to $0.0005$ (`saved_lr >= 0.0005`) so finer learning rates persist across restarts.
- `lr` can now freely anneal: $0.015 \to 0.010 \to 0.005 \to 0.002 \to 0.001$.

## 4. Verification & Parity
- **Compiler**: Rebuilt via self-hosting `cartanc.exe`.
- **4-Way Binary Parity**: Synchronized all 4 production binaries with SHA-256 `02751160B69FA8F0E1814AF42DDD00CFF6EB38037F67596207468BF23C3A5793`:
  - `test/geomind/geomind.exe`
  - `./geomind.exe`
  - `bin/geomind.exe`
  - `build/geomind.exe`
