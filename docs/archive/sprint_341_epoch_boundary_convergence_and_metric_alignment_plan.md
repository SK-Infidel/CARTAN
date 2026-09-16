# Sprint 341 Implementation Plan: Epoch-Boundary Target Loss Convergence & Metric Alignment

## 1. Problem Statement & Root Cause
- **Symptom**: User configured `-training-loss 3.8`, but training terminated prematurely midway through Epoch 1 (at Dataset 3 of 6, ~34.6% of corpus) claiming `TL: 2.54818` while true average epoch training loss was `ATL: 6.39808`, validation loss was `VL: 6.43494`, and validation perplexity was `VPPL: 809.858`.
- **Root Cause**:
  1. `test/geomind/train.cl` evaluated early stopping every 100 lines on instantaneous interval loss `tl`. When an easy/repetitive sequence in Dataset 3 produced an interval loss dip of 2.54818 ($\le 3.8$), it triggered premature termination, crowned `final_loss = 2.54818`, and skipped the remaining 65.4% of the corpus.
  2. `target_hit` flag loop breakout was partially removed but lines 1397–1440 retained `if (target_hit == 1.0)`, referencing an undefined identifier.
  3. Final loss convergence must only be evaluated at full epoch boundaries against authentic whole-epoch empirical loss (`final_loss <= t_loss`).

## 2. Logical Dependency Graph
```
[User CLI: geomind train cloze -tl 3.8]
              │
              ▼
    [test/geomind/main.car]
              │ (passes target_loss=3.8, epochs=Inf)
              ▼
    [test/geomind/train.cl: geomind_train_streaming_steady_state]
              │
              ├─► Iterates all 6 datasets completely (0 -> num_datasets)
              │     └─► Line-by-line sentence forward/backward passes
              │     └─► Telemetry outputs: TL, ATL, VL, AVL, VPPL
              │
              ▼ [All Datasets Completed (Epoch Boundary)]
    [Compute final_loss = ep_loss_sum / ep_step_count]
              │
              ├─► If final_loss <= t_loss && ep >= 1.0:
              │     └─► Converged! Exit loop, report SUCCESS with true final_loss
              │
              └─► Else:
                    └─► Decay lr = max(lr * 0.95, 0.0005), ep = ep + 1.0
                    └─► Reset dataset index & offset to 0.0, begin next epoch
```

## 3. Tasks
1. Edit `test/geomind/train.cl`:
   - Replace lines 1397–1440 with direct epoch completion logic evaluating `final_loss <= t_loss && ep >= 1.0`.
   - Remove dead `target_hit == 1.0` conditional wrapper.
2. Compile and link GeoMind with self-hosting compiler:
   - `.\cartanc.exe build test/geomind/main.car -o bin/geomind.exe`
3. Synchronize all 4 production binary locations:
   - `bin/geomind.exe` -> `./geomind.exe`, `build/geomind.exe`, `test/geomind/geomind.exe`
   - Verify matching SHA-256 hashes across all 4.
4. Empirically verify complete epoch traversal and target loss evaluation.
5. Update `CHANGELOG.md` and `ISSUES.md` [ISSUE-090].
6. Archive walkthrough.
