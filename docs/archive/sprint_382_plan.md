# Sprint 382 Implementation Plan: Calibrate Decisive Overfitting Braking, Active Trend Detection & 1.25x Temperature Gain

## 1. Context & Problem Statement
During the latest training run, the generalization gap widened from $val\_gap = 0.244\text{ nats}$ ($\Delta PPL = 22.0$) to $0.307\text{ nats}$ ($\Delta PPL = 28.0$), with $ATL$ dropping to $4.354$ while $AVL$ rose to $4.662$.
Root cause analysis revealed:
1. Braking at $val\_gap > 0.25$ was hardcoded to $0.999\times$ (only 0.1% per interval), which left nominal LR high ($0.00221$).
2. The trend detection condition was structured as an `else if` branch and required $(AVL - prev\_AVL) > 0.04$, which is $40\times$ larger than normal per-interval drift ($0.001 - 0.003$), making it dead code.
3. Temperature gain multiplier was only $0.50\times$, generating only $T \approx 1.074$ at gap $0.307$ (only 6.9% gradient attenuation).

## 2. Sprint Goal
Implement decisive proportional overfitting braking ($0.988\times$ at $>0.25$, $0.980\times$ at $>0.35$), unchain trend detection into an independent check at threshold $> 0.001$, and increase temperature gain to $1.25\times$ to enforce active gap closure before restoring post-cloze weights.

## 3. Targeted Modifications
- **`test/geomind/train.cl`**:
  1. Lines 1938-1956: Implement calibrated gap tiers ($0.97\times$ at $>0.60$, $0.98\times$ at $>0.35$, $0.988\times$ at $>0.25$, $0.995\times$ at $>0.15$) and unchain independent trend check at $> 0.001$ ($0.985\times$).
  2. Lines 1994-1997: Increase temperature gain multiplier from $0.50$ to $1.25$.

## 4. Verification Protocol
1. Compile using `cartanc.exe build test/geomind/main.car -o test/geomind/geomind.exe`.
2. Synchronize binary across `bin/geomind.exe` and `./geomind.exe`.
3. Verify 4/4 semantic vector analogies pass at Rank 1.
4. Record artifacts and update `CHANGELOG.md` and `ISSUES.md`.
