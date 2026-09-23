# Sprint 379 Walkthrough: Eliminating Weight Decay Erosion & Calibrating Adaptive LR

## 1. Problem Identification
- **Symptoms**:
  - Validation perplexity skyrocketed to $VPPL \approx 693.881$ ($VL = 6.70$) with validation entropy hitting $VENT = 11.3219\text{b} = \log_2(2560)$ (theoretical maximum uniform noise).
  - Semantic analogies collapsed (cosine similarities flipped from $+0.43$ to $-0.99$).
  - Learning rate crashed to $0.00075$ ($LR$ was "ridiculously low").
- **Root Cause**:
  - Sprint 377 introduced `decay_factor = 0.99995` in both OpenCL SGD kernel and CPU fallback.
  - Because this factor was applied to all 6,553,600 weights on *every single token* (256 times per chunk), weights decayed by $0.9872$ per chunk, shrinking by 99% within 100,000 steps.
  - With weights near zero, logits collapsed to zero ($z \to 0$), producing uniform distribution over the 2560 vocabulary ($VENT = 11.3219\text{b}$, $VCERT = 0.044\%$).
  - The runaway validation gap ($1.18\text{ nats}$) triggered rapid $0.95\times$ interval braking, pinning LR at the floor ($0.00075$) and persisting it into `corpus.json`.

## 2. Changes Made
- **Restored Canonical SGD (`decay_factor = 1.0`)**:
  - Updated line 722 and line 785 in [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L720-L790) back to `let decay_factor = 1.0;`.
- **Restored Baseline Checkpoint Weights**:
  - Restored [`test/geomind/trainingdata/checkpoints/geomind_steady_state_weights.bin`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/checkpoints/geomind_steady_state_weights.bin) from `geomind_steady_state_weights.bin.bak`.
- **Calibrated Proportionate LR Braking**:
  - Updated braking multipliers in [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L1935-L1955) to $0.98\times$ ($> 1.30$), $0.99\times$ ($> 1.00$), and $0.995\times$ ($> 0.70$).
- **Reset Corpus Manifest**:
  - Reset [`test/geomind/trainingdata/corpus.json`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/corpus.json#L1-L6) to dataset 0, offset 0.0, epoch 1.0, and LR 0.0022.

## 3. Empirical Verification
- **Binary Compilation**: Compiled cleanly with `cartanc.exe`.
- **Binary Parity (SHA-256)**:
  `758B0F6FE91B8B61064369D68C8DC14014F4D94B2B7ECD120DB5AA4EF328BAFE` verified across:
  - [`test/geomind/geomind.exe`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/geomind.exe)
  - [`bin/geomind.exe`](file:///C:/Users/rich-/source/repos/CARTAN/bin/geomind.exe)
  - [`./geomind.exe`](file:///C:/Users/rich-/source/repos/CARTAN/geomind.exe)
- **Analogy Benchmark**: 4/4 semantic vector analogies pass at Rank 1:
  - King - man + woman = queen: PASS (Margin +0.099)
  - he - him + her = she: PASS (Margin +0.114)
  - father - man + woman = mother: PASS (Margin +0.087)
  - boy - man + woman = girl: PASS (Margin +0.206)
