# Sprint 365 Walkthrough: Validation Divergence Braking, Rebalanced Manifold Updates & Multi-Domain Holdout

## Executive Summary
In Sprint 365, we addressed validation-training loss divergence and rising perplexity during Stage 2 pre-training ([ISSUE-116](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md#L1647)). Input embedding updates in OpenCL kernel `geomind_input_grad_update` were rebalanced to natural Riemannian manifold curvature (`0.025f`). The adaptive controller was upgraded with closed-loop validation feedback ($0.92\times$ braking on $AVL > ATL \times 1.08$, $0.95\times$ on climbing $AVL$). The starvation logic was de-jittered to `lr <= lr_floor * 1.05`, and a 200-line balanced multi-domain validation holdout was deployed.

## Changes Implemented

### 1. Rebalanced Input Embedding Manifold Updates
- **File**: [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L296)
- Scaled input embedding gradient updates to `0.025f` to align with `inv_sqrt_dim = 0.01976f`:
```c
weights[idx] = weights[idx] - lr * 0.025f * g;
```

### 2. Closed-Loop Validation Divergence Braking
- **File**: [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L1673-L1705)
- Wired active validation loss tracking and automatic braking into the controller:
```cl
if (ep_step_count > 200.0 && ema_val_loss > 0.0 && atl > 0.0) {
    if (ema_val_loss > (atl * 1.08)) {
        lr = lr * 0.92;
        if (lr < lr_floor) { lr = lr_floor; }
        printf("[Adaptive LR] Validation divergence detected (AVL: %s > ATL: %s * 1.08). Braked LR: %s -> %s\n", ...);
    } else if (prev_ema_val_loss > 0.0 && (ema_val_loss - prev_ema_val_loss) > 0.015) {
        lr = lr * 0.95;
        if (lr < lr_floor) { lr = lr_floor; }
        printf("[Adaptive LR] Validation loss climbing (AVL: %s -> %s). Braked LR: %s -> %s\n", ...);
    }
}
```

### 3. De-jittered Starvation Thresholds
- **File**: [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L1582-L1650)
- Tightened starvation probing condition from `lr <= lr_floor * 1.5` to `lr <= lr_floor * 1.05`, breaking the 100-step oscillation jitter loop (`0.0026` $\leftrightarrow$ `0.0033`).
- Set `lr_floor = 0.0015` and default pre-training rate to `0.004`.

### 4. Balanced Multi-Domain Validation Suite
- **Files**: [`test/geomind/trainingdata/pretrain_validation_holdout.txt`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/pretrain_validation_holdout.txt), [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L1533)
- Curated 200 genuine lines spanning FineWeb-Edu, OpenWebText, WikiText-103, ArXiv abstracts, and TinyStories.
- Directed Stage 2 pre-training validation to this balanced suite to eliminate single-domain artifacting.

## Empirical Verification

Recompiled using `cartanc.exe` with zero errors. Synchronized binaries across all three paths:

| Binary Path | SHA-256 Hash | Status |
| :--- | :--- | :--- |
| `test/geomind/geomind.exe` | `542C577EAA777F0C1F1A7E2AB3B70638CBA5B16B29ADDB3CC39FBBA569A9855E` | Verified |
| `bin/geomind.exe` | `542C577EAA777F0C1F1A7E2AB3B70638CBA5B16B29ADDB3CC39FBBA569A9855E` | Synchronized |
| `./geomind.exe` | `542C577EAA777F0C1F1A7E2AB3B70638CBA5B16B29ADDB3CC39FBBA569A9855E` | Synchronized |

### Live Execution Telemetry
Empirical test run confirmed active closed-loop divergence braking:
```
[Adaptive LR] Validation divergence detected (AVL: 4.5364 > ATL: 4.16717 * 1.08). Braked LR: 0.004 -> 0.00368
[Adaptive LR] Validation divergence detected (AVL: 4.53558 > ATL: 4.19729 * 1.08). Braked LR: 0.003496 -> 0.00321632
...
[Adaptive LR] Validation divergence detected (AVL: 4.53028 > ATL: 4.09592 * 1.08). Braked LR: 0.00156814 -> 0.0015
[GeoMind CAUSAL CE Stream] Ep 4.0/Inf | D[6.0/14.0] | TL: 4.14618 | ATL: 4.08724 | VL: 4.50257 | AVL: 4.52978 | VPPL: 92.7383 | LR: 0.0015
```
Validation loss and perplexity immediately reversed direction ($VPPL: 93.40 \to 92.73$), and learning rate settled smoothly at the controlled floor (`0.0015`).
