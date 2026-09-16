# Sprint 338: Elimination of Default Epoch Ceiling & Universal Target-Loss Multi-Epoch Cloze Training

## Objective
Ensure GeoMind cloze training (`--train-cloze`, `cloze`, `--cloze`) has NO default 3-epoch limit, running continuously across as many epochs as necessary (Epoch 1, 2, 3, 4, 5, ...) until `-training-loss` (or `-target-loss`, `-tl`, `-loss`) is achieved. Add robust CLI parsing supporting `-` and `--` prefixes and bare mode names.

## Logical Architecture
```
┌────────────────────────────────────────────────────────┐
│  test/geomind/main.car                                 │
│  - cli_arg_matches(): supports exact, -, --, bare      │
│  - is_mode(): matches cloze, --train-cloze, etc.       │
│  - get_cli_target_loss(): parses -training-loss, etc.  │
│  - has_cli_epochs(): only true if user explicitly passes│
│  - Default epochs = 1,000,000.0 (Unlimited)             │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│  test/geomind/train.cl                                 │
│  - Mid-epoch early stopping: tl <= t_loss              │
│  - End-of-epoch convergence: smoothed or final <= t_loss│
│  - Multi-epoch progression (ep = ep + 1.0) past 3 ep   │
│  - LR decay per epoch (0.90x down to 0.0001)           │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│  Binary Compilation & 4-Way Sync                       │
│  - cartanc.exe build test/geomind/main.car             │
│  - Sync bin/, ./, build/, test/geomind/                │
│  - Verified with SHA-256 hash comparison               │
└────────────────────────────────────────────────────────┘
```

## Detailed Work Items
1. [x] Implement robust zero-allocation mode validators in `test/geomind/main.car` (`is_pre_mode`, `is_cloze_mode`, `is_ce_mode`, `is_sft_mode`).
2. [x] Implement direct loop scanning in `test/geomind/main.car` supporting `cloze`, `--cloze`, `-cloze`, `--train-cloze`, etc., and all target loss/epoch aliases.
3. [x] Update mode handlers (`--train-cloze`, `--train-ce`, `--train-sft`, `--train-pre`) in `test/geomind/main.car` with unlimited default epochs (`1000000.0`).
4. [x] Enhance end-of-epoch convergence check in `test/geomind/train.cl` (`smoothed_loss <= t_loss || final_loss <= t_loss`).
5. [x] Recompile `bin/geomind.exe` with `cartanc.exe` and synchronize across all 4 locations.
6. [x] Empirically test `-training-loss` in cloze mode (verified past epoch 3 up to epoch 6 and stopping upon reaching target loss).
7. [x] Update `CHANGELOG.md` and `ISSUES.md`.
