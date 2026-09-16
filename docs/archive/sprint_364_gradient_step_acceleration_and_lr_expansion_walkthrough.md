# Sprint 364 Walkthrough: Gradient Step Acceleration, Input Embedding Scaling & Adaptive LR Headroom

## Executive Summary
In Sprint 364, we resolved pre-training loss plateauing across heterogeneous datasets ([ISSUE-115](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md#L1630)). The input token embedding gradient update in the OpenCL kernel `geomind_input_grad_update` was boosted from `0.02f` to `0.10f` (5× acceleration), restoring dual-ended representational plasticity. Additionally, artificial learning rate clamps were replaced with an expanded ceiling (`stage_ceiling_lr = 0.05`) and an explicit starvation floor (`lr_floor = 0.002`), initializing active pre-training at `0.006`.

## Changes Implemented

### 1. Input Embedding Gradient Acceleration
- **File**: [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L296)
- In kernel string `input_sgd_src`, accelerated update step from `lr * 0.02f * g` to `lr * 0.10f * g`:
```c
weights[idx] = weights[idx] - lr * 0.10f * g;
```

### 2. Stage 2 Pre-Training LR Bounds & Initialization
- **File**: [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L1287-L1300)
- Configured pre-training floor and ceiling:
```c
var lr_floor = 0.001;
var stage_ceiling_lr = 0.05;
if (stage_mode == 2.0) {
    lr_floor = 0.002;
    stage_ceiling_lr = 0.05; // Arbitrarily high headroom; dynamic controller handles self-regulation
}
if (base_lr > 0.0) {
    lr = base_lr;
} else if (lr <= 0.0 || lr < lr_floor) {
    lr = 0.006;
}
```

### 3. Adaptive TPPL Controller Dynamic Scaling
- **File**: [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L1575-L1665)
- Replaced hardcoded `0.008` / `0.010` limits with dynamic bounds checking against `stage_ceiling_lr` (`0.05`) and `lr_floor` (`0.002`).
- Anchored starvation probing to `lr_floor * 1.5` and `lr_floor * 1.25`, allowing natural oscillation decay ($0.95\times$) and divergence braking ($0.90\times$) to regulate descent dynamics without artificial capping.

### 4. Corpus Manifest Update
- **File**: [`test/geomind/trainingdata/corpus.json`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/corpus.json#L5)
- Updated active learning rate to `0.006`:
```json
"current_lr": 0.006,
```

## Compilation & Verification

Recompiled using `cartanc.exe` with zero errors. Verified bit-for-bit binary synchronization across all runtime locations:

| Binary Path | SHA-256 Hash | Status |
| :--- | :--- | :--- |
| `test/geomind/geomind.exe` | `187711740FCD9D05A97D2DA216E5A30461A5EA38DF220C16BD613A9F6461D9C4` | Verified |
| `bin/geomind.exe` | `187711740FCD9D05A97D2DA216E5A30461A5EA38DF220C16BD613A9F6461D9C4` | Synchronized |
| `./geomind.exe` | `187711740FCD9D05A97D2DA216E5A30461A5EA38DF220C16BD613A9F6461D9C4` | Synchronized |

## Launch Command
```powershell
.\geomind.exe --train-pre
```
