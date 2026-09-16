# Sprint 337: Target Loss-Driven Continuous Training & Dynamic Epoch Ceiling Elimination

## Objective
Remove the rigid 3-epoch default termination ceiling across GeoMind streaming training pipelines (`--train-cloze`, `--train-ce`, `--train-sft`, `--train-pre`). Enable continuous training across as many epochs as necessary until `-training-loss` (or `-target-loss`, `-tl`) is reached, with instant mid-epoch early stopping upon hitting the target.

## Architecture & Logic Flow
```
┌────────────────────────────────────────────────────────┐
│  test/geomind/main.car                                 │
│  - Support -training-loss, -target-loss, -tl, -loss    │
│  - has_cli_epochs() & has_cli_target_loss() detection  │
│  - Default epochs = Unlimited (1,000,000) when -epochs │
│    is omitted, training until target loss is reached   │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│  test/geomind/train.cl                                 │
│  - Banner reports "Epochs: Unlimited (Target Loss Hit)"│
│  - Mid-epoch early stopping check every 50 chunks:     │
│    if tl <= t_loss || smoothed_loss <= t_loss:         │
│      save checkpoint, sync GPU->host, status = SUCCESS │
│  - Continuous multi-epoch traversal with LR annealing  │
│    (0.90x decay to 0.0001 floor per epoch)             │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│  Synchronized Deployment (4 Targets)                   │
│  - ./geomind.exe, bin/, build/, test/geomind/          │
│  - Verified clean compilation and CLI arg handling     │
└────────────────────────────────────────────────────────┘
```

## Work Items
1. [ ] Update `test/geomind/main.car` CLI parsing to recognize `-training-loss` and `-loss`.
2. [ ] Default `epochs` to unlimited (`1000000.0`) when `-epochs` is not explicitly passed.
3. [ ] Update `test/geomind/train.cl` with dynamic banner display and mid-epoch target loss stopping.
4. [ ] Recompile `bin/geomind.exe` with `cartanc.exe` and synchronize all 4 binaries.
5. [ ] Empirically test `-training-loss` stopping behavior.
6. [ ] Update `CHANGELOG.md`, `ISSUES.md`, and generate archive walkthrough.
